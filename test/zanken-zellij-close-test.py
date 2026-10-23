"""Check pane-first prefix closing, permanent final close and detaching."""

import argparse
import json
from pathlib import Path
import re
import time

from zellij_pty import Workspace


def running(pid):
  try:
    return Path(f"/proc/{pid}/stat").read_text().split()[2] != "Z"
  except FileNotFoundError:
    return False


def shell_pid(w, marker):
  pane = next(p for p in w.terminals() if p["is_focused"])
  w.type(f"printf '{marker}=%s\\n' $fish_pid")
  w.key("Return")
  w.wait(lambda: re.search(marker + r"=(\d+)", w.frame(f"terminal_{pane['id']}")))
  return int(re.search(marker + r"=(\d+)", w.frame(f"terminal_{pane['id']}"))[1])


def run(evidence):
  workspace = Workspace(evidence, answer_queries=True)
  workspace.session = "close with spaces"
  with workspace as w:
    w.action("rename-tab", "KEEP_THIS_TAB")
    keep = w.terminals()[0]
    keep_pid = shell_pid(w, "KEEP_PID")
    w.action("new-tab", "--name", "CLOSE_THIS_TAB")
    stopped = [shell_pid(w, "CLOSE_PID")]
    w.type("sleep 600")
    w.key("Return")
    children = Path(f"/proc/{stopped[0]}/task/{stopped[0]}/children").read_text().split()
    w.action("new-pane", "--direction", "right")
    stopped.append(shell_pid(w, "SECOND_PID"))
    w.action("save-session")
    w.check("fixture has two tabs and multiple panes in the tab to close", len(w.tabs()) == 2 and len(w.terminals()) == 2)
    target = next(p["id"] for p in w.terminals() if p["is_focused"])
    w.key("Ctrl+Space")
    w.key("x")
    w.wait(lambda: len(w.terminals()) == 1 and not list((w.root / "runtime").glob("zanken-close-tab.*")), 15)
    w.check("prefix x closes only the focused split pane", len(w.tabs()) == 2 and w.terminals()[0]["id"] != target)
    w.check("the other split pane and its program remain running", running(stopped[0]) and all(running(int(pid)) for pid in children))
    # Exercise the compatibility prefix with another split as well.
    w.action("new-pane", "--direction", "right")
    w.wait(lambda: len(w.terminals()) == 2)
    time.sleep(.8)
    target = next(p["id"] for p in w.terminals() if p["is_focused"])
    w.key("Ctrl+b")
    w.key("x")
    w.wait(lambda: len(w.terminals()) == 1 and not list((w.root / "runtime").glob("zanken-close-tab.*")), 15)
    w.check("Ctrl+b x also closes only the focused split pane", len(w.tabs()) == 2 and w.terminals()[0]["id"] != target)
    time.sleep(.8)
    w.key("Ctrl+Space")
    w.key("x")
    w.wait(lambda: len(w.tabs()) == 1 and not list((w.root / "runtime").glob("zanken-close-tab.*")), 15)
    w.wait(lambda: all(not running(pid) for pid in stopped + [int(pid) for pid in children]))
    w.check("prefix x closes a single-pane tab and stops its remaining programs")
    w.check("other tab and its shell stay intact", w.terminals()[0]["id"] == keep["id"] and running(keep_pid))
    saved_path = next((w.root / "cache").glob(f"**/session_info/{w.session}/session-layout.kdl"))
    w.check("closed tab is absent from the saved layout", "CLOSE_THIS_TAB" not in saved_path.read_text())

    w.key("Ctrl+Space")
    w.key("d")
    w.wait(lambda: w.proc.poll() is not None)
    w.check("prefix d detaches and keeps the last shell running", running(keep_pid))
    w.start(launcher=True)
    w.check("reopening after detach keeps only the surviving tab", len(w.tabs()) == 1 and w.tab()["name"] == "KEEP_THIS_TAB" and w.terminals()[0]["id"] == keep["id"])
    w.check("reattached session returns to locked mode", not w.guide().strip())
    w.type("printf 'DETACH_%s\\n' INPUT_OK")
    w.key("Return")
    w.wait(lambda: "DETACH_INPUT_OK" in w.frame(f"terminal_{keep['id']}"))
    w.check("shell accepts ordinary typing after reattach")

    w.cli("kill-session", w.session)
    w.wait(lambda: w.proc.poll() is not None)
    w.start(resurrect=True)
    w.check("resurrection does not restore the removed tab", len(w.tabs()) == 1 and "CLOSE_THIS_TAB" not in json.dumps(w.tabs()))
    w.action("save-session")
    for prefix in ("Ctrl+Space", "Ctrl+b"):
      time.sleep(.8)
      w.key(prefix)
      w.key("x")
      w.wait(lambda: w.proc.poll() is not None)
      # Reopen immediately: the launcher must wait for old snapshot deletion.
      w.start(launcher=True)
      w.check(prefix + " x on the final tab reopens a fresh single shell", len(w.tabs()) == 1 and len(w.terminals()) == 1 and "KEEP_THIS_TAB" not in json.dumps(w.tabs()))
      fresh = w.terminals()[0]
      w.check("fresh shell has no previous output or directory", "DETACH_INPUT_OK" not in w.frame(f"terminal_{fresh['id']}") and fresh["pane_cwd"] == str(w.cwd))
      w.check("close worker completed without leftover logs", not list((w.root / "runtime").glob("zanken-close-tab.*")))


if __name__ == "__main__":
  parser = argparse.ArgumentParser(description=__doc__)
  parser.add_argument("--evidence", type=Path, default=Path("/tmp/zanken-zellij-close"))
  run(parser.parse_args().evidence)
