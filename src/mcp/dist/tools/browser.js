import { z } from "zod";
import { execFileSync } from "node:child_process";
import { logger } from "../core/logger.js";
export const browserTool = {
    name: "open_browser",
    description: "Apre un URL nel browser predefinito (Chrome) sul sistema host macOS.",
    parameters: z.object({
        url: z.string().describe("URL completo (es. https://example.com)"),
    }),
    handler: async ({ url }) => {
        try {
            if (!/^https?:\/\//.test(url)) {
                throw new Error("Invalid URL: must start with http:// or https://");
            }
            logger.info(`Opening URL: ${url}`);
            execFileSync("open", ["-a", "Google Chrome", url]);
            return {
                content: [{ type: "text", text: `Opened ${url}` }]
            };
        }
        catch (error) {
            logger.error(`Failed to open browser`, error);
            return {
                isError: true,
                content: [{ type: "text", text: `ERROR: ${error.message}` }]
            };
        }
    }
};
