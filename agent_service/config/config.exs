import Config

config :agent_service,
  ecto_repos: [AgentService.Repo]

config :agent_service, AgentService.Repo,
  database: Path.expand("~/.jido/conductor.db"),
  pool_size: 5,
  show_sensitive_data_on_connection_error: true

config :agent_service, AgentServiceWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [json: AgentServiceWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: AgentService.PubSub,
  live_view: [signing_salt: "J8K9L0M1"]

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :json_library, Jason

# Import environment specific config
import_config "#{config_env()}.exs"