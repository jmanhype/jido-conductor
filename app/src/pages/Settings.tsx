import { useState } from "react";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Switch } from "@/components/ui/switch";
import { toast } from "@/hooks/use-toast";
import { api } from "@/lib/api";
import { Key, Globe, Shield, Database } from "lucide-react";

export default function Settings() {
  const [anthropicKey, setAnthropicKey] = useState("");
  const [isOnline, setIsOnline] = useState(false);
  const [isSaving, setIsSaving] = useState(false);

  const saveAnthropicKey = async () => {
    if (!anthropicKey) {
      toast({
        title: "API key required",
        description: "Please enter your Anthropic API key",
        variant: "destructive",
      });
      return;
    }

    setIsSaving(true);
    try {
      await api.storeSecret("anthropic/default", anthropicKey);
      toast({
        title: "API key saved",
        description: "Your Anthropic API key has been securely stored",
      });
      setAnthropicKey("");
    } catch (error) {
      toast({
        title: "Failed to save API key",
        description: error instanceof Error ? error.message : "Unknown error",
        variant: "destructive",
      });
    } finally {
      setIsSaving(false);
    }
  };

  return (
    <div className="space-y-6 max-w-4xl">
      <div>
        <h1 className="text-3xl font-bold tracking-tight">Settings</h1>
        <p className="text-muted-foreground">
          Configure your JIDO Conductor preferences
        </p>
      </div>

      <div className="grid gap-6">
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Key className="h-5 w-5" />
              API Keys
            </CardTitle>
            <CardDescription>
              Manage your LLM provider API keys
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="anthropic-key">Anthropic API Key</Label>
              <div className="flex gap-2">
                <Input
                  id="anthropic-key"
                  type="password"
                  value={anthropicKey}
                  onChange={(e) => setAnthropicKey(e.target.value)}
                  placeholder="sk-ant-..."
                />
                <Button onClick={saveAnthropicKey} disabled={isSaving}>
                  {isSaving ? "Saving..." : "Save"}
                </Button>
              </div>
              <p className="text-sm text-muted-foreground">
                Your API key is stored securely in the OS keychain
              </p>
            </div>

            <div className="pt-4 border-t">
              <div className="space-y-2">
                <Label>Claude Code CLI</Label>
                <p className="text-sm text-muted-foreground">
                  The CLI integration is automatically configured if Claude Code is installed
                </p>
                <Button variant="outline" size="sm" disabled>
                  Check CLI Status
                </Button>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Globe className="h-5 w-5" />
              Network
            </CardTitle>
            <CardDescription>
              Control network access and online features
            </CardDescription>
          </CardHeader>
          <CardContent>
            <div className="flex items-center justify-between">
              <div className="space-y-0.5">
                <Label htmlFor="online-mode">Online Mode</Label>
                <p className="text-sm text-muted-foreground">
                  Allow network access for templates and remote features
                </p>
              </div>
              <Switch
                id="online-mode"
                checked={isOnline}
                onCheckedChange={setIsOnline}
              />
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Shield className="h-5 w-5" />
              Security
            </CardTitle>
            <CardDescription>
              Security and privacy settings
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="flex items-center justify-between">
              <div className="space-y-0.5">
                <Label>Template Sandboxing</Label>
                <p className="text-sm text-muted-foreground">
                  Restrict template network access by default
                </p>
              </div>
              <Switch defaultChecked={true} disabled />
            </div>
            <div className="flex items-center justify-between">
              <div className="space-y-0.5">
                <Label>Telemetry</Label>
                <p className="text-sm text-muted-foreground">
                  Share anonymous usage data to improve JIDO
                </p>
              </div>
              <Switch defaultChecked={false} />
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Database className="h-5 w-5" />
              Data
            </CardTitle>
            <CardDescription>
              Manage your local data and storage
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="space-y-2">
              <Label>Storage Location</Label>
              <Input value="~/.jido" disabled />
              <p className="text-sm text-muted-foreground">
                Templates, runs, and artifacts are stored here
              </p>
            </div>
            <div className="flex gap-2">
              <Button variant="outline">Export Data</Button>
              <Button variant="outline">Clear Cache</Button>
              <Button variant="destructive" disabled>Reset All Data</Button>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}