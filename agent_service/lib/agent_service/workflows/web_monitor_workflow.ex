defmodule AgentService.Workflows.WebMonitorWorkflow do
  @moduledoc """
  JIDO Workflow for web monitoring and summarization
  """
  use AgentService.Workflows.BaseWorkflow
  
  alias AgentService.Actions.{FetchUrl, ClaudeChat, SaveArtifact}

  @doc """
  Main workflow execution
  """
  def execute(agent, config) do
    log_step("Starting web monitor workflow")
    
    with {:ok, agent} <- fetch_all_urls(agent, config),
         {:ok, agent} <- analyze_changes(agent),
         {:ok, agent} <- generate_summary(agent),
         {:ok, agent} <- save_report(agent) do
      log_step("Web monitor workflow completed successfully")
      {:ok, agent}
    else
      {:error, reason} = error ->
        log_step("Workflow failed: #{inspect(reason)}", :error)
        error
    end
  end

  # Step 1: Fetch all URLs
  defp fetch_all_urls(agent, config) do
    urls = config["urls"] || []
    log_step("Fetching #{length(urls)} URLs")
    
    fetch_tasks = Enum.map(urls, fn url ->
      {FetchUrl, %{url: url, extract_text: true}}
    end)
    
    case parallel_actions(agent, fetch_tasks) do
      {:ok, results} ->
        # Store results in agent state
        agent = Jido.Agent.put_state(agent, :url_results, results)
        {:ok, agent}
      
      {:error, _} = error ->
        error
    end
  end

  # Step 2: Analyze changes (compare with previous fetch if available)
  defp analyze_changes(agent) do
    log_step("Analyzing changes in fetched content")
    
    url_results = agent.state[:url_results] || []
    previous_results = load_previous_results(agent.state.run_id)
    
    changes = detect_changes(url_results, previous_results)
    
    agent = agent
    |> Jido.Agent.put_state(:changes, changes)
    |> Jido.Agent.put_state(:has_changes, length(changes) > 0)
    
    {:ok, agent}
  end

  # Step 3: Generate summary using Claude
  defp generate_summary(agent) do
    log_step("Generating summary with Claude")
    
    if agent.state[:has_changes] do
      changes = agent.state[:changes]
      
      prompt = build_summary_prompt(changes)
      
      params = %{
        prompt: prompt,
        model: "claude-3-5-sonnet",
        max_tokens: 2000
      }
      
      case Jido.Agent.run_action(agent, ClaudeChat, params) do
        {:ok, result} ->
          agent = Jido.Agent.put_state(agent, :summary, result.data.text)
          {:ok, agent}
        
        error ->
          error
      end
    else
      log_step("No changes detected, skipping summary generation")
      agent = Jido.Agent.put_state(agent, :summary, "No changes detected in monitored URLs.")
      {:ok, agent}
    end
  end

  # Step 4: Save report as artifact
  defp save_report(agent) do
    log_step("Saving monitoring report")
    
    report = generate_report(agent)
    
    params = %{
      run_id: agent.state.run_id,
      filename: "monitor_report_#{DateTime.to_unix(DateTime.utc_now())}.md",
      content: report,
      content_type: "text/markdown",
      metadata: %{
        urls_monitored: length(agent.state[:url_results] || []),
        changes_detected: agent.state[:has_changes],
        timestamp: DateTime.utc_now()
      }
    }
    
    case Jido.Agent.run_action(agent, SaveArtifact, params) do
      {:ok, _} ->
        log_step("Report saved successfully")
        {:ok, agent}
      
      error ->
        error
    end
  end

  # Helper functions

  defp load_previous_results(run_id) do
    # Load previous results from storage
    # In a real implementation, this would query the database or filesystem
    []
  end

  defp detect_changes(current, previous) do
    # Simple change detection - in production, use more sophisticated diffing
    if length(previous) == 0 do
      Enum.map(current, fn result ->
        %{
          url: get_in(result, [:data, :url]),
          status: :new,
          content: get_in(result, [:data, :content])
        }
      end)
    else
      # Compare current with previous
      Enum.map(current, fn result ->
        url = get_in(result, [:data, :url])
        prev = Enum.find(previous, &(&1[:url] == url))
        
        if prev && prev[:content] != get_in(result, [:data, :content]) do
          %{
            url: url,
            status: :changed,
            content: get_in(result, [:data, :content])
          }
        else
          %{
            url: url,
            status: :unchanged,
            content: get_in(result, [:data, :content])
          }
        end
      end)
      |> Enum.filter(&(&1.status != :unchanged))
    end
  end

  defp build_summary_prompt(changes) do
    changes_text = Enum.map(changes, fn change ->
      "- #{change.url} (#{change.status}): #{String.slice(change.content || "", 0, 200)}..."
    end) |> Enum.join("\n")
    
    """
    Please analyze and summarize the following web monitoring results:
    
    #{changes_text}
    
    Provide a concise summary highlighting:
    1. Key changes detected
    2. Important information or updates
    3. Any patterns or trends noticed
    4. Recommendations for action if applicable
    
    Format the response as a clear, professional monitoring report.
    """
  end

  defp generate_report(agent) do
    """
    # Web Monitoring Report
    
    **Generated:** #{DateTime.utc_now() |> DateTime.to_string()}
    **Run ID:** #{agent.state.run_id}
    
    ## Summary
    
    #{agent.state[:summary] || "No summary available."}
    
    ## URLs Monitored
    
    #{format_url_results(agent.state[:url_results] || [])}
    
    ## Changes Detected
    
    #{if agent.state[:has_changes], do: format_changes(agent.state[:changes] || []), else: "No changes detected."}
    
    ## Metrics
    
    - Total URLs: #{length(agent.state[:url_results] || [])}
    - Changes Found: #{length(agent.state[:changes] || [])}
    - Tokens Used: #{agent.state[:total_tokens] || 0}
    - Cost: $#{Float.round(agent.state[:total_cost] || 0.0, 4)}
    
    ---
    
    *Generated by JIDO Conductor*
    """
  end

  defp format_url_results(results) do
    results
    |> Enum.map(fn result ->
      case result do
        {:ok, data} ->
          "- ✅ #{data.data.url}"
        {:error, error} ->
          "- ❌ Failed: #{inspect(error)}"
        _ ->
          "- Unknown result"
      end
    end)
    |> Enum.join("\n")
  end

  defp format_changes(changes) do
    changes
    |> Enum.map(fn change ->
      emoji = case change.status do
        :new -> "🆕"
        :changed -> "🔄"
        _ -> "📝"
      end
      
      "#{emoji} **#{change.url}**\n   Status: #{change.status}"
    end)
    |> Enum.join("\n\n")
  end
end