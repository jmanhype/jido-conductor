import { useEffect, useState } from "react";
import { useParams, useNavigate } from "react-router-dom";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { toast } from "@/hooks/use-toast";
import { useAgentStore } from "@/lib/store";
import { ArrowLeft, Play } from "lucide-react";

export default function Configure() {
  const { templateId } = useParams();
  const navigate = useNavigate();
  const { templates, startRun } = useAgentStore();
  const [template, setTemplate] = useState<any>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);

  const form = useForm({
    resolver: template?.config_schema ? zodResolver(z.object(template.config_schema)) : undefined,
  });

  useEffect(() => {
    const tmpl = templates.find((t) => t.id === templateId);
    if (tmpl) {
      setTemplate(tmpl);
    }
  }, [templateId, templates]);

  const onSubmit = async (data: any) => {
    setIsSubmitting(true);
    try {
      const run = await startRun(templateId!, data);
      toast({
        title: "Run started",
        description: `Successfully started run ${run.id}`,
      });
      navigate(`/runs/${run.id}`);
    } catch (error) {
      toast({
        title: "Failed to start run",
        description: error instanceof Error ? error.message : "Unknown error",
        variant: "destructive",
      });
    } finally {
      setIsSubmitting(false);
    }
  };

  if (!template) {
    return (
      <div className="space-y-6">
        <Button variant="ghost" onClick={() => navigate("/templates")}>
          <ArrowLeft className="mr-2 h-4 w-4" />
          Back to Templates
        </Button>
        <Card>
          <CardContent className="py-8 text-center">
            <p className="text-muted-foreground">Template not found</p>
          </CardContent>
        </Card>
      </div>
    );
  }

  return (
    <div className="space-y-6 max-w-2xl">
      <div>
        <Button variant="ghost" onClick={() => navigate("/templates")}>
          <ArrowLeft className="mr-2 h-4 w-4" />
          Back
        </Button>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>{template.displayName}</CardTitle>
          <CardDescription>{template.description}</CardDescription>
        </CardHeader>
        <CardContent>
          <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4">
            {/* Dynamic form fields based on config_schema */}
            {template.config_schema?.properties &&
              Object.entries(template.config_schema.properties).map(
                ([key, schema]: [string, any]) => (
                  <div key={key} className="space-y-2">
                    <Label htmlFor={key}>
                      {schema.title || key}
                      {template.config_schema.required?.includes(key) && (
                        <span className="text-destructive ml-1">*</span>
                      )}
                    </Label>
                    {schema.type === "array" ? (
                      <Textarea
                        id={key}
                        {...form.register(key)}
                        placeholder={schema.description || `Enter ${key} (one per line)`}
                        rows={3}
                      />
                    ) : schema.type === "integer" || schema.type === "number" ? (
                      <Input
                        id={key}
                        type="number"
                        {...form.register(key, { valueAsNumber: true })}
                        placeholder={schema.description}
                        min={schema.minimum}
                        max={schema.maximum}
                      />
                    ) : (
                      <Input id={key} {...form.register(key)} placeholder={schema.description} />
                    )}
                    {form.formState.errors[key] && (
                      <p className="text-sm text-destructive">
                        {String(form.formState.errors[key]?.message || "")}
                      </p>
                    )}
                  </div>
                )
              )}

            <div className="pt-4">
              <Button type="submit" disabled={isSubmitting} className="w-full">
                <Play className="mr-2 h-4 w-4" />
                {isSubmitting ? "Starting..." : "Start Run"}
              </Button>
            </div>
          </form>
        </CardContent>
      </Card>
    </div>
  );
}
