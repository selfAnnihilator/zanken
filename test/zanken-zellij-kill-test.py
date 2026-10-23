"""Check prefix k permanently kills its session without a replacement client."""

import argparse
from pathlib import Path
import re

from zellij_pty import Workspace


def running(pid):
  try:
    return Path(f"/proc/{pid}/stat").read_text().split()[2] != "Z"
  except FileNotFoundError:
    return False


def run(evidence):
  workspace = Workspace(evidence, answer_queries=True)
  workspace.session = "kill with spaces"
  with workspace as w:
    original = w.session, w.proc, w.master
    w.session = "untouched"
    w.start()
    w.type("printf 'KEEP_%s\\n' RUNNING")
    w.key("Return")
    other = w.terminals()[0]
    w.wait(lambda: "KEEP_RUNNING" in w.frame(f"terminal_{other['id']}"))
    w.session, w.proc, w.master = original
    for prefix, key in (("Ctrl+Space", "k"), ("Ctrl+b", "K")):
      w.type("printf 'OLD_PID=%s\\n' $fish_pid")
      w.key("Return")
      old = w.terminals()[0]
      w.wait(lambda: re.search(r"OLD_PID=(\d+)", w.frame(f"terminal_{old['id']}")))
      pid = int(re.search(r"OLD_PID=(\d+)", w.frame(f"terminal_{old['id']}"))[1])
      w.type("sleep 600")
      w.key("Return")
      children = Path(f"/proc/{pid}/task/{pid}/children").read_text().split()
      w.action("new-pane", "--direction", "right")
      w.action("new-tab", "--name", "DISCARD")
      w.action("save-session")
      w.key(prefix)
      w.key(key)
      w.wait(lambda: w.proc.poll() is not None and not list((w.root / "runtime").glob("zanken-kill.*")), 15)
      w.check(prefix + " " + key + " ends the terminal client", w.proc.poll() is not None)
      w.check("all original programs stop", not running(pid) and all(not running(int(child)) for child in children))
      w.check("saved session state is deleted", not list((w.root / "cache").glob(f"**/session_info/{w.session}/session-layout.kdl")))
      listing = w.cli("list-sessions", "--no-formatting").stdout
      w.check("no replacement session or reset bridge is started", w.session not in listing and "zanken-reset." not in listing)
      w.check("other session remains running", "KEEP_RUNNING" in w.frame(f"terminal_{other['id']}", session="untouched"))
      w.start(launcher=True)
      w.check("later reopening creates a fresh one-pane workspace", len(w.tabs()) == 1 and len(w.terminals()) == 1 and w.tab()["name"] != "DISCARD")


if __name__ == "__main__":
  parser = argparse.ArgumentParser(description=__doc__)
  parser.add_argument("--evidence", type=Path, default=Path("/tmp/zanken-zellij-kill"))
  run(parser.parse_args().evidence)
