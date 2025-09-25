defmodule AgentService.Runs.Worker do
  use GenServer, restart: :temporary
  require Logger

  alias AgentService.Providers.LLM.ClaudeCLI

  def start_link({run_id, config}) do
    GenServer.start_link(__MODULE__, {run_id, config}, name: {:via, Registry, {AgentService.RunRegistry, run_id}})
  end

  def init({run_id, config}) do
    Logger.info("Starting run worker: #{run_id}")

    # Start processing in background
    Process.send_after(self(), :start_processing, 100)

    {:ok,
     %{
       run_id: run_id,
       config: config,
       status: "running",
       logs: [],
       total_cost: 0
     }}
  end

  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  def handle_info(:start_processing, state) do
    # Simulate agent processing
    log_entry = %{
      timestamp: DateTime.utc_now(),
      event: "processing",
      level: "info",
      message: "Starting agent processing for template: #{state.config.template_id}",
      tokens: 0,
      cost: 0
    }

    broadcast_log(state.run_id, log_entry)

    # Schedule next processing step
    Process.send_after(self(), :process_step, 2000)

    {:noreply, %{state | logs: [log_entry | state.logs]}}
  end

  def handle_info(:process_step, state) do
    # Example: Call Claude CLI
    case ClaudeCLI.chat("Analyze this configuration: #{inspect(state.config)}") do
      {:ok, result} ->
        tokens = Map.get(result, :tokens_out, 100)
        # Example cost calculation
        cost = tokens * 0.00001

        log_entry = %{
          timestamp: DateTime.utc_now(),
          event: "llm_response",
          level: "info",
          message: "Received LLM response",
          tokens: tokens,
          cost: cost
        }

        broadcast_log(state.run_id, log_entry)

        # Continue or complete
        if length(state.logs) < 5 do
          Process.send_after(self(), :process_step, 3000)
        else
          Process.send(self(), :complete, [])
        end

        {:noreply, %{state | logs: [log_entry | state.logs], total_cost: state.total_cost + cost}}

      {:error, reason} ->
        log_entry = %{
          timestamp: DateTime.utc_now(),
          event: "error",
          level: "error",
          message: "LLM error: #{inspect(reason)}",
          tokens: 0,
          cost: 0
        }

        broadcast_log(state.run_id, log_entry)
        {:noreply, %{state | logs: [log_entry | state.logs], status: "failed"}}
    end
  end

  def handle_info(:complete, state) do
    Logger.info("Run completed: #{state.run_id}")

    Phoenix.PubSub.broadcast(
      AgentService.PubSub,
      "runs:#{state.run_id}",
      {:run_completed, state.run_id}
    )

    {:stop, :normal, %{state | status: "completed"}}
  end

  defp broadcast_log(run_id, entry) do
    Phoenix.PubSub.broadcast(
      AgentService.PubSub,
      "runs:#{run_id}",
      {:log_entry, entry}
    )
  end
end
