export function stripAnsi(value) {
  return value.replace(/\u001b\[[0-9;]*[A-Za-z]/g, "");
}
