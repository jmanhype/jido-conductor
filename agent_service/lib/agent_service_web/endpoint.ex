defmodule AgentServiceWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :agent_service

  @session_options [
    store: :cookie,
    key: "_agent_service_key",
    signing_salt: "J8K9L0M1",
    same_site: "Lax"
  ]

  plug CORSPlug, origin: ["http://localhost:1420", "tauri://localhost"]

  plug Plug.Static,
    at: "/",
    from: :agent_service,
    gzip: false,
    only: AgentServiceWeb.static_paths()

  if code_reloading? do
    plug Phoenix.CodeReloader
    plug Phoenix.Ecto.CheckRepoStatus, otp_app: :agent_service
  end

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options
  plug AgentServiceWeb.Router
end