defmodule AgentService.Actions.FetchUrl do
  @moduledoc """
  JIDO Action for fetching and processing web URLs
  """
  use Jido.Action,
    name: "fetch_url",
    description: "Fetch content from a URL",
    schema: [
      url: [type: :string, required: true, format: :url],
      timeout: [type: :integer, default: 30_000],
      extract_text: [type: :boolean, default: true]
    ]

  require Logger

  @impl true
  def run(params, _context) do
    case fetch_content(params.url, params.timeout) do
      {:ok, content} ->
        if params.extract_text do
          {:ok, %{
            url: params.url,
            content: extract_text_content(content),
            raw_html: content,
            fetched_at: DateTime.utc_now()
          }}
        else
          {:ok, %{
            url: params.url,
            content: content,
            fetched_at: DateTime.utc_now()
          }}
        end
      
      {:error, reason} ->
        {:error, %{
          url: params.url,
          reason: reason,
          failed_at: DateTime.utc_now()
        }}
    end
  end

  defp fetch_content(url, timeout) do
    headers = [
      {"User-Agent", "JIDO-Conductor/1.0"},
      {"Accept", "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"}
    ]
    
    options = [
      timeout: timeout,
      recv_timeout: timeout
    ]
    
    case :httpc.request(:get, {String.to_charlist(url), headers}, options, []) do
      {:ok, {{_, 200, _}, _headers, body}} ->
        {:ok, List.to_string(body)}
      
      {:ok, {{_, status_code, _}, _, _}} ->
        {:error, "HTTP #{status_code}"}
      
      {:error, reason} ->
        {:error, inspect(reason)}
    end
  end

  defp extract_text_content(html) do
    # Simple text extraction - in production, use a proper HTML parser
    html
    |> String.replace(~r/<script[^>]*>.*?<\/script>/s, "")
    |> String.replace(~r/<style[^>]*>.*?<\/style>/s, "")
    |> String.replace(~r/<[^>]+>/, " ")
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
  end
end