"""Resume surviving live sessions even when launcher history misses them."""

import argparse
from pathlib import Path
import subprocess

from zellij_pty import Workspace


def run(evidence):
  workspace = Workspace(evidence, answer_queries=True)
  workspace.session = "older work"
  helper = str(workspace.source.parents[1] / "bin/zanken-cmd-zellij-session")
  with workspace as w:
    w.action("rename-tab", "KEEP_OLDER")
    older = w.session
    w.session = "recent work"
    w.start()
    w.action("rename-tab", "KEEP_RECENT")
    recent = w.session
    history = w.root / "state/zanken/zellij-session-history"
    history.parent.mkdir(parents=True, exist_ok=True)
    history.write_text("")

    def last():
      return subprocess.check_output([helper, "last"], env=w.env, text=True).strip()

    w.check("empty history resumes a surviving live session", last() == recent)
    history.write_text("already killed\n")
    w.check("stale history resumes a surviving live session", last() == recent)
    history.write_text("")
    w.session = "discard this"
    w.start(launcher=True)
    w.key("Ctrl+Space")
    w.key("k")
    w.wait(lambda: w.proc.poll() is not None and not list((w.root / "runtime").glob("zanken-kill.*")), 15)
    w.check("kill returns launcher selection to the recent surviving session", last() == recent)
    w.check("both original workspaces stay intact",
            "KEEP_RECENT" in w.action("list-tabs", "--all", "--json", session=recent)
            and "KEEP_OLDER" in w.action("list-tabs", "--all", "--json", session=older))
    w.check("history reconciles previously untracked live sessions",
            set(history.read_text().splitlines()) == {older, recent})


if __name__ == "__main__":
  parser = argparse.ArgumentParser(description=__doc__)
  parser.add_argument("--evidence", type=Path, default=Path("/tmp/zanken-zellij-history"))
  run(parser.parse_args().evidence)
