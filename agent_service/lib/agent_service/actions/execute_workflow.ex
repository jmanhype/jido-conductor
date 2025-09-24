defmodule AgentService.Actions.ExecuteWorkflow do
  @moduledoc """
  JIDO Action for executing workflow steps within a template
  """
  use Jido.Action,
    name: "execute_workflow",
    description: "Execute a workflow step defined in the template",
    schema: [
      workflow_name: [type: :string, required: true],
      context: [type: :map, required: true],
      config: [type: :map, default: %{}]
    ]

  require Logger

  @impl true
  def run(params, agent_context) do
    Logger.info("Executing workflow: #{params.workflow_name}")
    
    # Build workflow context
    workflow_context = Map.merge(params.context, %{
      workflow_name: params.workflow_name,
      config: params.config,
      run_id: agent_context[:run_id],
      template_id: agent_context[:template_id]
    })
    
    case execute_workflow_logic(params.workflow_name, workflow_context) do
      {:ok, result} ->
        {:ok, %{
          workflow: params.workflow_name,
          result: result,
          executed_at: DateTime.utc_now()
        }}
      
      {:error, reason} ->
        {:error, %{
          workflow: params.workflow_name,
          reason: reason,
          failed_at: DateTime.utc_now()
        }}
    end
  end

  defp execute_workflow_logic("monitor_web", context) do
    # Example workflow for web monitoring
    urls = get_in(context, [:config, "urls"]) || []
    
    results = Enum.map(urls, fn url ->
      case AgentService.Actions.FetchUrl.run(%{url: url}, context) do
        {:ok, data} -> %{url: url, status: :success, content: data.content}
        {:error, error} -> %{url: url, status: :failed, error: error}
      end
    end)
    
    {:ok, %{urls_checked: length(urls), results: results}}
  end

  defp execute_workflow_logic("summarize", context) do
    # Example workflow for summarization
    content = context[:content] || ""
    
    prompt = """
    Please summarize the following content:
    
    #{content}
    
    Provide a concise summary highlighting the key points.
    """
    
    case AgentService.Actions.ClaudeChat.run(%{prompt: prompt}, context) do
      {:ok, data} -> {:ok, %{summary: data.text}}
      {:error, error} -> {:error, error}
    end
  end

  defp execute_workflow_logic(workflow_name, _context) do
    {:error, "Unknown workflow: #{workflow_name}"}
  end
end