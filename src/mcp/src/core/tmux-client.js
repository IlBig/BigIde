import { execFileSync } from "node:child_process";

export class TmuxClient {
  run(args) {
    return execFileSync("tmux", args, { encoding: "utf8" });
  }

  capturePane(target, lines = 50) {
    return this.run(["capture-pane", "-p", "-t", target, "-S", `-${lines}`]);
  }

  sendKeys(target, command) {
    this.run(["send-keys", "-t", target, command, "C-m"]);
  }

  listPanes(session) {
    return this.run([
      "list-panes",
      ...(session ? ["-t", session] : []),
      "-a",
      "-F",
      "#{session_name}:#{window_index}.#{pane_index}|#{pane_width}x#{pane_height}|#{pane_current_command}"
    ]);
  }
}
