defmodule AgentServiceWeb.Router do
  use AgentServiceWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
    plug AgentServiceWeb.Auth
  end

  scope "/v1", AgentServiceWeb do
    pipe_through :api

    get "/healthz", HealthController, :index
    get "/stats", StatsController, :index

    resources "/templates", TemplateController, only: [:index, :show]
    post "/templates/install", TemplateController, :install

    resources "/runs", RunController, only: [:index, :show, :create]
    post "/runs/:id/stop", RunController, :stop
    get "/runs/:id/logs", RunController, :logs
  end
end