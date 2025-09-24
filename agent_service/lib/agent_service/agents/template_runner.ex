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
      AgentService.Actions.SaveArtifact,
      AgentService.Actions.ExecuteWorkflow
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
      context: [type: :map, default: %{}]
    ]

  require Logger

  @impl true
  def on_after_init(agent) do
    # Start the template execution workflow
    Logger.info("Initializing template runner for run #{agent.state.run_id}")
    
    # Load template manifest
    case load_template_manifest(agent.state.template_id) do
      {:ok, manifest} ->
        agent
        |> put_state(:manifest, manifest)
        |> put_state(:status, :running)
        |> put_state(:started_at, DateTime.utc_now())
        |> schedule_next_step()
      
      {:error, reason} ->
        agent
        |> put_state(:status, :failed)
        |> put_state(:error, %{reason: reason, timestamp: DateTime.utc_now()})
        |> broadcast_failure(reason)
    end
  end

  @impl true
  def on_before_run_action(agent, action, params) do
    # Log action execution
    log_entry = %{
      timestamp: DateTime.utc_now(),
      action: action.name,
      params: params,
      step: agent.state.current_step
    }
    
    agent
    |> update_state(:logs, &[log_entry | &1])
    |> broadcast_log(log_entry)
  end

  @impl true
  def on_after_run_action(agent, action, params, result) do
    case result do
      {:ok, data} ->
        # Update metrics if action returned token counts
        agent = if Map.has_key?(data, :tokens_out) do
          agent
          |> update_state(:total_tokens, &(&1 + Map.get(data, :tokens_in, 0) + Map.get(data, :tokens_out, 0)))
          |> update_state(:total_cost, &(&1 + calculate_cost(data)))
          |> check_budget_limits()
        else
          agent
        end
        
        # Store artifacts if produced
        agent = if Map.has_key?(data, :artifact) do
          update_state(agent, :artifacts, &[data.artifact | &1])
        else
          agent
        end
        
        broadcast_progress(agent)
        agent
        
      {:error, error} ->
        Logger.error("Action #{action.name} failed: #{inspect(error)}")
        
        agent
        |> put_state(:status, :failed)
        |> put_state(:error, error)
        |> put_state(:completed_at, DateTime.utc_now())
        |> broadcast_failure(error)
    end
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
        |> put_state(:current_step, step.name)
        |> execute_workflow_step(step)
      
      :complete ->
        agent
        |> put_state(:status, :completed)
        |> put_state(:completed_at, DateTime.utc_now())
        |> broadcast_completion()
      
      {:error, reason} ->
        agent
        |> put_state(:status, :failed)
        |> put_state(:error, %{reason: reason})
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
      |> run_action(AgentService.Actions.ClaudeChat, params)
      |> schedule_next_step()
    else
      Logger.warn("Hook not found: #{hook_name}")
      schedule_next_step(agent)
    end
  end

  defp execute_workflow(agent, workflow_path) do
    # Execute Elixir workflow file
    workflow_full_path = Path.join([
      Path.expand("~/.jido/templates"),
      agent.state.template_id,
      workflow_path
    ])
    
    if File.exists?(workflow_full_path) do
      # In production, this would be sandboxed
      Code.eval_file(workflow_full_path)
      schedule_next_step(agent)
    else
      agent
      |> put_state(:status, :failed)
      |> put_state(:error, %{reason: "Workflow not found: #{workflow_path}"})
    end
  end

  defp execute_subagent(agent, subagent_id) do
    # Execute a sub-agent (Claude subagent)
    subagent_prompt = build_subagent_prompt(agent, subagent_id)
    
    params = %{
      prompt: subagent_prompt,
      model: get_llm_model(agent)
    }
    
    agent
    |> run_action(AgentService.Actions.ClaudeChat, params)
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
        |> put_state(:status, :stopped)
        |> put_state(:error, %{reason: "Token budget exceeded"})
        |> broadcast_budget_exceeded()
      
      budget[:max_usd] && agent.state.total_cost > budget.max_usd ->
        agent
        |> put_state(:status, :stopped)
        |> put_state(:error, %{reason: "Cost budget exceeded"})
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
end