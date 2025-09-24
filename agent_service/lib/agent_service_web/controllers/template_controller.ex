defmodule AgentServiceWeb.TemplateController do
  use AgentServiceWeb, :controller
  alias AgentService.Templates

  def index(conn, _params) do
    templates = Templates.list_templates()
    json(conn, templates)
  end

  def show(conn, %{"id" => id}) do
    case Templates.get_template(id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Template not found"})

      template ->
        json(conn, template)
    end
  end

  def install(conn, %{"template" => upload}) do
    case Templates.install_template(upload) do
      {:ok, template} ->
        json(conn, template)

      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: reason})
    end
  end
end
