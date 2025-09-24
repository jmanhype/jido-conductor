defmodule AgentService.MixProject do
  use Mix.Project

  def project do
    [
      app: :agent_service,
      version: "0.1.0",
      elixir: "~> 1.16",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      mod: {AgentService.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      # Core JIDO framework
      {:jido, "~> 1.0.0"},
      {:jido_ai, github: "agentjido/jido_ai"},
      
      # Web framework
      {:phoenix, "~> 1.7.14"},
      {:bandit, "~> 1.5"},
      {:jason, "~> 1.2"},
      {:cors_plug, "~> 3.0"},
      
      # Utilities
      {:elixir_uuid, "~> 1.2"},
      {:yaml_elixir, "~> 2.11"},
      
      # Database
      {:ecto, "~> 3.11"},
      {:ecto_sqlite3, "~> 0.17"},
      
      # Telemetry
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.0"},
      
      # LiveView (for future UI)
      {:phoenix_live_view, "~> 1.0"},
      {:plug_cowboy, "~> 2.5"}
    ]
  end
end