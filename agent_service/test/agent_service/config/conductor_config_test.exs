defmodule AgentService.Config.ConductorConfigTest do
  use ExUnit.Case, async: true

  alias AgentService.Config.ConductorConfig

  describe "validate_config/1" do
    test "validates a valid configuration" do
      config = %{
        "name" => "test-template",
        "version" => "1.0.0",
        "setup" => "setup.sh",
        "run" => "run.sh",
        "env" => %{"KEY" => "value"},
        "budget" => %{"max_usd" => 10.0}
      }

      assert {:ok, ^config} = ConductorConfig.validate_config(config)
    end

    test "returns error for non-map config" do
      assert {:error, "conductor.json must be a JSON object"} =
               ConductorConfig.validate_config("not a map")
    end

    test "validates script values are strings" do
      config = %{"setup" => 123}

      assert {:error, message} = ConductorConfig.validate_config(config)
      assert message =~ "Invalid script values"
    end

    test "validates env must be string key-value pairs" do
      config = %{"env" => %{"key" => 123}}

      assert {:error, "env must contain only string keys and values"} =
               ConductorConfig.validate_config(config)
    end

    test "validates budget max_usd must be positive number" do
      config = %{"budget" => %{"max_usd" => -5.0}}

      assert {:error, "Invalid budget constraints"} =
               ConductorConfig.validate_config(config)
    end

    test "validates budget max_tokens must be positive integer" do
      config = %{"budget" => %{"max_tokens" => -100}}

      assert {:error, "Invalid budget constraints"} =
               ConductorConfig.validate_config(config)
    end
  end

  describe "get_env/2" do
    test "merges environment variables with correct precedence" do
      config = %{"env" => %{"KEY1" => "from_config", "KEY2" => "config_only"}}
      additional = %{"KEY1" => "from_additional", "KEY3" => "additional_only"}

      result = ConductorConfig.get_env(config, additional)

      # Additional env should override config env
      assert result["KEY1"] == "from_additional"
      assert result["KEY2"] == "config_only"
      assert result["KEY3"] == "additional_only"
      # System env should be present but overridden
      assert is_map(result)
    end
  end

  describe "get_script_path/3" do
    test "returns full path when script is defined" do
      config = %{"run" => "scripts/run.sh"}
      template_dir = "/tmp/template"

      assert ConductorConfig.get_script_path(config, :run, template_dir) ==
               "/tmp/template/scripts/run.sh"
    end

    test "returns nil when script is not defined" do
      config = %{}
      template_dir = "/tmp/template"

      assert ConductorConfig.get_script_path(config, :run, template_dir) == nil
    end
  end

  describe "parallel_enabled?/1" do
    test "returns true when parallel is explicitly true" do
      config = %{"parallel" => true}
      assert ConductorConfig.parallel_enabled?(config) == true
    end

    test "returns false when parallel is false" do
      config = %{"parallel" => false}
      assert ConductorConfig.parallel_enabled?(config) == false
    end

    test "returns false when parallel is not set" do
      config = %{}
      assert ConductorConfig.parallel_enabled?(config) == false
    end
  end

  describe "get_timeout/1" do
    test "returns configured timeout" do
      config = %{"timeout" => 7200}
      assert ConductorConfig.get_timeout(config) == 7200
    end

    test "returns default timeout when not configured" do
      config = %{}
      assert ConductorConfig.get_timeout(config) == 3600
    end
  end

  describe "get_budget/1" do
    test "returns budget constraints when configured" do
      config = %{"budget" => %{"max_usd" => 25.0, "max_tokens" => 100_000}}
      budget = ConductorConfig.get_budget(config)

      assert budget.max_usd == 25.0
      assert budget.max_tokens == 100_000
    end

    test "returns nil values when budget not configured" do
      config = %{}
      budget = ConductorConfig.get_budget(config)

      assert budget.max_usd == nil
      assert budget.max_tokens == nil
    end
  end
end
