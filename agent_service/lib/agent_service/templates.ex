defmodule AgentService.Templates do
  @moduledoc """
  Context module for templates
  """

  defdelegate list_templates(), to: AgentService.Templates.Registry
  defdelegate get_template(id), to: AgentService.Templates.Registry
  defdelegate install_template(upload), to: AgentService.Templates.Registry
end
