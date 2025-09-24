defmodule AgentService.Config.ScriptExecutor do
  @moduledoc """
  Executes scripts defined in conductor.json (setup, run, archive).
  Handles script lifecycle, environment variables, and workspace isolation.
  """

  require Logger
  alias AgentService.Config.ConductorConfig

  @doc """
  Execute a script in the context of a template workspace.
  
  ## Parameters
    - script_type: :setup | :run | :archive
    - config: Parsed conductor.json configuration
    - workspace_dir: Directory where the script should run
    - env: Additional environment variables to pass
    
  ## Returns
    - {:ok, output} on success
    - {:error, reason} on failure
  """
  def execute(script_type, config, workspace_dir, env \\ %{}) 
      when script_type in [:setup, :run, :archive] do
    
    script_path = ConductorConfig.get_script_path(config, script_type, workspace_dir)
    
    if script_path && File.exists?(script_path) do
      Logger.info("Executing #{script_type} script: #{script_path}")
      
      # Prepare environment
      full_env = ConductorConfig.get_env(config, env)
      
      # Add workspace-specific environment variables
      workspace_env = %{
        "WORKSPACE_DIR" => workspace_dir,
        "TEMPLATE_NAME" => Map.get(config, "name", "unknown"),
        "TEMPLATE_VERSION" => Map.get(config, "version", "1.0.0"),
        "SCRIPT_TYPE" => to_string(script_type)
      }
      
      final_env = Map.merge(full_env, workspace_env)
      
      # Execute the script
      run_script(script_path, workspace_dir, final_env, config)
    else
      # No script defined for this phase
      {:ok, "No #{script_type} script defined"}
    end
  end

  @doc """
  Execute all lifecycle scripts for a template run.
  """
  def execute_lifecycle(config, workspace_dir, env \\ %{}) do
    with {:ok, setup_output} <- execute(:setup, config, workspace_dir, env),
         {:ok, run_output} <- execute(:run, config, workspace_dir, env),
         {:ok, archive_output} <- execute(:archive, config, workspace_dir, env) do
      {:ok, %{
        setup: setup_output,
        run: run_output,
        archive: archive_output
      }}
    else
      {:error, {phase, reason}} ->
        {:error, "Failed during #{phase}: #{reason}"}
    end
  end

  @doc """
  Create a workspace directory for template execution.
  """
  def create_workspace(template_name, run_id) do
    workspace_root = get_workspace_root()
    workspace_dir = Path.join([workspace_root, template_name, run_id])
    
    case File.mkdir_p(workspace_dir) do
      :ok -> 
        Logger.info("Created workspace: #{workspace_dir}")
        {:ok, workspace_dir}
      {:error, reason} -> 
        {:error, "Failed to create workspace: #{reason}"}
    end
  end

  @doc """
  Clean up a workspace directory.
  """
  def cleanup_workspace(workspace_dir) do
    if File.exists?(workspace_dir) do
      case File.rm_rf(workspace_dir) do
        {:ok, _} ->
          Logger.info("Cleaned up workspace: #{workspace_dir}")
          :ok
        {:error, reason} ->
          Logger.warn("Failed to cleanup workspace: #{reason}")
          {:error, reason}
      end
    else
      :ok
    end
  end

  # Private functions

  defp run_script(script_path, working_dir, env, config) do
    timeout = ConductorConfig.get_timeout(config) * 1000  # Convert to milliseconds
    
    # Determine script interpreter based on file extension
    cmd = case Path.extname(script_path) do
      ".sh" -> "bash"
      ".py" -> "python"
      ".js" -> "node"
      ".ts" -> "tsx"
      ".exs" -> "elixir"
      _ -> "bash"  # Default to bash
    end
    
    # Build environment list for System.cmd
    env_list = Enum.map(env, fn {k, v} -> {String.to_charlist(k), String.to_charlist(v)} end)
    
    # Execute the script
    case System.cmd(cmd, [script_path], [
      cd: working_dir,
      env: env_list,
      stderr_to_stdout: true,
      timeout: timeout
    ]) do
      {output, 0} ->
        Logger.debug("Script output: #{output}")
        {:ok, output}
      
      {output, exit_code} ->
        Logger.error("Script failed with exit code #{exit_code}: #{output}")
        {:error, "Script failed with exit code #{exit_code}"}
    end
  rescue
    e ->
      Logger.error("Script execution error: #{inspect(e)}")
      {:error, "Script execution failed: #{Exception.message(e)}"}
  end

  defp get_workspace_root do
    Application.get_env(:agent_service, :workspace_root, "/tmp/jido_workspaces")
  end
end