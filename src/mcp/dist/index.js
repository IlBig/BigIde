import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { captureTool } from "./tools/capture.js";
import { sendKeysTool } from "./tools/send.js";
import { listTool } from "./tools/list.js";
import { browserTool } from "./tools/browser.js";
import { createPaneTool, closePaneTool, resizePaneTool } from "./tools/manage.js";
import { watchPaneTool } from "./tools/watch.js";
import { logger } from "./core/logger.js";
async function main() {
    logger.info("Starting BigIDE MCP Server...");
    const server = new McpServer({
        name: "BigIDE Tmux MCP",
        version: "1.0.0"
    });
    // Registra i tool
    server.tool(captureTool.name, captureTool.description, captureTool.parameters.shape, captureTool.handler);
    server.tool(sendKeysTool.name, sendKeysTool.description, sendKeysTool.parameters.shape, sendKeysTool.handler);
    server.tool(listTool.name, listTool.description, listTool.parameters.shape, listTool.handler);
    server.tool(browserTool.name, browserTool.description, browserTool.parameters.shape, browserTool.handler);
    server.tool(createPaneTool.name, createPaneTool.description, createPaneTool.parameters.shape, createPaneTool.handler);
    server.tool(closePaneTool.name, closePaneTool.description, closePaneTool.parameters.shape, closePaneTool.handler);
    server.tool(resizePaneTool.name, resizePaneTool.description, resizePaneTool.parameters.shape, resizePaneTool.handler);
    server.tool(watchPaneTool.name, watchPaneTool.description, watchPaneTool.parameters.shape, watchPaneTool.handler);
    // Connetti stdio
    const transport = new StdioServerTransport();
    await server.connect(transport);
    logger.info("MCP Server started and listening on stdio.");
}
main().catch((error) => {
    logger.error("Fatal error starting MCP server", error);
    process.exit(1);
});
