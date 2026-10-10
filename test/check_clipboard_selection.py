"""Run in a Wayland session: exercise the real popup using a private clipboard sink."""

import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import time


SOURCE = Path(__file__).resolve().parents[1] / "default/desktop/quickshell"


with tempfile.TemporaryDirectory(prefix="zanken-clipboard-selection-") as directory:
  root = Path(directory)
  config = root / "shell"
  config.mkdir()
  for name in ["ClipboardPopup.qml", "CardWindow.qml"]:
    shutil.copy2(SOURCE / name, config / name)
  (config / "shell.qml").write_text('''import QtQuick
import Quickshell
import Quickshell.Io
ShellRoot {
  Item {
    id: nav
    property bool clipboardVisible: true
    property var clipHistory: []
    property var screenshotFiles: []
    property string barEdge: ""
    property real popupAnchorX: 0
    property real popupAnchorY: 0
    property int cornerRadius: 0
    property color paper: "#181616"
    property color bg: paper
    property color ink: "#c5c9c5"
    property color inkDeep: ink
    property color muted: "#777777"
    property color seal: "#c4746e"
    property color sep: "#333333"
    property string mono: "monospace"
    function clearClipHistory() {}
    function removeClipItem(index) {}
    function copyScreenshotToClipboard(path) {}
  }
  ClipboardPopup { id: popup; root: nav; revealed: false }
  IpcHandler {
    target: "test"
    function select(text: string): void { nav.clipboardVisible = true; popup.copyText(text); }
    function selectLarge(): void { nav.clipboardVisible = true; popup.copyText("x".repeat(180000)); }
    function selectLeading(): void { nav.clipboardVisible = true; popup.copyText("--leading options"); }
    function burst(first: string, last: string): void {
      nav.clipboardVisible = true;
      popup.copyText(first);
      popup.copyText(last);
    }
    function state(): string {
      return JSON.stringify({visible: nav.clipboardVisible, copied: popup.copiedContent});
    }
  }
}
''')
  mock_bin = root / "bin"
  mock_bin.mkdir()
  writer = mock_bin / "wl-copy"
  writer.write_text('''#!/bin/bash
[[ -f $MOCK_COPY_FAIL ]] && exit 1
sleep 0.15
cat > "$MOCK_CLIPBOARD_FILE"
''')
  writer.chmod(0o755)
  copied = root / "clipboard"
  failed = root / "copy-fail"
  environment = {**os.environ,
    "XDG_CONFIG_HOME": str(root / "config"), "XDG_CACHE_HOME": str(root / "cache"),
    "QT_QPA_PLATFORM": "wayland", "QS_NO_RELOAD_POPUP": "1",
    "PATH": str(mock_bin) + os.pathsep + os.environ["PATH"],
    "MOCK_CLIPBOARD_FILE": str(copied), "MOCK_COPY_FAIL": str(failed)}

  with (root / "qs.log").open("w+") as log:
    process = subprocess.Popen(["qs", "-p", str(config)], env=environment,
      stdout=log, stderr=log)
    try:
      def call(method, *arguments):
        return subprocess.run(["qs", "-p", str(config), "ipc", "call", "test",
          method, *arguments], env=environment, text=True, capture_output=True, timeout=5)

      def wait_for(predicate):
        deadline = time.monotonic() + 5
        while time.monotonic() < deadline:
          result = call("state")
          if result.returncode == 0:
            try:
              state = json.loads(result.stdout)
            except json.JSONDecodeError:
              state = None
            if state is not None and predicate(state):
              return
          if process.poll() is not None:
            break
          time.sleep(0.04)
        log.seek(0)
        details = {"clipboard_size": copied.stat().st_size if copied.exists() else None}
        if state is not None:
          details.update(visible=state["visible"], copied_size=len(state["copied"]))
        raise AssertionError("Selection did not reach expected state: " + str(details) + "\n" + log.read())

      wait_for(lambda state: state["visible"])
      samples = ["chosen older history entry",
        "multiline\nदेवनागरी 日本語 😀\nquotes: \" ' $() `echo ignored`\n",
        "--leading options",
        "x" * 180000]
      for text in samples:
        copied.unlink(missing_ok=True)
        if len(text) > 131000:
          result = call("selectLarge")
        elif text.startswith("--"):
          result = call("selectLeading")
        else:
          result = call("select", text)
        assert result.returncode == 0, result.stdout + result.stderr
        wait_for(lambda state: copied.exists() and copied.read_text() == text
          and not state["visible"])
      failed.touch()
      assert call("select", "copy must fail").returncode == 0
      time.sleep(0.3)
      state = json.loads(call("state").stdout)
      assert state["visible"], "Failed copy must leave the popup open"
      assert state["copied"] != "copy must fail", "Failed copy must not report success"
      assert copied.read_text() == samples[-1], "Failed copy changed the clipboard"
      failed.unlink()
      assert call("select", "retry succeeds").returncode == 0
      wait_for(lambda state: copied.read_text() == "retry succeeds" and not state["visible"])
      assert call("burst", "first click", "latest click").returncode == 0
      wait_for(lambda state: copied.read_text() == "latest click" and not state["visible"])
      print("PASS: popup selection copies exact text, closes after success, handles failure/retry, and preserves the latest click")
    finally:
      process.terminate()
      try:
        process.wait(timeout=5)
      except subprocess.TimeoutExpired:
        process.kill()
        process.wait()
