import { useEffect, useState, useRef } from "react";
import { useParams, useNavigate } from "react-router-dom";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { ScrollArea } from "@/components/ui/scroll-area";
import { ArrowLeft, Square, Download } from "lucide-react";
import { api } from "@/lib/api";
import { useAgentStore } from "@/lib/store";

interface LogEntry {
  timestamp: string;
  event: string;
  level: "info" | "warning" | "error";
  message: string;
  tokens?: number;
  cost?: number;
}

export default function RunDetails() {
  const { runId } = useParams();
  const navigate = useNavigate();
  const { runs, stopRun } = useAgentStore();
  const [logs, setLogs] = useState<LogEntry[]>([]);
  const [isConnected, setIsConnected] = useState(false);
  const eventSourceRef = useRef<EventSource | null>(null);
  const scrollAreaRef = useRef<HTMLDivElement>(null);

  const run = runs.find(r => r.id === runId);

  useEffect(() => {
    if (!runId) return;

    // Connect to SSE log stream
    const eventSource = api.getRunLogs(runId);
    eventSourceRef.current = eventSource;

    eventSource.onopen = () => {
      setIsConnected(true);
    };

    eventSource.onmessage = (event) => {
      try {
        const data = JSON.parse(event.data);
        if (data.connected) {
          console.log("Connected to log stream");
        } else {
          setLogs(prev => [...prev, data as LogEntry]);
          // Auto-scroll to bottom
          if (scrollAreaRef.current) {
            scrollAreaRef.current.scrollTop = scrollAreaRef.current.scrollHeight;
          }
        }
      } catch (error) {
        console.error("Failed to parse log entry:", error);
      }
    };

    eventSource.addEventListener("completed", () => {
      setIsConnected(false);
      eventSource.close();
    });

    eventSource.onerror = () => {
      setIsConnected(false);
      console.error("Log stream connection error");
    };

    return () => {
      eventSource.close();
    };
  }, [runId]);

  const handleStop = async () => {
    if (runId) {
      await stopRun(runId);
      if (eventSourceRef.current) {
        eventSourceRef.current.close();
        setIsConnected(false);
      }
    }
  };

  const downloadLogs = () => {
    const content = logs.map(log => 
      `[${log.timestamp}] ${log.level.toUpperCase()}: ${log.message}`
    ).join("\n");
    
    const blob = new Blob([content], { type: "text/plain" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = `run-${runId}-logs.txt`;
    a.click();
    URL.revokeObjectURL(url);
  };

  const getLogColor = (level: string) => {
    switch (level) {
      case "error": return "text-red-600";
      case "warning": return "text-yellow-600";
      default: return "text-foreground";
    }
  };

  if (!run) {
    return (
      <div className="space-y-6">
        <Button variant="ghost" onClick={() => navigate("/runs")}>
          <ArrowLeft className="mr-2 h-4 w-4" />
          Back to Runs
        </Button>
        <Card>
          <CardContent className="py-8 text-center">
            <p className="text-muted-foreground">Run not found</p>
          </CardContent>
        </Card>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-4">
          <Button variant="ghost" onClick={() => navigate("/runs")}>
            <ArrowLeft className="mr-2 h-4 w-4" />
            Back
          </Button>
          <h1 className="text-2xl font-bold">Run Details</h1>
          <Badge variant={run.status === "running" ? "default" : "secondary"}>
            {run.status}
          </Badge>
          {isConnected && (
            <Badge variant="outline" className="bg-green-50">
              Live
            </Badge>
          )}
        </div>
        <div className="flex gap-2">
          {run.status === "running" && (
            <Button variant="outline" onClick={handleStop}>
              <Square className="mr-2 h-4 w-4" />
              Stop Run
            </Button>
          )}
          <Button variant="outline" onClick={downloadLogs}>
            <Download className="mr-2 h-4 w-4" />
            Download Logs
          </Button>
        </div>
      </div>

      <div className="grid gap-4 md:grid-cols-3">
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium">Template</CardTitle>
          </CardHeader>
          <CardContent>
            <p className="text-lg">{run.templateName || run.templateId}</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium">Started</CardTitle>
          </CardHeader>
          <CardContent>
            <p className="text-lg">{new Date(run.startedAt).toLocaleString()}</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium">Total Cost</CardTitle>
          </CardHeader>
          <CardContent>
            <p className="text-lg">
              ${logs.reduce((sum, log) => sum + (log.cost || 0), 0).toFixed(4)}
            </p>
          </CardContent>
        </Card>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Logs</CardTitle>
        </CardHeader>
        <CardContent>
          <ScrollArea className="h-[500px] w-full rounded-md border p-4" ref={scrollAreaRef}>
            <div className="space-y-2">
              {logs.map((log, index) => (
                <div key={index} className="font-mono text-sm">
                  <span className="text-muted-foreground">
                    [{new Date(log.timestamp).toLocaleTimeString()}]
                  </span>
                  <span className={`ml-2 ${getLogColor(log.level)}`}>
                    {log.message}
                  </span>
                  {log.tokens && (
                    <span className="ml-2 text-muted-foreground text-xs">
                      ({log.tokens} tokens)
                    </span>
                  )}
                </div>
              ))}
              {logs.length === 0 && (
                <p className="text-muted-foreground text-center py-4">
                  {isConnected ? "Waiting for logs..." : "No logs available"}
                </p>
              )}
            </div>
          </ScrollArea>
        </CardContent>
      </Card>
    </div>
  );
}