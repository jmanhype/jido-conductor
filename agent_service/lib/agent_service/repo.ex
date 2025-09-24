defmodule AgentService.Repo do
  use Ecto.Repo,
    otp_app: :agent_service,
    adapter: Ecto.Adapters.SQLite3
end
