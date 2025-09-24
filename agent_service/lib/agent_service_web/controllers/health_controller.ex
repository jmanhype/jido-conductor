defmodule AgentServiceWeb.HealthController do
  use AgentServiceWeb, :controller

  def index(conn, _params) do
    health = %{
      status: "healthy",
      service: "agent-service",
      version: "0.1.0",
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
    }

    json(conn, health)
  end
end