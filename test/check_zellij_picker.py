"""In a Wayland session, exercise the real palette with private session fixtures."""

import json
import os
from pathlib import Path
import subprocess
import tempfile
import time


SOURCE = Path(__file__).resolve().parents[1] / "default/desktop/quickshell"


with tempfile.TemporaryDirectory(prefix="zanken-zellij-picker-") as directory:
  root = Path(directory)
  shell = root / "shell"
  shell.mkdir()
  for source in SOURCE.iterdir():
    if source.name != "shell.qml":
      (shell / source.name).symlink_to(source)
  (shell / "shell.qml").write_text('''import QtQuick
import Quickshell
import Quickshell.Io
ShellRoot {
  Theme { id: theme }
  OmniMenu { id: menu; theme: theme }
  IpcHandler {
    target: "test"
    function state(): string {
      return JSON.stringify({visible: menu.visible_, query: menu.query,
        items: menu.filteredItems.map(function(item) {
          return {name: item.sessionName, status: item.category};
        })});
    }
  }
}
''')
  commands = root / "bin"
  commands.mkdir()
  fixtures = root / "sessions.json"
  selected = root / "selected"
  for name, body in {
    "zanken-cmd-zellij-session": 'cat "$PICKER_FIXTURES"\n',
    # Real terminals write startup diagnostics after the short-lived launch
    # parent exits. A detached child must retain usable output descriptors.
    "zanken-launch-terminal-zellij": '''set -e
sleep 0.2
printf 'terminal startup diagnostic\\n' >&2
printf '%s\\0' "$@" > "$PICKER_SELECTED"
''',
  }.items():
    command = commands / name
    command.write_text("#!/bin/bash\n" + body)
    command.chmod(0o755)

  name = 'project "quoted" $literal `text`'
  fixtures.write_text(json.dumps([
    {"name": "visible work", "window_id": 42, "saved": False},
    {"name": name, "window_id": None, "saved": False},
    {"name": "saved project", "window_id": None, "saved": True},
  ]))
  environment = {**os.environ, "HOME": str(root),
    "XDG_CONFIG_HOME": str(root / "config"), "XDG_CACHE_HOME": str(root / "cache"),
    "XDG_STATE_HOME": str(root / "state"),
    "QT_QPA_PLATFORM": "wayland", "QS_NO_RELOAD_POPUP": "1",
    "PATH": str(commands) + os.pathsep + os.environ["PATH"],
    "PICKER_FIXTURES": str(fixtures), "PICKER_SELECTED": str(selected)}

  with (root / "qs.log").open("w+") as log:
    process = subprocess.Popen(["qs", "-p", str(shell)], env=environment,
                               stdout=log, stderr=log)
    try:
      def call(target, method, *arguments):
        return subprocess.run(["qs", "-p", str(shell), "ipc", "call", target,
          method, *arguments], env=environment, text=True, capture_output=True, timeout=5)

      def wait_for(predicate):
        deadline = time.monotonic() + 10
        while time.monotonic() < deadline:
          result = call("test", "state")
          if result.returncode == 0:
            state = json.loads(result.stdout)
            if predicate(state):
              return state
          if process.poll() is not None:
            break
          time.sleep(0.1)
        log.seek(0)
        raise AssertionError(f"Picker did not reach expected state\n{log.read()}")

      def keys(*arguments):
        subprocess.run(["wtype", *arguments], env=environment, check=True)

      wait_for(lambda state: not state["visible"])
      call("palette", "openCategory", "Zellij")
      state = wait_for(lambda state: state["visible"] and len(state["items"]) == 3)
      assert [item["status"] for item in state["items"]] == [
        "Focus window", "Open in new window", "Restore saved session"]
      time.sleep(0.25)
      keys("quoted")
      state = wait_for(lambda state: state["query"] == "quoted" and len(state["items"]) == 1)
      assert state["items"][0]["name"] == name
      keys("-k", "Return")
      wait_for(lambda state: not state["visible"] and selected.exists())
      assert selected.read_bytes().decode().split("\0")[:-1] == [name]
      selected.unlink()

      # Reopening probes again; keyboard navigation activates the saved row.
      call("palette", "openCategory", "Zellij")
      wait_for(lambda state: state["visible"] and len(state["items"]) == 3)
      time.sleep(0.25)
      keys("-k", "Down", "-k", "Down", "-k", "Up", "-k", "Down", "-k", "Return")
      wait_for(lambda state: not state["visible"] and selected.exists())
      assert selected.read_bytes().decode().split("\0")[:-1] == ["saved project"]
      selected.unlink()

      fixtures.write_text(json.dumps([
        {"name": "changed session", "window_id": None, "saved": False}]))
      call("palette", "openCategory", "Zellij")
      wait_for(lambda state: len(state["items"]) == 1 and state["items"][0]["name"] == "changed session")
      time.sleep(0.25)
      keys("-k", "Escape")
      wait_for(lambda state: not state["visible"])
      assert not selected.exists(), "Escape must not launch a session"

      fixtures.write_text("[]")
      call("palette", "openCategory", "Zellij")
      wait_for(lambda state: state["visible"] and not state["items"])
      time.sleep(0.25)
      keys("-k", "Return", "-k", "Escape")
      wait_for(lambda state: not state["visible"])
      assert not selected.exists(), "An empty picker must not create a session"
      print("Picker passed: labels, search, exact names, arrows, Enter, refresh, Escape, empty list")
    finally:
      process.terminate()
      try:
        process.wait(timeout=5)
      except subprocess.TimeoutExpired:
        process.kill()
        process.wait()
