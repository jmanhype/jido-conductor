defmodule AgentService.Actions.SaveArtifact do
  @moduledoc """
  JIDO Action for saving artifacts to the filesystem
  """
  use Jido.Action,
    name: "save_artifact",
    description: "Save generated artifacts to the run's artifact directory",
    schema: [
      run_id: [type: :string, required: true],
      filename: [type: :string, required: true],
      content: [type: :string, required: true],
      content_type: [type: :string, default: "text/plain"],
      metadata: [type: :map, default: %{}]
    ]

  require Logger

  @impl true
  def run(params, _context) do
    artifact_dir = get_artifact_dir(params.run_id)

    # Ensure directory exists
    File.mkdir_p!(artifact_dir)

    file_path = Path.join(artifact_dir, params.filename)

    case File.write(file_path, params.content) do
      :ok ->
        artifact = %{
          id: UUID.uuid4(:hex),
          filename: params.filename,
          path: file_path,
          size: byte_size(params.content),
          content_type: params.content_type,
          metadata: params.metadata,
          created_at: DateTime.utc_now()
        }

        # Save artifact metadata
        save_artifact_metadata(params.run_id, artifact)

        {:ok, %{artifact: artifact, message: "Artifact saved successfully"}}

      {:error, reason} ->
        {:error,
         %{
           reason: "Failed to save artifact",
           details: inspect(reason),
           filename: params.filename
         }}
    end
  end

  defp get_artifact_dir(run_id) do
    Path.join([
      Path.expand("~/.jido"),
      "runs",
      run_id,
      "artifacts"
    ])
  end

  defp save_artifact_metadata(run_id, artifact) do
    metadata_file =
      Path.join([
        Path.expand("~/.jido"),
        "runs",
        run_id,
        "artifacts.json"
      ])

    # Load existing artifacts
    artifacts =
      case File.read(metadata_file) do
        {:ok, content} ->
          case Jason.decode(content) do
            {:ok, data} -> data
            _ -> []
          end

        _ ->
          []
      end

    # Append new artifact
    updated = [artifact | artifacts]

    # Save updated list
    File.write!(metadata_file, Jason.encode!(updated, pretty: true))
  end
end
