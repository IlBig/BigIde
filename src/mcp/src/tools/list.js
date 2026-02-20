import { TmuxClient } from "../core/tmux-client.js";
import { asOptionalString, isValidationError } from "../core/validate.js";

export function listPanes(input) {
  const payload = input ?? {};
  const session = asOptionalString(payload.session, "session");
  if (isValidationError(session)) return { error: session };

  try {
    const tmux = new TmuxClient();
    const raw = tmux.listPanes(session);
    return { panes: raw.trim().split("\n").filter(Boolean) };
  } catch (error) {
    return { error: { code: "LIST_FAILED", message: String(error) } };
  }
}
