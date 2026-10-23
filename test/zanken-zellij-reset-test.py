"""Exercise the optional explicit reset helper in a private namespace."""

import argparse
import json
import os
from pathlib import Path
import re
import subprocess

from zellij_pty import Workspace


def process_running(pid):
  try:
    return Path(f"/proc/{pid}/stat").read_text().split()[2] != "Z"
  except FileNotFoundError:
    return False


def run(evidence):
  helper = Path(__file__).resolve().parents[1] / "bin/zanken-cmd-zellij-session"
  outside = os.environ.copy()
  outside.pop("ZELLIJ_SESSION_NAME", None)
  result = subprocess.run([str(helper), "reset"], env=outside, text=True, capture_output=True)
  assert result.returncode == 1 and "inside Zellij" in result.stderr
  workspace = Workspace(evidence, answer_queries=True)
  workspace.session = "reset with spaces"
  with workspace as w:
    original_session = w.session
    w.action("pipe", "--name", "zanken-reset-return", "--", '{"session":"must-not-open","cwd":"/tmp"}')
    w.check("ordinary sessions ignore the reset handoff", "must-not-open" not in w.cli("list-sessions", "--no-formatting").stdout)
    original_client = w.proc, w.master
    w.session = "untouched"
    w.start()
    w.type("printf 'UNTOUCHED_%s\\n' SURVIVES")
    w.key("Return")
    other = w.terminals()[0]
    other_pane = f"terminal_{other['id']}"
    w.wait(lambda: "UNTOUCHED_SURVIVES" in w.frame(other_pane))
    w.session = original_session
    w.proc, w.master = original_client

    for _ in range(1):
      w.type("printf 'RESET_OLD_PID=%s\\n' $fish_pid")
      w.key("Return")
      current = w.terminals()[0]
      current_pane = f"terminal_{current['id']}"
      old_pid = int(re.search(r"RESET_OLD_PID=(\d+)", w.frame(current_pane))[1])
      w.type("sleep 600")
      w.key("Return")
      children = Path(f"/proc/{old_pid}/task/{old_pid}/children").read_text().split()
      w.action("new-pane", "--direction", "right")
      w.action("rename-pane", "DISCARD_OLD_PANE")
      w.action("new-tab", "--name", "DISCARD_OLD_TAB")
      w.action("save-session")
      w.check("reset fixture has multiple panes and tabs", len(w.tabs()) == 2)
      w.action("new-pane", "--floating", "--close-on-exit", "--", str(helper), "reset")

      def reset_finished():
        logs = list((w.root / "runtime").glob("zanken-reset.*"))
        if logs or w.proc.poll() is not None:
          return False
        listing = w.cli("list-sessions", "--no-formatting").stdout
        return "zanken-reset." not in listing and not process_running(old_pid) and len(w.tabs()) == 1

      try:
        w.wait(reset_finished, 30)
      except AssertionError:
        for log in (w.root / "runtime").glob("zanken-reset.*"):
          (w.evidence / "reset-worker.txt").write_text(log.read_text())
          for pane in json.loads(w.action("list-panes", "--all", "--json", session=log.name)):
            if pane["is_plugin"]:
              (w.evidence / f"bridge-plugin-{pane['id']}.txt").write_text(w.frame(f"plugin_{pane['id']}", session=log.name))
        raise
      w.check("explicit reset helper keeps the same terminal client", w.proc.poll() is None)
      w.check("old shell and running command stop", not process_running(old_pid) and all(not process_running(int(pid)) for pid in children))
      terminals = [p for p in w.panes() if not p["is_plugin"]]
      w.check("replacement is one new shell in home", len(terminals) == 1 and terminals[0]["pane_cwd"] == str(Path.home()))
      text = w.frame(f"terminal_{terminals[0]['id']}")
      w.check("old panes, tab names and output are not restored", "RESET_OLD_PID=" not in text and "DISCARD_OLD_TAB" not in json.dumps(w.tabs()))
      w.check("on-demand hints remain hidden while locked", not w.guide().strip())
      w.type("printf 'RESET_NEW_%s\\n' INPUT_OK")
      w.key("Return")
      w.wait(lambda: "RESET_NEW_INPUT_OK" in w.frame(f"terminal_{terminals[0]['id']}"))
      w.check("new shell accepts input")
      w.check("unrelated session is intact", "UNTOUCHED_SURVIVES" in w.frame(other_pane, session="untouched"))
      w.action("save-session")
      saved = next((w.root / "cache").glob(f"**/session_info/{original_session}/session-layout.kdl")).read_text()
      w.check("saved replacement contains no old layout", "DISCARD_OLD_TAB" not in saved and "DISCARD_OLD_PANE" not in saved)

    w.cli("kill-session", original_session)
    w.wait(lambda: w.proc.poll() is not None)
    w.start(resurrect=True)
    w.check("later resurrection restores only the blank replacement", len(w.tabs()) == 1 and len(w.terminals()) == 1 and "DISCARD_OLD_TAB" not in json.dumps(w.tabs()))


if __name__ == "__main__":
  parser = argparse.ArgumentParser(description=__doc__)
  parser.add_argument("--evidence", type=Path, default=Path("/tmp/zanken-zellij-reset"))
  run(parser.parse_args().evidence)
