defmodule AgentService.Runs.Store do
  @moduledoc """
  In-memory store for runs. In production, this would use Ecto/SQLite.
  """

  use Agent

  def start_link(_) do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  def list_runs do
    Agent.get(__MODULE__, fn state ->
      Map.values(state)
    end)
  end

  def get_run(id) do
    Agent.get(__MODULE__, fn state ->
      Map.get(state, id)
    end)
  end

  def create_run(run) do
    Agent.update(__MODULE__, fn state ->
      Map.put(state, run.id, run)
    end)

    {:ok, run}
  end

  def update_run_status(id, status) do
    Agent.update(__MODULE__, fn state ->
      case Map.get(state, id) do
        nil -> state
        run -> Map.put(state, id, %{run | status: status})
      end
    end)
  end
end
