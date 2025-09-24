import { create } from 'zustand';
import { api } from './api';

interface Template {
  id: string;
  name: string;
  displayName: string;
  description: string;
  version: string;
  author: string;
  tags: string[];
}

interface Run {
  id: string;
  templateId: string;
  templateName: string;
  status: 'running' | 'stopped' | 'failed' | 'completed';
  startedAt: string;
  config: any;
  budget?: {
    maxUsd?: number;
    maxTokens?: number;
  };
}

interface Stats {
  activeRuns: number;
  totalTemplates: number;
  todayCost: number;
  recentActivity: Array<{ name: string; time: string }>;
}

interface AgentStore {
  templates: Template[];
  runs: Run[];
  stats: Stats | null;
  sessionToken: string | null;
  
  fetchTemplates: () => Promise<void>;
  fetchRuns: () => Promise<void>;
  fetchStats: () => Promise<void>;
  setSessionToken: (token: string) => void;
  
  startRun: (templateId: string, config: any) => Promise<Run>;
  stopRun: (runId: string) => Promise<void>;
  
  installTemplate: (file: File) => Promise<void>;
}

export const useAgentStore = create<AgentStore>((set, get) => ({
  templates: [],
  runs: [],
  stats: null,
  sessionToken: null,

  fetchTemplates: async () => {
    try {
      const templates = await api.getTemplates();
      set({ templates });
    } catch (error) {
      console.error('Failed to fetch templates:', error);
    }
  },

  fetchRuns: async () => {
    try {
      const runs = await api.getRuns();
      set({ runs });
    } catch (error) {
      console.error('Failed to fetch runs:', error);
    }
  },

  fetchStats: async () => {
    try {
      const stats = await api.getStats();
      set({ stats });
    } catch (error) {
      console.error('Failed to fetch stats:', error);
    }
  },

  setSessionToken: (token: string) => {
    set({ sessionToken: token });
    api.setSessionToken(token);
  },

  startRun: async (templateId: string, config: any) => {
    const run = await api.startRun({ template: templateId, config });
    const runs = [...get().runs, run];
    set({ runs });
    return run;
  },

  stopRun: async (runId: string) => {
    await api.stopRun(runId);
    const runs = get().runs.map(r => 
      r.id === runId ? { ...r, status: 'stopped' as const } : r
    );
    set({ runs });
  },

  installTemplate: async (file: File) => {
    await api.installTemplate(file);
    await get().fetchTemplates();
  },
}));