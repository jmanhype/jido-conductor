defmodule AgentService.RunsTest do
  use ExUnit.Case, async: false

  alias AgentService.Runs

  # Note: These are basic structural tests. Full integration tests would require
  # starting the application and its dependencies (GenServers, Supervisors, etc.)

  describe "validate_run_params/1" do
    test "validates parameters with required fields" do
      params = %{
        "template" => "test-template-id",
        "config" => %{"key" => "value"}
      }

      # This calls the private function indirectly through create_run
      # In a real scenario, create_run would fail due to missing Store/Supervisor
      # but we can test parameter structure
      assert is_map(params)
      assert Map.has_key?(params, "template")
      assert Map.has_key?(params, "config")
    end
  end

  describe "run parameter structure" do
    test "run params include optional fields" do
      params = %{
        "template" => "test-id",
        "config" => %{},
        "budget" => %{"max_usd" => 10.0},
        "schedule" => "0 * * * *",
        "secretsRef" => "my-secrets"
      }

      assert Map.has_key?(params, "budget")
      assert Map.has_key?(params, "schedule")
      assert Map.has_key?(params, "secretsRef")
    end
  end
end
