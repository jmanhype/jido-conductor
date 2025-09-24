defmodule AgentService.Runs do
  @moduledoc """
  Context module for managing agent runs
  """

  alias AgentService.Runs.{Supervisor, Store}
  require Logger

  def list_runs do
    Store.list_runs()
  end

  def get_run(id) do
    Store.get_run(id)
  end

  def create_run(params) do
    with {:ok, validated} <- validate_run_params(params),
         {:ok, run} <- Store.create_run(validated),
         {:ok, _pid} <- Supervisor.start_run(run.id, run) do
      {:ok, run}
    end
  end

  def stop_run(id) do
    case Supervisor.stop_run(id) do
      :ok ->
        Store.update_run_status(id, "stopped")
        :ok

      error ->
        error
    end
  end

  defp validate_run_params(params) do
    required = ["template", "config"]

    if Enum.all?(required, &Map.has_key?(params, &1)) do
      run_params = %{
        id: UUID.uuid4(:hex),
        template_id: params["template"],
        config: params["config"],
        status: "running",
        started_at: DateTime.utc_now(),
        budget: Map.get(params, "budget"),
        schedule: Map.get(params, "schedule"),
        secrets_ref: Map.get(params, "secretsRef")
      }

      {:ok, run_params}
    else
      {:error, "Missing required parameters: template and config"}
    end
  end
end
