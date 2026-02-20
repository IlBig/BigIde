import { z } from "zod";
import { TmuxClient } from "../core/tmux-client.js";
import { logger } from "../core/logger.js";

const client = new TmuxClient();

export const listTool = {
  name: "list_panes",
  description: "Elenca tutti i pannelli tmux attivi nella sessione corrente.",
  parameters: z.object({
    session: z.string().optional().describe("Nome sessione opzionale (default: corrente)"),
  }),
  handler: async ({ session }: { session?: string }) => {
    try {
      logger.info(`Listing panes for session: ${session || "current"}`);
      const rawOutput = client.listPanes(session);
      const panes = rawOutput.trim().split("\n").filter(Boolean);
      
      // Parser per il formato personalizzato
      const parsedPanes = panes.map(line => {
        const [idPart, rest] = line.split(": ");
        const [windowIndex, paneIndex] = idPart.split(".");
        // rest: %0 [238x50] (active?) cmd
        const match = rest.match(/%(\d+)\s+\[(\d+)x(\d+)\]\s*(?:\((active)\))?\s*(.*)/);
        
        if (!match) return { raw: line };

        const [, paneId, width, height, active, command] = match;
        return {
          id: `%${paneId}`,
          window: parseInt(windowIndex),
          index: parseInt(paneIndex),
          size: { width: parseInt(width), height: parseInt(height) },
          active: !!active,
          command: command.trim()
        };
      });

      return {
        content: [{ type: "text" as const, text: JSON.stringify(parsedPanes, null, 2) }]
      };
    } catch (error: any) {
      logger.error(`List panes failed`, error);
      return {
        isError: true,
        content: [{ type: "text" as const, text: `ERROR: ${error.message}` }]
      };
    }
  }
};
