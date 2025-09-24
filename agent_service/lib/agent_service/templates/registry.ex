defmodule AgentService.Templates.Registry do
  use GenServer
  require Logger
  alias AgentService.Templates.Template

  @templates_dir Path.expand("~/.jido/templates")

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_opts) do
    ensure_templates_dir()
    templates = load_templates()
    {:ok, %{templates: templates}}
  end

  def list_templates do
    GenServer.call(__MODULE__, :list_templates)
  end

  def get_template(id) do
    GenServer.call(__MODULE__, {:get_template, id})
  end

  def install_template(upload) do
    GenServer.call(__MODULE__, {:install_template, upload})
  end

  # Callbacks

  def handle_call(:list_templates, _from, state) do
    {:reply, Map.values(state.templates), state}
  end

  def handle_call({:get_template, id}, _from, state) do
    {:reply, Map.get(state.templates, id), state}
  end

  def handle_call({:install_template, upload}, _from, state) do
    case do_install_template(upload) do
      {:ok, template} ->
        new_templates = Map.put(state.templates, template.id, template)
        {:reply, {:ok, template}, %{state | templates: new_templates}}
      
      {:error, reason} = error ->
        {:reply, error, state}
    end
  end

  # Private

  defp ensure_templates_dir do
    File.mkdir_p!(@templates_dir)
  end

  defp load_templates do
    case File.ls(@templates_dir) do
      {:ok, dirs} ->
        dirs
        |> Enum.filter(&File.dir?(Path.join(@templates_dir, &1)))
        |> Enum.map(&load_template/1)
        |> Enum.filter(&(&1 != nil))
        |> Enum.map(&{&1.id, &1})
        |> Map.new()
      
      {:error, _} ->
        %{}
    end
  end

  defp load_template(dir_name) do
    template_path = Path.join(@templates_dir, dir_name)
    manifest_path = Path.join(template_path, "jido-template.yaml")
    
    if File.exists?(manifest_path) do
      case YamlElixir.read_from_file(manifest_path) do
        {:ok, manifest} ->
          Template.from_manifest(manifest, dir_name)
        
        {:error, reason} ->
          Logger.error("Failed to load template #{dir_name}: #{inspect(reason)}")
          nil
      end
    else
      nil
    end
  end

  defp do_install_template(upload) do
    temp_path = upload.path
    template_id = generate_template_id()
    target_dir = Path.join(@templates_dir, template_id)
    
    try do
      # Extract zip file
      File.mkdir_p!(target_dir)
      
      case System.cmd("unzip", ["-q", temp_path, "-d", target_dir]) do
        {_, 0} ->
          # Load the template manifest
          manifest_path = Path.join(target_dir, "jido-template.yaml")
          
          if File.exists?(manifest_path) do
            case YamlElixir.read_from_file(manifest_path) do
              {:ok, manifest} ->
                template = Template.from_manifest(manifest, template_id)
                {:ok, template}
              
              {:error, reason} ->
                File.rm_rf!(target_dir)
                {:error, "Invalid template manifest: #{inspect(reason)}"}
            end
          else
            File.rm_rf!(target_dir)
            {:error, "Template manifest not found"}
          end
        
        {error, _} ->
          File.rm_rf!(target_dir)
          {:error, "Failed to extract template: #{error}"}
      end
    rescue
      e ->
        File.rm_rf!(target_dir)
        {:error, "Installation failed: #{inspect(e)}"}
    end
  end

  defp generate_template_id do
    UUID.uuid4(:hex)
  end
end