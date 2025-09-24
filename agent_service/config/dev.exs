import Config

config :agent_service, AgentServiceWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 8745],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "YK0PZ9XZ8K9L0M1N2O3P4Q5R6S7T8U9V0W1X2Y3Z4A5B6C7D8E9F0G1H2I3J4K5L",
  watchers: []

config :agent_service, dev_routes: true

config :logger, level: :debug

config :phoenix, :stacktrace_depth, 20

config :phoenix, :plug_init_mode, :runtime