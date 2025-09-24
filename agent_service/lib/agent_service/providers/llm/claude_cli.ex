defmodule AgentService.Providers.LLM.ClaudeCLI do
  @moduledoc """
  Claude Code CLI provider - piggybacks on user's authenticated CLI
  """
  
  require Logger
  
  @timeout 60_000

  def chat(prompt, opts \\ []) do
    args = build_args(prompt, opts)
    
    case System.cmd("claude", args, stderr_to_stdout: true, timeout: @timeout) do
      {output, 0} ->
        parse_output(output)
      
      {output, exit_code} ->
        Logger.error("Claude CLI failed with exit code #{exit_code}: #{output}")
        {:error, "Claude CLI command failed: #{output}"}
      
      exception ->
        Logger.error("Claude CLI exception: #{inspect(exception)}")
        {:error, "Failed to execute Claude CLI"}
    end
  end

  def stream_chat(prompt, opts \\ []) do
    args = build_args(prompt, opts, streaming: true)
    port = Port.open({:spawn_executable, System.find_executable("claude")},
      [:binary, :exit_status, args: args])
    
    {:ok, port}
  end

  defp build_args(prompt, opts, flags \\ []) do
    base_args = if Keyword.get(flags, :streaming, false) do
      ["--output-format", "stream-json", "chat", "--input", prompt]
    else
      ["--output-format", "json", "chat", "--input", prompt]
    end
    
    base_args ++ model_flag(opts)
  end

  defp model_flag(opts) do
    case Keyword.get(opts, :model) do
      nil -> []
      model -> ["--model", to_string(model)]
    end
  end

  defp parse_output(output) do
    case Jason.decode(output) do
      {:ok, %{"text" => text} = json} ->
        {:ok, %{
          text: text,
          tokens_in: Map.get(json, "tokens_in"),
          tokens_out: Map.get(json, "tokens_out"),
          raw: json
        }}
      
      {:ok, json} ->
        # Handle other response formats
        {:ok, %{raw: json}}
      
      {:error, _} ->
        # Try to extract text from non-JSON output
        {:ok, %{text: output}}
    end
  end
end