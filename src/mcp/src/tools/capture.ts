import { z } from "zod";
import { TmuxClient } from "../core/tmux-client.js";
import { stripAnsi } from "../utils/ansi.js";
import { logger } from "../core/logger.js";

const client = new TmuxClient();

export const captureTool = {
  name: "capture_pane",
  description: "Cattura l'output visibile di un pannello tmux. Utile per leggere log, errori o stato.",
  parameters: z.object({
    target: z.string().describe("Target pane (es. '%1', 'log.0', 'claude')"),
    lines: z.number().optional().default(50).describe("Numero di righe da catturare (default: 50)"),
  }),
  handler: async ({ target, lines }: { target: string, lines: number }) => {
    try {
      logger.info(`Capturing pane ${target}, lines=${lines}`);
      const rawOutput = client.capturePane(target, lines);
      const cleanOutput = stripAnsi(rawOutput);
      return {
        content: [{ type: "text" as const, text: cleanOutput }]
      };
    } catch (error: any) {
      logger.error(`Capture failed for ${target}`, error);
      return {
        isError: true,
        content: [{ type: "text" as const, text: `ERROR: ${error.message}` }]
      };
    }
  }
};
