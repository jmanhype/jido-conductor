defmodule AgentServiceWeb.Auth do
  import Plug.Conn
  require Logger

  def init(opts), do: opts

  def call(conn, _opts) do
    # For loopback-only service, we just verify the request is local
    # In production, we'd validate the X-Local-Token header
    case get_req_header(conn, "x-local-token") do
      [token] when is_binary(token) ->
        # TODO: Validate token against session store
        conn

      _ ->
        # For development, allow requests without token
        if Mix.env() == :dev do
          conn
        else
          conn
          |> put_status(:unauthorized)
          |> Phoenix.Controller.json(%{error: "Missing or invalid session token"})
          |> halt()
        end
    end
  end
end
