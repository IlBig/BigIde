import { z } from "zod";
import { TmuxClient } from "../core/tmux-client.js";
import { logger } from "../core/logger.js";
import { stripAnsi } from "../utils/ansi.js";

const client = new TmuxClient();

export const watchPaneTool = {
  name: "watch_pane",
  description: "Attende un cambiamento nell'output di un pannello (polling) o un timeout.",
  parameters: z.object({
    target: z.string().describe("Target pane da monitorare"),
    timeoutMs: z.number().default(10000).describe("Timeout massimo attesa (ms)"),
    pollIntervalMs: z.number().default(500).describe("Intervallo polling (ms)"),
    captureLines: z.number().default(50).describe("Righe da confrontare"),
  }),
  handler: async ({ target, timeoutMs, pollIntervalMs, captureLines }: any) => {
    try {
      logger.info(`Watching pane ${target} (timeout=${timeoutMs})`);
      
      const initial = stripAnsi(client.capturePane(target, captureLines));
      const start = Date.now();

      while (Date.now() - start < timeoutMs) {
        await new Promise(r => setTimeout(r, pollIntervalMs));
        const current = stripAnsi(client.capturePane(target, captureLines));
        
        if (current !== initial) {
          // Calcola diff semplice (solo le righe nuove)
          // Questo è un approccio naif ma efficace per log append-only
          const newContent = current.replace(initial, "").trim();
          return {
            content: [{ type: "text" as const, text: newContent || current }]
          };
        }
      }

      return {
        content: [{ type: "text" as const, text: "No changes detected within timeout." }]
      };
    } catch (error: any) {
      logger.error(`Watch pane failed`, error);
      return {
        isError: true,
        content: [{ type: "text" as const, text: `ERROR: ${error.message}` }]
      };
    }
  }
};
