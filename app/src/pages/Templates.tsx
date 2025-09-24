import { useEffect, useRef } from "react";
import { Link } from "react-router-dom";
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Upload, Play, Package2 } from "lucide-react";
import { useAgentStore } from "@/lib/store";
import { toast } from "@/hooks/use-toast";

export default function Templates() {
  const { templates, fetchTemplates, installTemplate } = useAgentStore();
  const fileInputRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    fetchTemplates();
  }, [fetchTemplates]);

  const handleFileUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    if (!file.name.endsWith('.jido.zip')) {
      toast({
        title: "Invalid file",
        description: "Please select a .jido.zip template file",
        variant: "destructive",
      });
      return;
    }

    try {
      await installTemplate(file);
      toast({
        title: "Template installed",
        description: "The template has been successfully installed",
      });
    } catch (error) {
      toast({
        title: "Installation failed",
        description: error instanceof Error ? error.message : "Failed to install template",
        variant: "destructive",
      });
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Templates</h1>
          <p className="text-muted-foreground">
            Browse and install agent templates
          </p>
        </div>
        <Button 
          onClick={() => fileInputRef.current?.click()}
          variant="outline"
        >
          <Upload className="mr-2 h-4 w-4" />
          Install Template
        </Button>
        <input
          ref={fileInputRef}
          type="file"
          accept=".jido.zip,.zip"
          onChange={handleFileUpload}
          className="hidden"
        />
      </div>

      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
        {templates.map((template) => (
          <Card key={template.id}>
            <CardHeader>
              <div className="flex items-center justify-between">
                <Package2 className="h-8 w-8 text-muted-foreground" />
                <Badge variant="secondary">v{template.version}</Badge>
              </div>
              <CardTitle>{template.displayName}</CardTitle>
              <CardDescription>{template.description}</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="flex flex-wrap gap-1">
                {template.tags.map((tag) => (
                  <Badge key={tag} variant="outline" className="text-xs">
                    {tag}
                  </Badge>
                ))}
              </div>
              <p className="text-sm text-muted-foreground mt-2">
                By {template.author}
              </p>
            </CardContent>
            <CardFooter>
              <Link to={`/configure/${template.id}`} className="w-full">
                <Button className="w-full">
                  <Play className="mr-2 h-4 w-4" />
                  Configure & Run
                </Button>
              </Link>
            </CardFooter>
          </Card>
        ))}

        {templates.length === 0 && (
          <Card className="col-span-full">
            <CardContent className="text-center py-8">
              <Package2 className="h-12 w-12 text-muted-foreground mx-auto mb-4" />
              <p className="text-muted-foreground">
                No templates installed. Upload a .jido.zip file to get started.
              </p>
            </CardContent>
          </Card>
        )}
      </div>
    </div>
  );
}