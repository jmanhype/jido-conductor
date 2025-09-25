import { useEffect } from "react";
import { Link } from "react-router-dom";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { useAgentStore } from "@/lib/store";
import { PlayCircle, Square, Eye } from "lucide-react";

export default function Runs() {
  const { runs, fetchRuns, stopRun } = useAgentStore();

  useEffect(() => {
    fetchRuns();
    const interval = setInterval(fetchRuns, 3000);
    return () => clearInterval(interval);
  }, [fetchRuns]);

  const getStatusColor = (status: string) => {
    switch (status) {
      case "running":
        return "bg-green-500";
      case "stopped":
        return "bg-gray-500";
      case "failed":
        return "bg-red-500";
      case "completed":
        return "bg-blue-500";
      default:
        return "bg-gray-400";
    }
  };

  const handleStop = async (runId: string) => {
    try {
      await stopRun(runId);
    } catch (error) {
      console.error("Failed to stop run:", error);
    }
  };

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold tracking-tight">Runs</h1>
        <p className="text-muted-foreground">Monitor and manage active agent runs</p>
      </div>

      <div className="space-y-4">
        {runs.map((run) => (
          <Card key={run.id}>
            <CardHeader className="pb-3">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <div className={`w-2 h-2 rounded-full ${getStatusColor(run.status)}`} />
                  <CardTitle className="text-lg">
                    {run.templateName || `Run ${run.id.slice(0, 8)}`}
                  </CardTitle>
                  <Badge variant="outline">{run.status}</Badge>
                </div>
                <div className="flex gap-2">
                  {run.status === "running" && (
                    <Button size="sm" variant="outline" onClick={() => handleStop(run.id)}>
                      <Square className="h-4 w-4 mr-1" />
                      Stop
                    </Button>
                  )}
                  <Link to={`/runs/${run.id}`}>
                    <Button size="sm" variant="outline">
                      <Eye className="h-4 w-4 mr-1" />
                      View
                    </Button>
                  </Link>
                </div>
              </div>
            </CardHeader>
            <CardContent>
              <div className="grid grid-cols-2 gap-4 text-sm">
                <div>
                  <span className="text-muted-foreground">Started:</span>
                  <span className="ml-2">{new Date(run.startedAt).toLocaleString()}</span>
                </div>
                {run.budget && (
                  <div>
                    <span className="text-muted-foreground">Budget:</span>
                    <span className="ml-2">
                      ${run.budget.maxUsd || "∞"} / {run.budget.maxTokens || "∞"} tokens
                    </span>
                  </div>
                )}
              </div>
            </CardContent>
          </Card>
        ))}

        {runs.length === 0 && (
          <Card>
            <CardContent className="text-center py-8">
              <PlayCircle className="h-12 w-12 text-muted-foreground mx-auto mb-4" />
              <p className="text-muted-foreground">
                No active runs. Start a new run from the Templates page.
              </p>
              <Link to="/templates">
                <Button className="mt-4">Browse Templates</Button>
              </Link>
            </CardContent>
          </Card>
        )}
      </div>
    </div>
  );
}
