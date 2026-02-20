import { TmuxClient } from "../core/tmux-client.js";
import { stripAnsi } from "../utils/ansi.js";
import { asOptionalInt, asString, isValidationError } from "../core/validate.js";

export function capturePane(input) {
  const payload = input ?? {};
  const target = asString(payload.target, "target");
  const lines = asOptionalInt(payload.lines, "lines", 1, 500);
  if (isValidationError(target)) return { error: target };
  if (isValidationError(lines)) return { error: lines };

  try {
    const tmux = new TmuxClient();
    const output = tmux.capturePane(target, lines ?? 50);
    return { output: stripAnsi(output) };
  } catch (error) {
    return { error: { code: "PANE_NOT_FOUND", message: String(error) } };
  }
}
