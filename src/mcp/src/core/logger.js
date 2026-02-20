import { appendFileSync, mkdirSync } from "node:fs";
import { dirname } from "node:path";

const logFile = `${process.env.HOME}/.bigide/logs/mcp.log`;

export function logLine(line) {
  mkdirSync(dirname(logFile), { recursive: true });
  appendFileSync(logFile, `${new Date().toISOString()} ${line}\n`, "utf8");
}
