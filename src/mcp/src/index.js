#!/usr/bin/env node
import readline from "node:readline";
import { capturePane } from "./tools/capture.js";
import { sendKeys } from "./tools/send.js";
import { listPanes } from "./tools/list.js";
import { openBrowser } from "./tools/browser.js";
import { logLine } from "./core/logger.js";

const rl = readline.createInterface({ input: process.stdin, output: process.stdout, terminal: false });

async function handleRequest(req) {
  if (!req || typeof req !== "object" || !req.tool) {
    return { error: { code: "INVALID_REQUEST", message: "Campo tool mancante" } };
  }

  switch (req.tool) {
    case "capturePane":
      return capturePane(req.input);
    case "sendKeys":
      return await sendKeys(req.input);
    case "listPanes":
      return listPanes(req.input);
    case "openBrowser":
      return openBrowser(req.input);
    default:
      return { error: { code: "UNKNOWN_TOOL", message: `Tool non supportato: ${req.tool}` } };
  }
}

rl.on("line", async (line) => {
  let req;
  try {
    req = JSON.parse(line);
  } catch {
    process.stdout.write(`${JSON.stringify({ error: { code: "INVALID_JSON", message: "JSON non valido" } })}\n`);
    return;
  }

  const response = await handleRequest(req);
  process.stdout.write(`${JSON.stringify({ id: req.id ?? null, ...response })}\n`);
});

rl.on("close", () => logLine("mcp-stdio terminated"));
