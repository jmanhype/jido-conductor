defmodule AgentService.Templates.TemplateTest do
  use ExUnit.Case, async: true

  alias AgentService.Templates.Template

  describe "from_manifest/2" do
    test "creates template from complete manifest" do
      manifest = %{
        "metadata" => %{
          "name" => "test-template",
          "display_name" => "Test Template",
          "description" => "A test template",
          "version" => "1.2.0",
          "author" => "Test Author",
          "tags" => ["test", "example"]
        },
        "config_schema" => %{
          "type" => "object",
          "properties" => %{}
        }
      }

      template = Template.from_manifest(manifest, "test-id")

      assert template.id == "test-id"
      assert template.name == "test-template"
      assert template.display_name == "Test Template"
      assert template.description == "A test template"
      assert template.version == "1.2.0"
      assert template.author == "Test Author"
      assert template.tags == ["test", "example"]
      assert template.config_schema == manifest["config_schema"]
      assert template.manifest == manifest
    end

    test "uses defaults for missing metadata fields" do
      manifest = %{
        "metadata" => %{
          "name" => "minimal-template"
        }
      }

      template = Template.from_manifest(manifest, "minimal-id")

      assert template.id == "minimal-id"
      assert template.name == "minimal-template"
      assert template.display_name == "minimal-template"
      assert template.description == ""
      assert template.version == "0.1.0"
      assert template.author == "unknown"
      assert template.tags == []
    end

    test "handles missing metadata section" do
      manifest = %{}

      template = Template.from_manifest(manifest, "empty-id")

      assert template.id == "empty-id"
      assert template.name == nil
      assert template.display_name == nil
      assert template.description == ""
      assert template.version == "0.1.0"
    end
  end
end
