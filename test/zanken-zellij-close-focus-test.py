"""Check that repeated close input cannot cascade through panes and tabs."""

import argparse
import os
from pathlib import Path
import time

from zellij_pty import Workspace


def run(evidence):
  with Workspace(evidence, answer_queries=True) as w:
    w.action("rename-tab", "KEEP")
    w.action("new-tab", "--name", "SPLIT")
    w.action("new-pane", "--direction", "right")
    w.wait(lambda: len(w.terminals()) == 2)
    original = w.terminals()
    target = next(p["id"] for p in original if p["is_focused"])
    survivor = next(p["id"] for p in original if not p["is_focused"])
    w.action("save-session")
    w.key("Ctrl+Alt+x")
    # Typical keyboard delay before repeat begins; then a held-key stream.
    time.sleep(.4)
    for _ in range(16):
      os.write(w.master, b"\x1b[120;7u")
      time.sleep(.04)
    time.sleep(.2)
    w.check("one held close gesture leaves both tabs intact", len(w.tabs()) == 2)
    w.check("only the initially focused split pane is closed",
      [p["id"] for p in w.terminals()] == [survivor] and target != survivor)
    time.sleep(.8)
    w.key("Ctrl+Alt+x")
    w.wait(lambda: len(w.tabs()) == 1)
    w.check("a later close removes the single-pane tab", w.tab()["name"] == "KEEP")
    time.sleep(.8)
    w.key("Ctrl+Alt+x")
    w.wait(lambda: w.proc.poll() is not None and not list((w.root / "runtime").glob("zanken-close-tab.*")), 15)
    w.check("final close removes saved session state", not list((w.root / "cache").glob("**/session_info/audit/session-layout.kdl")))


if __name__ == "__main__":
  parser = argparse.ArgumentParser(description=__doc__)
  parser.add_argument("--evidence", type=Path, default=Path("/tmp/zanken-close-repeat"))
  run(parser.parse_args().evidence)
