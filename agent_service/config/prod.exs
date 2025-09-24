import Config

config :agent_service, AgentServiceWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 8745],
  secret_key_base: System.get_env("SECRET_KEY_BASE")

config :logger, level: :info