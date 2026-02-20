import { execFileSync } from "node:child_process";
import { asString, isValidationError } from "../core/validate.js";

export function openBrowser(input) {
  const payload = input ?? {};
  const url = asString(payload.url, "url");
  if (isValidationError(url)) return { error: url };
  if (!/^https?:\/\//.test(url)) {
    return { error: { code: "INVALID_INPUT", message: "url deve iniziare con http:// o https://" } };
  }

  try {
    execFileSync("open", ["-a", "Google Chrome", url]);
    return { ok: true };
  } catch (error) {
    return { error: { code: "BROWSER_OPEN_FAILED", message: String(error) } };
  }
}
