"""Check session selection and desktop focus without touching real sessions."""

import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest


class LauncherTest(unittest.TestCase):
  def setUp(self):
    self.source = Path(__file__).resolve().parents[1]
    self.temporary = tempfile.TemporaryDirectory(prefix="zanken-launcher-")
    self.addCleanup(self.temporary.cleanup)
    self.root = Path(self.temporary.name)
    commands = self.root / "bin"
    commands.mkdir()
    self.listing = self.root / "sessions"
    self.listing.touch()
    self.arguments = self.root / "arguments"
    self.windows = self.root / "windows.json"
    self.windows.write_text("[]")
    scripts = {
      "zellij": r"""#!/bin/bash
if [[ $1 == "list-sessions" ]]; then
  cat "$MOCK_SESSIONS"
  exit
fi
printf '%s\0' "$@" > "$LAUNCH_ARGS"
if [[ $1 == "attach" ]]; then session_name=$3; else session_name=$2; fi
if ! grep -Fq -- "$session_name [Created" "$MOCK_SESSIONS"; then
  printf '%s [Created 1m ago] \n' "$session_name" > "$MOCK_SESSIONS.new"
  cat "$MOCK_SESSIONS" >> "$MOCK_SESSIONS.new"
  mv "$MOCK_SESSIONS.new" "$MOCK_SESSIONS"
fi
""",
      "niri": r"""#!/bin/bash
if [[ $2 == "--json" ]]; then
  cat "$MOCK_WINDOWS"
else
  printf '%s\0' "$@" > "$NIRI_ARGS"
fi
""",
      "zanken-launch-terminal": r"""#!/bin/bash
printf '%s\0' "$@" > "$TERMINAL_ARGS"
""",
      "foot": r"""#!/bin/bash
printf '%s\0' "$@" > "$TERMINAL_ARGS"
""",
      "setsid": r"""#!/bin/bash
exec "$@"
""",
      "uwsm-app": r"""#!/bin/bash
[[ $1 == "--" ]] && shift
exec "$@"
""",
      "zanken-cmd-terminal-cwd": r"""#!/bin/bash
printf '%s\n' "$MOCK_CWD"
""",
    }
    for name, content in scripts.items():
      executable = commands / name
      executable.write_text(content)
      executable.chmod(0o755)
    self.env = os.environ.copy()
    for name in ("ZELLIJ", "ZELLIJ_SESSION_NAME", "ZELLIJ_PANE_ID", "NIRI_SOCKET"):
      self.env.pop(name, None)
    self.env.update(PATH=f"{commands}:{self.source / 'bin'}:{self.env['PATH']}",
                    XDG_STATE_HOME=str(self.root / "state"), XDG_RUNTIME_DIR=str(self.root),
                    LAUNCH_ARGS=str(self.arguments), MOCK_SESSIONS=str(self.listing),
                    MOCK_WINDOWS=str(self.windows), NIRI_ARGS=str(self.root / "niri-args"),
                    TERMINAL_ARGS=str(self.root / "terminal-args"), MOCK_CWD=str(self.root / "project with spaces"))
    self.state = self.root / "state/zanken"

  def helper(self, *arguments):
    return subprocess.check_output(
      [str(self.source / "bin/zanken-cmd-zellij-session"), *arguments],
      env=self.env, text=True).strip()

  def launch(self, *arguments):
    subprocess.run([str(self.source / "bin/zanken-launch-zellij"), *arguments],
                   env=self.env, check=True)
    return self.arguments.read_bytes().decode().strip("\0").split("\0")

  def test_fresh_and_resume(self):
    self.assertEqual(self.launch(), ["--session", "main"])
    self.assertEqual(self.launch("project with spaces"),
                     ["attach", "--create", "project with spaces"])
    self.assertEqual(self.launch(), ["attach", "--create", "project with spaces"])
    first = self.launch("--new")
    second = self.launch("--new")
    self.assertEqual(first[0], "--session")
    self.assertEqual(len(first), 2)
    self.assertNotEqual(first[1], second[1])
    self.assertEqual(self.launch(), ["attach", "--create", second[1]])
    marker = self.state / "zellij-last-session"
    self.assertEqual(marker.stat().st_mode & 0o777, 0o600)
    nested = self.env | {"ZELLIJ": "1"}
    subprocess.run([str(self.source / "bin/zanken-launch-zellij"), "--new"],
                   env=nested, check=True)
    self.assertEqual(marker.read_text().strip(), second[1])

  def test_empty_or_stale_history_falls_back_to_surviving_live_sessions(self):
    self.listing.write_text("kaze work [Created 1h ago] \nwork [Created 2h ago] \n")
    self.state.mkdir(parents=True)
    for history in ("", "killed session\n"):
      with self.subTest(history=history):
        (self.state / "zellij-session-history").write_text(history)
        self.assertEqual(self.helper("last"), "kaze work")
        self.assertEqual(self.launch(), ["attach", "--create", "kaze work"])
        self.assertIn("work", (self.state / "zellij-session-history").read_text().splitlines())

  def test_saved_remembered_session_can_resurrect_but_stale_name_cannot(self):
    self.listing.write_text("saved project [Created 1day ago] (EXITED - attach to resurrect)\n")
    self.state.mkdir(parents=True)
    history = self.state / "zellij-session-history"
    history.write_text("deleted\nsaved project\n")
    self.assertEqual(self.helper("last"), "saved project")
    history.write_text("deleted\n")
    self.assertEqual(self.helper("last"), "")

  def test_desktop_focus_reuses_most_recent_existing_window(self):
    self.listing.write_text("kaze work [Created 1h ago] \nwork [Created 2h ago] \n")
    self.env["NIRI_SOCKET"] = "private-mock"
    self.windows.write_text(json.dumps([
      {"id": 16, "app_id": "foot", "title": "kaze work | fish", "focus_timestamp": {"secs": 100, "nanos": 1}},
      {"id": 22, "app_id": "foot", "title": "work | nvim", "focus_timestamp": {"secs": 200, "nanos": 1}},
      {"id": 99, "app_id": "browser", "title": "kaze work | other", "focus_timestamp": {"secs": 500}},
    ]))
    self.assertEqual(self.helper("last"), "work")
    self.assertEqual(self.helper("window", "work"), "22")
    wrapper = str(self.source / "bin/zanken-launch-terminal-zellij")
    subprocess.run([wrapper], env=self.env, check=True)
    self.assertEqual((self.root / "niri-args").read_bytes().decode().split("\0")[:-1],
                     ["msg", "action", "focus-window", "--id", "22"])
    self.assertFalse((self.root / "terminal-args").exists())
    subprocess.run([wrapper, "--new"], env=self.env, check=True)
    self.assertEqual((self.root / "terminal-args").read_bytes().decode().split("\0")[:-1][-2:],
                     ["zanken-launch-zellij", "--new"])

  def test_fresh_desktop_launch_uses_the_existing_foot_theme(self):
    wrapper = str(self.source / "bin/zanken-launch-terminal-zellij")
    subprocess.run([wrapper, "--new"], env=self.env, check=True)
    arguments = (self.root / "terminal-args").read_bytes().decode().split("\0")[:-1]
    self.assertEqual(arguments, [f"--config={self.env['HOME']}/.config/foot/foot.ini",
                                f"--working-directory={self.env['MOCK_CWD']}",
                                "-e", "zanken-launch-zellij", "--new"])


if __name__ == "__main__":
  unittest.main()
