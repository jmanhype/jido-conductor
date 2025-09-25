defmodule AgentService.Actions.ClaudeChat do
  @moduledoc """
  JIDO Action for interacting with Claude via CLI
  """
  use Jido.Action,
    name: "claude_chat",
    description: "Chat with Claude using the Claude Code CLI",
    schema: [
      prompt: [type: :string, required: true],
      model: [type: :string, default: "claude-3-5-sonnet"],
      temperature: [type: :float, default: 0.7],
      max_tokens: [type: :integer, default: 4096]
    ]

  require Logger

  @timeout 60_000

  @impl true
  def run(params, context) do
    args = build_cli_args(params)

    case System.cmd("claude", args, stderr_to_stdout: true, timeout: @timeout) do
      {output, 0} ->
        parse_response(output, context)

      {output, exit_code} ->
        Logger.error("Claude CLI failed with exit code #{exit_code}: #{output}")

        {:error,
         %{
           reason: "Claude CLI command failed",
           details: output,
           exit_code: exit_code
         }}

      exception ->
        Logger.error("Claude CLI exception: #{inspect(exception)}")
        {:error, %{reason: "Failed to execute Claude CLI", details: inspect(exception)}}
    end
  end

  defp build_cli_args(params) do
    base_args = ["--output-format", "json", "chat", "--input", params.prompt]

    if params[:model] && params.model != "claude-3-5-sonnet" do
      base_args ++ ["--model", params.model]
    else
      base_args
    end
  end

  defp parse_response(output, context) do
    case Jason.decode(output) do
      {:ok, %{"text" => text} = json} ->
        # Track tokens and cost if available
        tokens_in = Map.get(json, "tokens_in", 0)
        tokens_out = Map.get(json, "tokens_out", 0)

        # Broadcast metrics if we have a run_id in context
        if context[:run_id] do
          broadcast_metrics(context.run_id, tokens_in, tokens_out)
        end

        {:ok,
         %{
           text: text,
           tokens_in: tokens_in,
           tokens_out: tokens_out,
           model: Map.get(json, "model", "unknown"),
           raw: json
         }}

      {:ok, json} ->
        {:ok, %{raw: json}}

      {:error, _} ->
        # Try to extract text from non-JSON output
        {:ok, %{text: String.trim(output)}}
    end
  end

  defp broadcast_metrics(run_id, tokens_in, tokens_out) do
    Phoenix.PubSub.broadcast(
      AgentService.PubSub,
      "runs:#{run_id}",
      {:metrics,
       %{
         tokens_in: tokens_in,
         tokens_out: tokens_out,
         cost: calculate_cost(tokens_in, tokens_out)
       }}
    )
  end

  defp calculate_cost(tokens_in, tokens_out) do
    # Claude 3.5 Sonnet pricing (example)
    input_cost = tokens_in * 0.000003
    output_cost = tokens_out * 0.000015
    input_cost + output_cost
  end
end
