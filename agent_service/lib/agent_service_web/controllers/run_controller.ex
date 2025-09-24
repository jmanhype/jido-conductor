defmodule AgentServiceWeb.RunController do
  use AgentServiceWeb, :controller
  alias AgentService.Runs

  def index(conn, _params) do
    runs = Runs.list_runs()
    json(conn, runs)
  end

  def show(conn, %{"id" => id}) do
    case Runs.get_run(id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Run not found"})

      run ->
        json(conn, run)
    end
  end

  def create(conn, params) do
    case Runs.create_run(params) do
      {:ok, run} ->
        conn
        |> put_status(:created)
        |> json(run)

      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: reason})
    end
  end

  def stop(conn, %{"id" => id}) do
    case Runs.stop_run(id) do
      :ok ->
        json(conn, %{success: true})

      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: reason})
    end
  end

  def logs(conn, %{"id" => id}) do
    conn
    |> put_resp_header("content-type", "text/event-stream")
    |> put_resp_header("cache-control", "no-cache")
    |> put_resp_header("connection", "keep-alive")
    |> send_chunked(200)
    |> stream_logs(id)
  end

  defp stream_logs(conn, run_id) do
    # Subscribe to run logs
    Phoenix.PubSub.subscribe(AgentService.PubSub, "runs:#{run_id}")

    # Send initial connection message
    chunk(conn, "event: connected\ndata: {\"connected\": true}\n\n")

    # Stream logs
    receive_logs(conn, run_id)
  end

  defp receive_logs(conn, run_id) do
    receive do
      {:log_entry, entry} ->
        data = Jason.encode!(entry)

        case chunk(conn, "data: #{data}\n\n") do
          {:ok, conn} ->
            receive_logs(conn, run_id)

          {:error, _reason} ->
            Phoenix.PubSub.unsubscribe(AgentService.PubSub, "runs:#{run_id}")
            conn
        end

      {:run_completed, _} ->
        chunk(conn, "event: completed\ndata: {\"completed\": true}\n\n")
        Phoenix.PubSub.unsubscribe(AgentService.PubSub, "runs:#{run_id}")
        conn
    after
      30_000 ->
        # Send heartbeat every 30 seconds
        case chunk(conn, ":heartbeat\n\n") do
          {:ok, conn} ->
            receive_logs(conn, run_id)

          {:error, _reason} ->
            Phoenix.PubSub.unsubscribe(AgentService.PubSub, "runs:#{run_id}")
            conn
        end
    end
  end
end
