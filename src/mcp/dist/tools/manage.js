import { z } from "zod";
import { TmuxClient } from "../core/tmux-client.js";
import { logger } from "../core/logger.js";
const client = new TmuxClient();
export const createPaneTool = {
    name: "create_pane",
    description: "Crea un nuovo pannello tmux splittando quello esistente.",
    parameters: z.object({
        target: z.string().describe("Target pane esistente da splittare (es. '%1')"),
        direction: z.enum(["h", "v"]).default("h").describe("Direzione split: 'h' (orizzontale/fianco) o 'v' (verticale/sotto)"),
        size: z.string().optional().describe("Dimensione opzionale (es. '20%', '10')"),
        command: z.string().optional().describe("Comando da eseguire nel nuovo pannello"),
    }),
    handler: async ({ target, direction, size, command }) => {
        try {
            logger.info(`Creating pane from ${target} (${direction})`);
            const newPaneId = client.splitWindow(target, direction, size);
            if (command) {
                client.sendKeys(newPaneId, command);
            }
            return {
                content: [{ type: "text", text: `Created pane ${newPaneId}` }]
            };
        }
        catch (error) {
            logger.error(`Create pane failed`, error);
            return {
                isError: true,
                content: [{ type: "text", text: `ERROR: ${error.message}` }]
            };
        }
    }
};
export const closePaneTool = {
    name: "close_pane",
    description: "Chiude un pannello tmux specifico.",
    parameters: z.object({
        target: z.string().describe("Target pane da chiudere (es. '%1')"),
    }),
    handler: async ({ target }) => {
        try {
            logger.info(`Closing pane ${target}`);
            client.killPane(target);
            return {
                content: [{ type: "text", text: `Closed pane ${target}` }]
            };
        }
        catch (error) {
            logger.error(`Close pane failed`, error);
            return {
                isError: true,
                content: [{ type: "text", text: `ERROR: ${error.message}` }]
            };
        }
    }
};
export const resizePaneTool = {
    name: "resize_pane",
    description: "Ridimensiona un pannello tmux.",
    parameters: z.object({
        target: z.string().describe("Target pane da ridimensionare"),
        direction: z.enum(["U", "D", "L", "R"]).describe("Direzione resize (Up, Down, Left, Right)"),
        amount: z.number().default(5).describe("Quantità righe/colonne"),
    }),
    handler: async ({ target, direction, amount }) => {
        try {
            logger.info(`Resizing pane ${target} ${direction} ${amount}`);
            client.resizePane(target, direction, amount);
            return {
                content: [{ type: "text", text: `Resized pane ${target}` }]
            };
        }
        catch (error) {
            logger.error(`Resize pane failed`, error);
            return {
                isError: true,
                content: [{ type: "text", text: `ERROR: ${error.message}` }]
            };
        }
    }
};
