defmodule AgentService.Runs.JidoWorker do
  @moduledoc """
  Worker that manages JIDO agent execution for runs
  """
  use GenServer, restart: :temporary

  alias AgentService.Agents.TemplateRunner

  require Logger

  def start_link({run_id, config}) do
    GenServer.start_link(__MODULE__, {run_id, config}, name: {:via, Registry, {AgentService.RunRegistry, run_id}})
  end

  def init({run_id, config}) do
    Logger.info("Starting JIDO worker for run: #{run_id}")

    # Start the JIDO agent for this run
    agent_id = "agent_#{run_id}"

    agent_config = %{
      id: agent_id,
      template_id: config.template_id,
      template_config: config.config,
      run_id: run_id,
      budget: config[:budget] || %{},
      context: build_agent_context(config)
    }

    # Start the template runner agent
    case start_template_runner(agent_id, agent_config) do
      {:ok, agent_pid} ->
        # Monitor the agent
        Process.monitor(agent_pid)

        state = %{
          run_id: run_id,
          agent_id: agent_id,
          agent_pid: agent_pid,
          config: config,
          status: :running,
          started_at: DateTime.utc_now()
        }

        # Subscribe to agent events
        Phoenix.PubSub.subscribe(AgentService.PubSub, "agent:#{agent_id}")

        # Broadcast initial status
        broadcast_status(state)

        {:ok, state}

      {:error, reason} ->
        Logger.error("Failed to start JIDO agent: #{inspect(reason)}")
        {:stop, reason}
    end
  end

  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  def handle_call(:stop, _from, state) do
    Logger.info("Stopping run: #{state.run_id}")

    # Stop the JIDO agent
    if state.agent_pid && Process.alive?(state.agent_pid) do
      GenServer.stop(state.agent_pid, :normal)
    end

    {:stop, :normal, :ok, %{state | status: :stopped}}
  end

  def handle_info({:DOWN, _ref, :process, pid, reason}, state) when pid == state.agent_pid do
    Logger.info("JIDO agent terminated for run #{state.run_id}: #{inspect(reason)}")

    new_status =
      case reason do
        :normal -> :completed
        _ -> :failed
      end

    new_state = %{state | status: new_status, completed_at: DateTime.utc_now()}

    broadcast_completion(new_state, reason)

    {:stop, :normal, new_state}
  end

  def handle_info({:agent_event, event}, state) do
    # Handle events from the JIDO agent
    handle_agent_event(event, state)
  end

  def handle_info(msg, state) do
    Logger.debug("Unhandled message in JidoWorker: #{inspect(msg)}")
    {:noreply, state}
  end

  # Private functions

  defp start_template_runner(agent_id, config) do
    # Start the JIDO agent with the template runner behavior
    AgentService.Agents.TemplateRunner.start_link(
      id: agent_id,
      initial_state: config
    )
  end

  defp build_agent_context(config) do
    %{
      template_id: config.template_id,
      secrets_ref: config[:secrets_ref],
      schedule: config[:schedule],
      environment: %{
        jido_home: Path.expand("~/.jido"),
        templates_dir: Path.expand("~/.jido/templates"),
        runs_dir: Path.expand("~/.jido/runs")
      }
    }
  end

  defp handle_agent_event({:log, log_entry}, state) do
    # Forward log entries to the run channel
    Phoenix.PubSub.broadcast(
      AgentService.PubSub,
      "runs:#{state.run_id}",
      {:log_entry, log_entry}
    )

    {:noreply, state}
  end

  defp handle_agent_event({:metrics, metrics}, state) do
    # Forward metrics to the run channel
    Phoenix.PubSub.broadcast(
      AgentService.PubSub,
      "runs:#{state.run_id}",
      {:metrics, metrics}
    )

    {:noreply, state}
  end

  defp handle_agent_event({:status_change, new_status}, state) do
    new_state = %{state | status: new_status}
    broadcast_status(new_state)
    {:noreply, new_state}
  end

  defp handle_agent_event(event, state) do
    Logger.debug("Unhandled agent event: #{inspect(event)}")
    {:noreply, state}
  end

  defp broadcast_status(state) do
    Phoenix.PubSub.broadcast(
      AgentService.PubSub,
      "runs:#{state.run_id}",
      {:status_update,
       %{
         run_id: state.run_id,
         status: state.status,
         started_at: state.started_at
       }}
    )
  end

  defp broadcast_completion(state, reason) do
    Phoenix.PubSub.broadcast(
      AgentService.PubSub,
      "runs:#{state.run_id}",
      {:run_completed,
       %{
         run_id: state.run_id,
         status: state.status,
         reason: reason,
         completed_at: state.completed_at
       }}
    )
  end
end
