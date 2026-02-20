import { z } from "zod";
import { TmuxClient } from "../core/tmux-client.js";
import { logger } from "../core/logger.js";
import { stripAnsi } from "../utils/ansi.js";

const client = new TmuxClient();

export const sendKeysTool = {
  name: "send_keys",
  description: "Invia comandi o tasti a un pannello tmux. Può attendere il prompt per conferma esecuzione.",
  parameters: z.object({
    target: z.string().describe("Target pane (es. '%1', 'log.0')"),
    command: z.string().describe("Comando o sequenza di tasti da inviare"),
    waitForPrompt: z.boolean().optional().default(false).describe("Attendi il ritorno del prompt?"),
    promptRegex: z.string().optional().describe("Regex per rilevare il prompt (default: [$#>] $)"),
    timeoutMs: z.number().optional().default(5000).describe("Timeout attesa prompt in ms"),
    captureLines: z.number().optional().default(50).describe("Righe da catturare per verifica prompt"),
  }),
  handler: async ({ target, command, waitForPrompt, promptRegex, timeoutMs, captureLines }: any) => {
    try {
      logger.info(`Sending keys to ${target}: ${command} (wait=${waitForPrompt})`);
      client.sendKeys(target, command);

      if (waitForPrompt) {
        const regex = new RegExp(promptRegex || "[$#>] $");
        const output = await client.waitForPrompt(target, regex, timeoutMs);
        return {
          content: [{ type: "text" as const, text: output }]
        };
      }

      return {
        content: [{ type: "text" as const, text: "Command sent successfully." }]
      };
    } catch (error: any) {
      logger.error(`Send keys failed for ${target}`, error);
      return {
        isError: true,
        content: [{ type: "text" as const, text: `ERROR: ${error.message}` }]
      };
    }
  }
};
