import { TmuxClient } from "../core/tmux-client.js";
import { logLine } from "../core/logger.js";
import { stripAnsi } from "../utils/ansi.js";
import { asOptionalBoolean, asOptionalInt, asOptionalString, asString, isValidationError } from "../core/validate.js";

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function waitUntilPrompt(tmux, target, promptRegex, timeoutMs, pollIntervalMs, captureLines) {
  const startedAt = Date.now();
  while (Date.now() - startedAt <= timeoutMs) {
    const output = stripAnsi(tmux.capturePane(target, captureLines));
    if (promptRegex.test(output)) return output;
    await sleep(pollIntervalMs);
  }
  throw new Error(`Prompt non trovato entro ${timeoutMs}ms`);
}

export async function sendKeys(input) {
  const payload = input ?? {};
  const target = asString(payload.target, "target");
  const command = asString(payload.command, "command");
  const waitForPrompt = asOptionalBoolean(payload.waitForPrompt, "waitForPrompt");
  const promptRegex = asOptionalString(payload.promptRegex, "promptRegex");
  const timeoutMs = asOptionalInt(payload.timeoutMs, "timeoutMs", 1, 60000);
  const pollIntervalMs = asOptionalInt(payload.pollIntervalMs, "pollIntervalMs", 1, 2000);
  const captureLines = asOptionalInt(payload.captureLines, "captureLines", 1, 500);

  for (const candidate of [target, command, waitForPrompt, promptRegex, timeoutMs, pollIntervalMs, captureLines]) {
    if (isValidationError(candidate)) return { error: candidate };
  }

  const wait = waitForPrompt ?? false;
  const timeout = timeoutMs ?? 5000;
  const poll = pollIntervalMs ?? 150;
  const lines = captureLines ?? 50;
  const pattern = promptRegex ?? "[$#>] $";

  try {
    const tmux = new TmuxClient();
    tmux.sendKeys(target, command);
    logLine(`send_keys target=${target} wait_for_prompt=${wait} command=${JSON.stringify(command)}`);
    if (!wait) return { ok: true };

    const output = await waitUntilPrompt(tmux, target, new RegExp(pattern, "m"), timeout, poll, lines);
    return { ok: true, output };
  } catch (error) {
    return { error: { code: "SEND_FAILED", message: String(error) } };
  }
}
