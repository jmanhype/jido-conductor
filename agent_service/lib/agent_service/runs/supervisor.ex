defmodule AgentService.Runs.Supervisor do
  use DynamicSupervisor

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_run(run_id, config) do
    spec = {AgentService.Runs.JidoWorker, {run_id, config}}
    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  def stop_run(run_id) do
    case Registry.lookup(AgentService.RunRegistry, run_id) do
      [{pid, _}] ->
        DynamicSupervisor.terminate_child(__MODULE__, pid)
      [] ->
        {:error, :not_found}
    end
  end

  def list_runs do
    DynamicSupervisor.which_children(__MODULE__)
    |> Enum.map(fn {_, pid, _, _} ->
      GenServer.call(pid, :get_state)
    end)
  end
end