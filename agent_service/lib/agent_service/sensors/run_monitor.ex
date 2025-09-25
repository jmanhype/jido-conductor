defmodule AgentService.Sensors.RunMonitor do
  @moduledoc """
  JIDO Sensor for monitoring run metrics and health
  """
  use Jido.Sensor,
    name: "run_monitor",
    description: "Monitors agent run metrics, performance, and resource usage",
    schema: [
      emit_interval: [type: :integer, default: 5000],
      run_id: [type: :string, required: true],
      metrics: [
        type: :map,
        default: %{
          total_actions: 0,
          successful_actions: 0,
          failed_actions: 0,
          total_tokens: 0,
          total_cost: 0.0,
          avg_action_duration: 0
        }
      ]
    ]

  require Logger

  @impl true
  def init(config) do
    # Schedule periodic metric emission
    schedule_emit(config.emit_interval)

    # Subscribe to run events
    Phoenix.PubSub.subscribe(AgentService.PubSub, "runs:#{config.run_id}")

    {:ok, config}
  end

  @impl true
  def handle_info(:emit_metrics, state) do
    # Emit current metrics
    emit_event(:metrics_update, state.metrics, %{
      run_id: state.run_id,
      timestamp: DateTime.utc_now()
    })

    # Schedule next emission
    schedule_emit(state.emit_interval)

    {:noreply, state}
  end

  @impl true
  def handle_info({:log_entry, entry}, state) do
    # Update metrics based on log entry
    new_metrics = update_metrics(state.metrics, entry)

    {:noreply, %{state | metrics: new_metrics}}
  end

  @impl true
  def handle_info({:metrics, metrics}, state) do
    # Update cumulative metrics
    new_metrics = %{
      state.metrics
      | total_tokens: state.metrics.total_tokens + Map.get(metrics, :tokens_in, 0) + Map.get(metrics, :tokens_out, 0),
        total_cost: state.metrics.total_cost + Map.get(metrics, :cost, 0)
    }

    # Emit if significant change
    if significant_change?(state.metrics, new_metrics) do
      emit_event(:metrics_threshold, new_metrics, %{
        run_id: state.run_id,
        alert: determine_alert(new_metrics)
      })
    end

    {:noreply, %{state | metrics: new_metrics}}
  end

  @impl true
  def handle_info({:action_completed, result}, state) do
    # Track action completion
    new_metrics =
      case result do
        {:ok, _} ->
          %{
            state.metrics
            | total_actions: state.metrics.total_actions + 1,
              successful_actions: state.metrics.successful_actions + 1
          }

        {:error, _} ->
          %{
            state.metrics
            | total_actions: state.metrics.total_actions + 1,
              failed_actions: state.metrics.failed_actions + 1
          }
      end

    {:noreply, %{state | metrics: new_metrics}}
  end

  @impl true
  def handle_info(msg, state) do
    Logger.debug("RunMonitor received: #{inspect(msg)}")
    {:noreply, state}
  end

  # Private functions

  defp schedule_emit(interval) do
    Process.send_after(self(), :emit_metrics, interval)
  end

  defp update_metrics(metrics, log_entry) do
    # Update metrics based on log entry type
    case log_entry[:event] do
      "action_start" ->
        %{metrics | total_actions: metrics.total_actions + 1}

      "action_complete" ->
        %{metrics | successful_actions: metrics.successful_actions + 1}

      "action_failed" ->
        %{metrics | failed_actions: metrics.failed_actions + 1}

      _ ->
        metrics
    end
  end

  defp significant_change?(old_metrics, new_metrics) do
    # Determine if metrics changed significantly
    cost_change = abs(new_metrics.total_cost - old_metrics.total_cost)
    token_change = abs(new_metrics.total_tokens - old_metrics.total_tokens)

    cost_change > 0.01 || token_change > 1000
  end

  defp determine_alert(metrics) do
    cond do
      metrics.failed_actions > 5 ->
        :high_failure_rate

      metrics.total_cost > 10.0 ->
        :high_cost

      metrics.total_tokens > 100_000 ->
        :high_token_usage

      true ->
        :none
    end
  end

  defp emit_event(event_type, data, metadata) do
    event = %{
      type: event_type,
      source: "run_monitor",
      data: data,
      metadata: metadata,
      timestamp: DateTime.utc_now()
    }

    Phoenix.PubSub.broadcast(
      AgentService.PubSub,
      "sensors:run_monitor",
      {:sensor_event, event}
    )

    Logger.debug("RunMonitor emitted #{event_type}: #{inspect(data)}")
  end
end
