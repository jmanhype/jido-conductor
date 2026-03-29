defmodule AgentService.Templates.Template do
  @derive Jason.Encoder
  defstruct [:id, :name, :display_name, :description, :version, :author, :tags, :config_schema, :manifest]

  @type t :: %__MODULE__{
          id: String.t(),
          name: String.t() | nil,
          display_name: String.t() | nil,
          description: String.t(),
          version: String.t(),
          author: String.t(),
          tags: list(String.t()),
          config_schema: map(),
          manifest: map()
        }

  @spec from_manifest(map(), String.t()) :: t()
  def from_manifest(manifest, id) do
    metadata = Map.get(manifest, "metadata", %{})

    %__MODULE__{
      id: id,
      name: Map.get(metadata, "name"),
      display_name: Map.get(metadata, "display_name", Map.get(metadata, "name")),
      description: Map.get(metadata, "description", ""),
      version: Map.get(metadata, "version", "0.1.0"),
      author: Map.get(metadata, "author", "unknown"),
      tags: Map.get(metadata, "tags", []),
      config_schema: Map.get(manifest, "config_schema", %{}),
      manifest: manifest
    }
  end
end
