defmodule AgentService.Agents.TemplateRunner do
  @moduledoc """
  JIDO Agent for executing templates with configurable actions and workflows
  """
  use Jido.Agent,
    name: "template_runner",
    description: "Executes JIDO templates with LLM integration and workflow orchestration",
    actions: [
      AgentService.Actions.ClaudeChat,
      AgentService.Actions.FetchUrl,
      AgentService.Actions.SaveArtifact
    ],
    schema: [
      template_id: [type: :string, required: true],
      template_config: [type: :map, required: true],
      run_id: [type: :string, required: true],
      status: [type: :atom, default: :initializing],
      current_step: [type: :string, default: nil],
      artifacts: [type: {:list, :map}, default: []],
      logs: [type: {:list, :map}, default: []],
      total_tokens: [type: :integer, default: 0],
      total_cost: [type: :float, default: 0.0],
      started_at: [type: :utc_datetime],
      completed_at: [type: :utc_datetime],
      error: [type: :map, default: nil],
      budget: [type: :map, default: %{}],
      context: [type: :map, default: %{}],
      conductor_config: [type: :map, default: %{}],
      workspace_dir: [type: :string, default: nil]
    ]

  require Logger
  import OK, only: [success: 1, failure: 1]
  alias AgentService.Config.{ConductorConfig, ScriptExecutor}

  @impl true
  def on_before_run(agent) do
    # Start the template execution workflow
    Logger.info("Initializing template runner for run #{agent.state.run_id}")
    
    # Create workspace for this run
    template_dir = get_template_dir(agent.state.template_id)
    
    with {:ok, workspace_dir} <- ScriptExecutor.create_workspace(agent.state.template_id, agent.state.run_id),
         :ok <- copy_template_to_workspace(template_dir, workspace_dir),
         {:ok, conductor_config} <- ConductorConfig.load_from_template(workspace_dir),
         {:ok, manifest} <- load_template_manifest(agent.state.template_id) do
      
      # Update agent state with conductor config and workspace
      updated_agent = agent
        |> Map.put(:state, Map.put(agent.state, :manifest, manifest))
        |> Map.put(:state, Map.put(agent.state, :conductor_config, conductor_config))
        |> Map.put(:state, Map.put(agent.state, :workspace_dir, workspace_dir))
        |> Map.put(:state, Map.put(agent.state, :status, :running))
        |> Map.put(:state, Map.put(agent.state, :started_at, DateTime.utc_now()))
      
      # Execute setup script if defined
      case ScriptExecutor.execute(:setup, conductor_config, workspace_dir, agent.state.template_config) do
        {:ok, _output} ->
          Logger.info("Setup script completed successfully")
          updated_agent
          |> schedule_next_step()
          |> success()
        
        {:error, reason} ->
          Logger.error("Setup script failed: #{reason}")
          updated_agent
          |> Map.put(:state, Map.put(agent.state, :status, :failed))
          |> Map.put(:state, Map.put(agent.state, :error, %{reason: "Setup failed: #{reason}", timestamp: DateTime.utc_now()}))
          |> broadcast_failure("Setup failed: #{reason}")
          |> (&failure(&1)).()  # Return failure with agent
      end
    else
      {:error, reason} ->
        agent
        |> Map.put(:state, Map.put(agent.state, :status, :failed))
        |> Map.put(:state, Map.put(agent.state, :error, %{reason: reason, timestamp: DateTime.utc_now()}))
        |> broadcast_failure(reason)
        |> (&failure(&1)).()  # Return failure with agent
    end
  end

  # Custom logging function (not a JIDO callback)
  def log_action_execution(agent, action, params) do
    # Log action execution
    log_entry = %{
      timestamp: DateTime.utc_now(),
      action: action.name,
      params: params,
      step: agent.state.current_step
    }
    
    agent
    |> Map.update!(:state, fn state -> Map.update(state, :logs, [log_entry], &[log_entry | &1]) end)
    |> broadcast_log(log_entry)
  end

  @impl true  
  def on_after_run(agent, _result, _unapplied_directives) do
    # Execute archive script if defined
    if agent.state.conductor_config && agent.state.workspace_dir do
      case ScriptExecutor.execute(:archive, agent.state.conductor_config, agent.state.workspace_dir) do
        {:ok, _output} ->
          Logger.info("Archive script completed successfully")
        {:error, reason} ->
          Logger.warning("Archive script failed: #{reason}")
      end
      
      # Clean up workspace
      ScriptExecutor.cleanup_workspace(agent.state.workspace_dir)
    end
    
    # Mark as completed
    agent
    |> Map.put(:state, Map.put(agent.state, :status, :completed))
    |> Map.put(:state, Map.put(agent.state, :completed_at, DateTime.utc_now()))
    |> broadcast_progress()
    |> OK.success()
  end

  # Private functions

  defp load_template_manifest(template_id) do
    templates_dir = Path.expand("~/.jido/templates")
    manifest_path = Path.join([templates_dir, template_id, "jido-template.yaml"])
    
    if File.exists?(manifest_path) do
      YamlElixir.read_from_file(manifest_path)
    else
      {:error, "Template manifest not found: #{template_id}"}
    end
  end

  defp schedule_next_step(agent) do
    # Get the next workflow step from the manifest
    case get_next_workflow_step(agent) do
      {:ok, step} ->
        agent
        |> Map.put(:state, Map.put(agent.state, :current_step, step.name))
        |> execute_workflow_step(step)
      
      :complete ->
        agent
        |> Map.put(:state, Map.put(agent.state, :status, :completed))
        |> Map.put(:state, Map.put(agent.state, :completed_at, DateTime.utc_now()))
        |> broadcast_completion()
      
      {:error, reason} ->
        agent
        |> Map.put(:state, Map.put(agent.state, :status, :failed))
        |> Map.put(:state, Map.put(agent.state, :error, %{reason: reason}))
        |> broadcast_failure(reason)
    end
  end

  defp get_next_workflow_step(agent) do
    manifest = agent.state.manifest
    current = agent.state.current_step
    
    # Simple workflow progression - in production, this would be more sophisticated
    commands = Map.get(manifest, "commands", [])
    
    if current == nil && length(commands) > 0 do
      {:ok, List.first(commands)}
    else
      # Find next command after current
      current_index = Enum.find_index(commands, &(&1["name"] == current))
      
      if current_index && current_index < length(commands) - 1 do
        {:ok, Enum.at(commands, current_index + 1)}
      else
        :complete
      end
    end
  end

  defp execute_workflow_step(agent, step) do
    # Execute the workflow step based on its type
    cond do
      Map.has_key?(step, "hook") ->
        execute_hook(agent, step["hook"])
      
      Map.has_key?(step, "run") ->
        execute_workflow(agent, step["run"])
      
      Map.has_key?(step, "subagent") ->
        execute_subagent(agent, step["subagent"])
      
      true ->
        # Default to running the command steps
        execute_command_steps(agent, step)
    end
  end

  defp execute_hook(agent, hook_name) do
    # Load and execute hook content
    hook_path = Path.join([
      Path.expand("~/.jido/templates"),
      agent.state.template_id,
      hook_name
    ])
    
    if File.exists?(hook_path) do
      hook_content = File.read!(hook_path)
      
      # Execute hook as Claude prompt
      params = %{
        prompt: hook_content,
        model: get_llm_model(agent)
      }
      
      agent
      # TODO: Execute Claude action using proper JIDO v1.2.0 API
    agent
      |> schedule_next_step()
    else
      Logger.warning("Hook not found: #{hook_name}")
      schedule_next_step(agent)
    end
  end

  defp execute_workflow(agent, _workflow_path) do
    # Workflows not yet fully implemented - skip for now
    Logger.warning("Workflow execution not fully implemented yet")
    schedule_next_step(agent)
  end

  defp execute_subagent(agent, subagent_id) do
    # Execute a sub-agent (Claude subagent)
    subagent_prompt = build_subagent_prompt(agent, subagent_id)
    
    params = %{
      prompt: subagent_prompt,
      model: get_llm_model(agent)
    }
    
    agent
    # TODO: Execute Claude action using proper JIDO v1.2.0 API
    agent
    |> schedule_next_step()
  end

  defp execute_command_steps(agent, command) do
    steps = Map.get(command, "steps", [])
    
    # Execute each step in the command
    Enum.reduce(steps, agent, fn step, acc_agent ->
      execute_workflow_step(acc_agent, step)
    end)
    |> schedule_next_step()
  end

  defp build_subagent_prompt(agent, subagent_id) do
    """
    You are acting as a specialized sub-agent: #{subagent_id}
    
    Current context:
    - Template: #{agent.state.template_id}
    - Step: #{agent.state.current_step}
    - Configuration: #{inspect(agent.state.template_config)}
    
    Please perform your specialized task based on the above context.
    """
  end

  defp get_llm_model(agent) do
    # Get LLM model from manifest or use default
    manifest = agent.state.manifest
    providers = Map.get(manifest, "providers", %{})
    llm = Map.get(providers, "llm", %{})
    Map.get(llm, "model", "claude-3-5-sonnet")
  end

  defp calculate_cost(data) do
    tokens_in = Map.get(data, :tokens_in, 0)
    tokens_out = Map.get(data, :tokens_out, 0)
    
    # Claude 3.5 Sonnet pricing
    (tokens_in * 0.000003) + (tokens_out * 0.000015)
  end

  defp check_budget_limits(agent) do
    budget = agent.state.budget
    
    cond do
      budget[:max_tokens] && agent.state.total_tokens > budget.max_tokens ->
        agent
        |> Map.put(:state, Map.put(agent.state, :status, :stopped))
        |> Map.put(:state, Map.put(agent.state, :error, %{reason: "Token budget exceeded"}))
        |> broadcast_budget_exceeded()
      
      budget[:max_usd] && agent.state.total_cost > budget.max_usd ->
        agent
        |> Map.put(:state, Map.put(agent.state, :status, :stopped))
        |> Map.put(:state, Map.put(agent.state, :error, %{reason: "Cost budget exceeded"}))
        |> broadcast_budget_exceeded()
      
      true ->
        agent
    end
  end

  # Broadcasting functions

  defp broadcast_log(agent, log_entry) do
    Phoenix.PubSub.broadcast(
      AgentService.PubSub,
      "runs:#{agent.state.run_id}",
      {:log_entry, log_entry}
    )
    agent
  end

  defp broadcast_progress(agent) do
    Phoenix.PubSub.broadcast(
      AgentService.PubSub,
      "runs:#{agent.state.run_id}",
      {:progress, %{
        status: agent.state.status,
        current_step: agent.state.current_step,
        total_tokens: agent.state.total_tokens,
        total_cost: agent.state.total_cost
      }}
    )
    agent
  end

  defp broadcast_completion(agent) do
    Phoenix.PubSub.broadcast(
      AgentService.PubSub,
      "runs:#{agent.state.run_id}",
      {:run_completed, agent.state.run_id}
    )
    agent
  end

  defp broadcast_failure(agent, reason) do
    Phoenix.PubSub.broadcast(
      AgentService.PubSub,
      "runs:#{agent.state.run_id}",
      {:run_failed, %{run_id: agent.state.run_id, reason: reason}}
    )
    agent
  end

  defp broadcast_budget_exceeded(agent) do
    Phoenix.PubSub.broadcast(
      AgentService.PubSub,
      "runs:#{agent.state.run_id}",
      {:budget_exceeded, %{
        run_id: agent.state.run_id,
        total_tokens: agent.state.total_tokens,
        total_cost: agent.state.total_cost
      }}
    )
    agent
  end
  
  defp get_template_dir(template_id) do
    Path.join([Path.expand("~/.jido/templates"), template_id])
  end
  
  defp copy_template_to_workspace(template_dir, workspace_dir) do
    # Copy template files to workspace
    case System.cmd("cp", ["-r", "#{template_dir}/.", workspace_dir]) do
      {_, 0} -> :ok
      {output, code} -> {:error, "Failed to copy template: #{output} (exit code: #{code})"}
    end
  end
end