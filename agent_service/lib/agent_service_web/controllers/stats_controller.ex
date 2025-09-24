defmodule AgentServiceWeb.StatsController do
  use AgentServiceWeb, :controller
  alias AgentService.Runs

  def index(conn, _params) do
    runs = Runs.list_runs()
    
    stats = %{
      activeRuns: Enum.count(runs, &(&1.status == "running")),
      totalTemplates: length(AgentService.Templates.list_templates()),
      todayCost: calculate_today_cost(runs),
      recentActivity: format_recent_activity(runs)
    }
    
    json(conn, stats)
  end

  defp calculate_today_cost(runs) do
    today = Date.utc_today()
    
    runs
    |> Enum.filter(fn run ->
      Date.compare(DateTime.to_date(run.started_at), today) == :eq
    end)
    |> Enum.map(fn run -> Map.get(run, :total_cost, 0) end)
    |> Enum.sum()
  end

  defp format_recent_activity(runs) do
    runs
    |> Enum.sort_by(&(&1.started_at), {:desc, DateTime})
    |> Enum.take(5)
    |> Enum.map(fn run ->
      %{
        name: "Run #{String.slice(run.id, 0..7)}",
        time: format_time_ago(run.started_at)
      }
    end)
  end

  defp format_time_ago(datetime) do
    diff = DateTime.diff(DateTime.utc_now(), datetime, :second)
    
    cond do
      diff < 60 -> "#{diff}s ago"
      diff < 3600 -> "#{div(diff, 60)}m ago"
      diff < 86400 -> "#{div(diff, 3600)}h ago"
      true -> "#{div(diff, 86400)}d ago"
    end
  end
end