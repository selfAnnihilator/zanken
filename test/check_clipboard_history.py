"""Run under dbus-run-session: exercise the real QML history and event stream."""

import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import time


SOURCE = Path(__file__).resolve().parents[1] / "default/desktop/quickshell/ClipboardHistory.qml"


with tempfile.TemporaryDirectory(prefix="zanken-clipboard-regression-") as directory:
  root = Path(directory)
  runtime = root / "runtime"
  runtime.mkdir(mode=0o700)
  config = root / "shell"
  config.mkdir()
  shutil.copy2(SOURCE, config / SOURCE.name)
  (config / "shell.qml").write_text('''import Quickshell
import Quickshell.Io
ShellRoot {
  ClipboardHistory { id: history; maxItems: 75; storePath: "%s" }
  IpcHandler {
    target: "test"
    function snapshot(): string { return JSON.stringify(history.entries); }
    function clear(): void { history.clear(); }
    function remove(index: int): void { history.remove(index); }
    function reload(): void { Quickshell.reload(false); }
  }
}
''' % (root / "history.json"))
  mock_bin = root / "bin"
  mock_bin.mkdir()
  watcher = mock_bin / "wl-paste"
  watcher.write_text('''#!/bin/bash
shift 3
while IFS=$'\t' read -r state event; do
  [[ $state == "stop" ]] && exit 1
  CLIPBOARD_STATE="$state" "$@" < "$CLIPBOARD_FIXTURES/$event"
done < "$CLIPBOARD_EVENTS"
''')
  watcher.chmod(0o755)
  events = root / "events"
  os.mkfifo(events)
  event_fd = os.open(events, os.O_RDWR)
  environment = {**os.environ, "XDG_RUNTIME_DIR": str(runtime),
    "XDG_CONFIG_HOME": str(root / "config"), "XDG_CACHE_HOME": str(root / "cache"),
    "QT_QPA_PLATFORM": "offscreen", "QS_NO_RELOAD_POPUP": "1",
    "PATH": str(mock_bin) + os.pathsep + os.environ["PATH"],
    "CLIPBOARD_EVENTS": str(events), "CLIPBOARD_FIXTURES": str(root)}
  environment.pop("WAYLAND_DISPLAY", None)
  environment.pop("DISPLAY", None)

  with (root / "qs.log").open("w+") as log:
    process = subprocess.Popen(["qs", "-p", str(config)], env=environment,
      stdout=log, stderr=log)
    try:
      def call(method, *arguments):
        return subprocess.run(["qs", "-p", str(config), "ipc", "call", "test",
          method, *map(str, arguments)], env=environment, text=True,
          capture_output=True, timeout=5)

      def await_entries(predicate):
        deadline = time.monotonic() + 6
        while time.monotonic() < deadline:
          result = call("snapshot")
          if result.returncode == 0:
            entries = json.loads(result.stdout)
            if predicate(entries):
              return entries
          if process.poll() is not None:
            break
          time.sleep(0.04)
        log.seek(0)
        raise AssertionError("History did not reach expected state:\n" + log.read())

      event_number = 0

      def emit(content, state="data"):
        global event_number
        event_number += 1
        name = "event-%s" % event_number
        (root / name).write_text(content)
        os.write(event_fd, (state + "\t" + name + "\n").encode())

      await_entries(lambda entries: entries == [])
      text = "line one\nदेवनागरी 日本語 😀\nquotes: \" ' $() `echo ignored`\n"
      emit(text)
      await_entries(lambda entries: len(entries) == 1 and entries[0]["content"] == text)
      emit("another copy")
      emit(text)
      await_entries(lambda entries: len(entries) == 2 and entries[0]["content"] == text)
      for number in range(80):
        emit("rapid copy %s" % number)
      entries = await_entries(lambda entries: len(entries) == 75
        and entries[0]["content"] == "rapid copy 79")
      assert [item["content"] for item in entries] == ["rapid copy %s" % n for n in range(79, 4, -1)]
      emit("sensitive copy", "sensitive")
      emit("", "nil")
      emit("rapid copy 79")
      await_entries(lambda entries: len(entries) == 75 and entries[0]["content"] == "rapid copy 79")
      assert call("reload").returncode == 0
      await_entries(lambda entries: len(entries) == 75 and entries[0]["content"] == "rapid copy 79")
      emit("after reload")
      entries = await_entries(lambda entries: entries[0]["content"] == "after reload")
      assert all(item["content"] != "sensitive copy" for item in entries)
      os.write(event_fd, b"stop\tunused\n")
      time.sleep(1.2)
      emit("after watcher restart")
      await_entries(lambda entries: entries[0]["content"] == "after watcher restart")
      assert call("remove", 0).returncode == 0
      await_entries(lambda entries: len(entries) == 74 and entries[0]["content"] == "after reload")
      assert call("clear").returncode == 0
      await_entries(lambda entries: entries == [])
      assert call("reload").returncode == 0
      await_entries(lambda entries: entries == [])
      emit("after clear")
      await_entries(lambda entries: len(entries) == 1 and entries[0]["content"] == "after clear")
      assert process.poll() is None
      print("PASS: unfocused events, exact Unicode/multiline text, rapid copies, dedupe, retention, reload, watcher recovery, removal and clear")
    finally:
      process.terminate()
      try:
        process.wait(timeout=5)
      except subprocess.TimeoutExpired:
        process.kill()
        process.wait()
      os.close(event_fd)
