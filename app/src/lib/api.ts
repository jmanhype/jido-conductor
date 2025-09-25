import { invoke } from "@tauri-apps/api/core";

const API_BASE = "http://127.0.0.1:8745/v1";

class API {
  private sessionToken: string | null = null;

  constructor() {
    this.initSessionToken();
  }

  private async initSessionToken() {
    try {
      const token = await invoke<string>("get_session_token");
      this.sessionToken = token;
    } catch (error) {
      console.error("Failed to get session token:", error);
    }
  }

  setSessionToken(token: string) {
    this.sessionToken = token;
  }

  private async request(path: string, options: RequestInit = {}) {
    const headers: any = {
      "Content-Type": "application/json",
      ...options.headers,
    };

    if (this.sessionToken) {
      headers["X-Local-Token"] = this.sessionToken;
    }

    const response = await fetch(`${API_BASE}${path}`, {
      ...options,
      headers,
    });

    if (!response.ok) {
      throw new Error(`API error: ${response.statusText}`);
    }

    return response.json();
  }

  async getTemplates() {
    return this.request("/templates");
  }

  async getTemplate(id: string) {
    return this.request(`/templates/${id}`);
  }

  async installTemplate(file: File) {
    const formData = new FormData();
    formData.append("template", file);

    const response = await fetch(`${API_BASE}/templates/install`, {
      method: "POST",
      headers: {
        "X-Local-Token": this.sessionToken || "",
      },
      body: formData,
    });

    if (!response.ok) {
      throw new Error(`Failed to install template: ${response.statusText}`);
    }

    return response.json();
  }

  async getRuns() {
    return this.request("/runs");
  }

  async getRun(id: string) {
    return this.request(`/runs/${id}`);
  }

  async startRun(body: {
    template: string;
    config: any;
    secretsRef?: string;
    schedule?: string;
    budget?: { maxUsd?: number; maxTokens?: number };
  }) {
    return this.request("/runs", {
      method: "POST",
      body: JSON.stringify(body),
    });
  }

  async stopRun(id: string) {
    return this.request(`/runs/${id}/stop`, {
      method: "POST",
    });
  }

  getRunLogs(id: string): EventSource {
    const url = `${API_BASE}/runs/${id}/logs`;
    return new EventSource(url);
  }

  async getStats() {
    return this.request("/stats");
  }

  async getHealth() {
    return this.request("/healthz");
  }

  async storeSecret(key: string, value: string) {
    return invoke("store_secret", { key, value });
  }

  async getSecret(key: string): Promise<string> {
    return invoke("get_secret", { key });
  }

  async deleteSecret(key: string) {
    return invoke("delete_secret", { key });
  }
}

export const api = new API();
