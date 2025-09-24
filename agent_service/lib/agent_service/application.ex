defmodule AgentService.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      AgentService.Repo,
      {Phoenix.PubSub, name: AgentService.PubSub},
      {Registry, keys: :unique, name: AgentService.RunRegistry},
      AgentServiceWeb.Endpoint,
      AgentService.Runs.Supervisor,
      {AgentService.Templates.Registry, []},
      {AgentService.Runs.Store, []}
    ]

    opts = [strategy: :one_for_one, name: AgentService.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    AgentServiceWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
