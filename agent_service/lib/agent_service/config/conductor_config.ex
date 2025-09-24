defmodule AgentService.Config.ConductorConfig do
  @moduledoc """
  Parser and manager for conductor.json configuration files.
  Provides compatibility with Conductor's configuration format.
  """

  require Logger
  alias Jason

  @default_config %{
    "name" => "unnamed_template",
    "version" => "1.0.0",
    "description" => "",
    "setup" => nil,
    "run" => nil,
    "archive" => nil,
    "env" => %{},
    "requirements" => %{},
    "parallel" => false,
    "timeout" => 3600,
    "budget" => %{
      "max_usd" => nil,
      "max_tokens" => nil
    }
  }

  @doc """
  Load and parse a conductor.json file from the given path.
  Returns {:ok, config} or {:error, reason}
  """
  def load(path) do
    with {:ok, content} <- File.read(path),
         {:ok, json} <- Jason.decode(content),
         {:ok, config} <- validate_config(json) do
      {:ok, merge_with_defaults(config)}
    else
      {:error, %Jason.DecodeError{} = error} ->
        {:error, "Invalid JSON in conductor.json: #{Exception.message(error)}"}
      
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Load conductor.json from a template directory.
  Looks for conductor.json in the root of the template directory.
  """
  def load_from_template(template_path) do
    conductor_path = Path.join(template_path, "conductor.json")
    
    if File.exists?(conductor_path) do
      load(conductor_path)
    else
      # Fall back to default config if no conductor.json exists
      {:ok, @default_config}
    end
  end

  @doc """
  Validate a conductor configuration map.
  """
  def validate_config(config) when is_map(config) do
    with :ok <- validate_scripts(config),
         :ok <- validate_env(config),
         :ok <- validate_requirements(config),
         :ok <- validate_budget(config) do
      {:ok, config}
    end
  end

  def validate_config(_), do: {:error, "conductor.json must be a JSON object"}

  @doc """
  Get environment variables from config, merging with system env.
  """
  def get_env(config, additional_env \\ %{}) do
    config_env = Map.get(config, "env", %{})
    
    # Merge in order of precedence: additional > config > system
    System.get_env()
    |> Map.merge(stringify_map(config_env))
    |> Map.merge(stringify_map(additional_env))
  end

  @doc """
  Get script path relative to template directory.
  """
  def get_script_path(config, script_type, template_dir) when script_type in [:setup, :run, :archive] do
    script_name = Map.get(config, to_string(script_type))
    
    if script_name do
      Path.join(template_dir, script_name)
    else
      nil
    end
  end

  @doc """
  Check if parallel execution is enabled.
  """
  def parallel_enabled?(config) do
    Map.get(config, "parallel", false) == true
  end

  @doc """
  Get timeout in seconds (default 1 hour).
  """
  def get_timeout(config) do
    Map.get(config, "timeout", 3600)
  end

  @doc """
  Get budget constraints.
  """
  def get_budget(config) do
    budget = Map.get(config, "budget", %{})
    
    %{
      max_usd: get_in(budget, ["max_usd"]),
      max_tokens: get_in(budget, ["max_tokens"])
    }
  end

  # Private functions

  defp validate_scripts(config) do
    scripts = ["setup", "run", "archive"]
    
    invalid_scripts = 
      scripts
      |> Enum.filter(fn key -> 
        value = Map.get(config, key)
        value != nil and not is_binary(value)
      end)
    
    if Enum.empty?(invalid_scripts) do
      :ok
    else
      {:error, "Invalid script values for: #{Enum.join(invalid_scripts, ", ")}"}
    end
  end

  defp validate_env(config) do
    case Map.get(config, "env") do
      nil -> :ok
      env when is_map(env) -> 
        if Enum.all?(env, fn {k, v} -> is_binary(k) and is_binary(v) end) do
          :ok
        else
          {:error, "env must contain only string keys and values"}
        end
      _ -> {:error, "env must be an object"}
    end
  end

  defp validate_requirements(config) do
    case Map.get(config, "requirements") do
      nil -> :ok
      reqs when is_map(reqs) -> :ok
      _ -> {:error, "requirements must be an object"}
    end
  end

  defp validate_budget(config) do
    case Map.get(config, "budget") do
      nil -> :ok
      budget when is_map(budget) ->
        valid_max_usd = 
          case Map.get(budget, "max_usd") do
            nil -> true
            num when is_number(num) and num > 0 -> true
            _ -> false
          end
        
        valid_max_tokens =
          case Map.get(budget, "max_tokens") do
            nil -> true
            num when is_integer(num) and num > 0 -> true
            _ -> false
          end
        
        if valid_max_usd and valid_max_tokens do
          :ok
        else
          {:error, "Invalid budget constraints"}
        end
      _ -> {:error, "budget must be an object"}
    end
  end

  defp merge_with_defaults(config) do
    Map.merge(@default_config, config)
  end

  defp stringify_map(map) when is_map(map) do
    map
    |> Enum.map(fn {k, v} -> {to_string(k), to_string(v)} end)
    |> Enum.into(%{})
  end

  defp stringify_map(_), do: %{}
end