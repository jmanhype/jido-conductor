import Config

config :agent_service, AgentServiceWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "TEST_SECRET_KEY_BASE_FOR_TESTING_ONLY",
  server: false

config :logger, level: :warning
