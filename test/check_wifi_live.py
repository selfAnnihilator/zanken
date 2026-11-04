"""Run under dbus-run-session: replay NetworkManager changes through real Wi-Fi QML.

The harness loads the Wi-Fi state/probes and popup bindings verbatim from the
production files. Only unrelated desktop services and shell login setup are
excluded; all nmcli processes, completion signals and timers run in Quickshell.
"""

import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import time


parser = argparse.ArgumentParser()
parser.add_argument("--source", type=Path, default=Path(__file__).resolve().parents[1] / "default/desktop/quickshell")
parser.add_argument("--case", default="all")
args = parser.parse_args()
navbar = (args.source / "Navbar.qml").read_text()
state = navbar[navbar.index('    property string wifiSsid:'):navbar.index('    property string btIcon:')]
probes = navbar[navbar.index('    // ---------- Wi-Fi live-refresh timer'):navbar.index('    // ---------- Audio sinks probe')]
open_wifi = navbar[navbar.index('    function openWifi()'):navbar.index('    function openBluetooth()')]

with tempfile.TemporaryDirectory(prefix="zanken-wifi-check-") as directory:
  root = Path(directory)
  runtime = root / "runtime"
  runtime.mkdir(mode=0o700)
  config = root / "shell"
  config.mkdir()
  shutil.copy2(args.source / "WifiPopup.qml", config / "WifiPopup.qml")
  shutil.copy2(args.source / "ToggleSwitch.qml" if (args.source / "ToggleSwitch.qml").exists()
    else Path(__file__).resolve().parents[1] / "default/desktop/quickshell/ToggleSwitch.qml", config / "ToggleSwitch.qml")
  # Keep the real popup/delegates; replace only the compositor-owned surface.
  (config / "CardWindow.qml").write_text('''import QtQuick
Item {
  property var theme
  property bool revealed: false
  property real cardWidth: 400
  property string layerNamespace: ""
  property string footer: ""
  property string anchorEdge: ""
  property real anchorBarX: 0
  property real anchorBarY: 0
  signal dismiss()
  signal keyPressed(var event)
  width: cardWidth
  visible: revealed
  function requestKeyboardFocus(item) { item.forceActiveFocus(); }
}
''')
  qml = '''import QtQuick
import Quickshell
import Quickshell.Io
ShellRoot {
  Item {
    id: root
    property bool wifiVisible: false
    property var wifiAnchorItem: null
    property color ink: "#eeeeee"
    property color inkDeep: "#999999"
    property color seal: "#df237f"
    property color sep: "#333333"
    property string mono: "monospace"
    property string barEdge: "top"
    property real popupAnchorX: 0
    property real popupAnchorY: 0
    property var vpnStatus: ({enabled: false, isProtected: false, needsAttention: false, state: "disconnected", connectionLabel: "", description: ""})
    function wifiBarsGlyph(pct) { return "wifi"; }
    function closeAllCards() {}
    function anchorPopupTo(item) {}
    function run(command) { action.exec(["bash", "-c", command]); }
    Process { id: action }
%s
%s
%s
    WifiPopup {
      id: wifiPopup
      root: parent
    }
    function visiblePasswordText(item) {
      if (item.echoMode !== undefined && item.visible) return item.text;
      for (const child of item.children || []) {
        const text = root.visiblePasswordText(child);
        if (text !== null) return text;
      }
      return null;
    }
    IpcHandler {
      target: "test"
      function snapshot(): string {
        return JSON.stringify({radio: root.wifiRadioOn, ssid: wifiPopup.activeSsid,
          active: wifiPopup.activeNetwork, connecting: root.wifiConnectingSSID,
          error: root.wifiConnectError, networks: root.wifiNetworks,
          known: root.wifiKnownSsids, saved: wifiPopup.knownAvailableNetworks,
          details: root.wifiConnectionDetails, scanning: root.wifiScanning,
          password: wifiPopup.pendingConnectPassword || "",
          passwordField: root.visiblePasswordText(wifiPopup)});
      }
      function open(): void { root.openWifi(); }
      function close(): void { root.wifiVisible = false; }
      function connect(ssid: string): void { root.connectWifi(ssid, ""); }
      function refresh(): void { root.refreshWifi(); }
      function reload(): void { Quickshell.reload(false); }
      function parse(text: string): string { return JSON.stringify(root.parseWifiNetworks(text)); }
      function password(ssid: string, text: string): void {
        wifiPopup.pendingConnectSsid = ssid;
        wifiPopup.pendingConnectPassword = text;
      }
      function forget(ssid: string): void { root.forgetWifi(ssid); }
    }
  }
}
''' % (state, probes, open_wifi)
  # Keep fixtures on PATH; production login profiles would replace it.
  (config / "shell.qml").write_text(qml.replace('"bash", "-lc"', '"bash", "-c"'))
  mock_bin = root / "bin"
  mock_bin.mkdir()
  events = root / "events"
  os.mkfifo(events)
  event_fd = os.open(events, os.O_RDWR)
  fixture = root / "state.json"
  calls = root / "calls.jsonl"
  mock = mock_bin / "nmcli"
  mock.write_text('''#!/usr/bin/python3
import json, os, sys, time
from pathlib import Path
p = Path(os.environ["WIFI_FIXTURE"])
args = sys.argv[1:]
with open(os.environ["WIFI_CALLS"], "a") as f:
  f.write(json.dumps(args) + "\\n")
def load(): return json.loads(p.read_text())
def save(s):
  tmp = p.with_suffix(".next")
  tmp.write_text(json.dumps(s))
  tmp.replace(p)
def esc(s): return s.replace("\\\\", "\\\\\\\\").replace(":", "\\\\:")
if "monitor" in args:
  with open(os.environ["WIFI_EVENTS"]) as f:
    for line in f:
      if line.strip() == "stop": sys.exit(1)
      print(line.strip(), flush=True)
  sys.exit()
s = load()
if "connect" in args and "wifi" in args:
  time.sleep(s.get("delay", 0.12))
  if s.get("fail"):
    print("fixture activation failed", file=sys.stderr)
    sys.exit(10)
  s["ssid"] = args[args.index("connect") + 1]
  save(s)
  sys.exit()
if "delete" in args:
  indexes = {int(v.replace("uuid-", "")) for v in args[args.index("delete") + 1:]}
  s["known"] = [name for i, name in enumerate(s["known"]) if i not in indexes]
  save(s)
  sys.exit()
if "rescan" in args:
  time.sleep(s.get("scan_delay", 0.05))
  if s.get("scan_fail"): sys.exit(1)
  sys.exit()
if "radio" in args:
  print("enabled" if s["radio"] else "disabled")
elif "list" in args and "wifi" in args:
  time.sleep(s.get("read_delay", 0))
  for ssid, strength in s["networks"]:
    print(("*" if s["radio"] and s["ssid"] == ssid else " ") + ":" + esc(ssid) + ":WPA2:" + str(strength))
elif "connection" in args and "show" in args:
  if "802-11-wireless.ssid" in args:
    print(esc(s["known"][int(args[-1].replace("uuid-", ""))]))
  elif "UUID,TYPE" in args:
    for i, ssid in enumerate(s["known"]): print("uuid-%d:802-11-wireless" % i)
  else:
    for ssid in s["known"]: print(esc("profile " + ssid) + ":802-11-wireless")
elif "device" in args:
  print("wlan0:wifi:connected" if "STATE" in " ".join(args) else "wlan0:wifi")
else:
  print("unhandled fixture command: " + repr(args), file=sys.stderr)
  sys.exit(2)
''')
  mock.chmod(0o755)
  for name in ("ip", "iw"):
    tool = mock_bin / name
    tool.write_text('#!/bin/bash\nif [[ $1 == "dev" ]]; then printf "  freq: 5180\\n"; elif [[ $1 == "route" ]]; then printf "default via 192.0.2.1 dev wlan0\\n"; else printf "2: wlan0 inet 192.0.2.2/24\\n"; fi\n')
    tool.chmod(0o755)
  environment = {**os.environ, "XDG_RUNTIME_DIR": str(runtime),
    "XDG_CONFIG_HOME": str(root / "config"), "QT_QPA_PLATFORM": "offscreen",
    "QS_NO_RELOAD_POPUP": "1", "PATH": str(mock_bin) + os.pathsep + os.environ["PATH"],
    "WIFI_FIXTURE": str(fixture), "WIFI_CALLS": str(calls), "WIFI_EVENTS": str(events)}
  environment.pop("WAYLAND_DISPLAY", None)
  environment.pop("DISPLAY", None)

  def write_state(**changes):
    data = {"radio": True, "ssid": "Alpha", "networks": [["Alpha", 70], ["Beta", 80]], "known": ["Alpha", "Beta"]}
    if fixture.exists():
      data.update(json.loads(fixture.read_text()))
    data.update(changes)
    temporary = fixture.with_suffix(".new")
    temporary.write_text(json.dumps(data))
    temporary.replace(fixture)

  def emit(line="wlan0: device changed"):
    os.write(event_fd, (line + "\n").encode())

  write_state()
  with (root / "qs.log").open("w+") as log:
    process = subprocess.Popen(["qs", "-p", str(config)], env=environment, stdout=log, stderr=log)
    try:
      def call(method, *values):
        result = subprocess.run(["qs", "-p", str(config), "ipc", "call", "test", method, *values],
          env=environment, text=True, capture_output=True, timeout=5)
        if result.returncode:
          log.seek(0)
          raise AssertionError(result.stderr + log.read())
        return result.stdout

      def wait_for(predicate, timeout=5):
        deadline = time.monotonic() + timeout
        last = None
        while time.monotonic() < deadline:
          try:
            last = json.loads(call("snapshot"))
            if predicate(last): return last
          except AssertionError:
            if process.poll() is not None: raise
          time.sleep(0.05)
        log.seek(0)
        raise AssertionError("Wi-Fi state did not converge: " + json.dumps(last) + "\n" + log.read())

      wait_for(lambda s: True)
      call("open")
      wait_for(lambda s: s["ssid"] == "Alpha")

      if args.case in ("all", "connect"):
        call("connect", "Beta")
        wait_for(lambda s: s["connecting"] == "Beta")
        wait_for(lambda s: s["connecting"] == "" and s["ssid"] == "Beta")
        print("PASS: successful activation updates the connected row without reopening")
        write_state(fail=True)
        call("connect", "Alpha")
        wait_for(lambda s: s["connecting"] == "" and s["error"] == "Alpha")
        write_state(fail=False)
        print("PASS: failed activation clears CONNECTING and reports failure")

      if args.case in ("all", "live"):
        write_state(ssid="Alpha")
        emit()
        wait_for(lambda s: s["ssid"] == "Alpha")
        write_state(ssid="Beta", networks=[["Beta", 48], ["New network", 66]])
        emit()
        wait_for(lambda s: s["ssid"] == "Beta" and s["active"]["signal"] == 48)
        write_state(ssid="")
        emit()
        wait_for(lambda s: s["ssid"] == "" and s["active"] is None)
        write_state(radio=False)
        emit()
        wait_for(lambda s: not s["radio"] and not s["networks"] and s["active"] is None)
        write_state(radio=True, ssid="Beta")
        emit()
        wait_for(lambda s: s["radio"] and s["ssid"] == "Beta")
        write_state(networks=[["Beta", 31], ["New network", 66]])
        wait_for(lambda s: s["active"]["signal"] == 31)
        print("PASS: external switch/disconnect/radio changes and silent signal updates")

      if args.case in ("all", "parser"):
        name = "Office:50%\\Lab"
        write_state(ssid=name, networks=[[name, 70], [name, 90]])
        call("open")
        wait_for(lambda s: s["ssid"] == name and len(s["networks"]) == 1)
        parsed = json.loads(call("parse", 'RADIO|on\n*:Office\\:50%\\\\Lab:WPA2:70\n :Office\\:50%\\\\Lab:WPA2:90\n'))
        assert parsed["networks"] == [{"inUse": True, "ssid": "Office:50%\\Lab", "security": "WPA2", "signal": 70}], parsed
        print("PASS: escaped colon, percent and backslash SSIDs preserve identity and deduplicate")

      if args.case in ("all", "known"):
        write_state(ssid="", networks=[["Alpha", 60], ["Beta", 50]])
        emit("connections changed")
        wait_for(lambda s: len(s["saved"]) == 2)
        call("forget", "Beta")
        wait_for(lambda s: s["known"] == ["Alpha"])
        print("PASS: saved SSIDs are read from profiles even when profile names differ")

      if args.case == "all":
        call("password", "Beta", "temporary fixture password")
        write_state(networks=[["Beta", 21], ["Alpha", 42]])
        emit()
        wait_for(lambda s: any(n["signal"] == 21 for n in s["networks"]))
        snapshot = wait_for(lambda s: s["passwordField"] == "temporary fixture password")
        assert snapshot["password"] == snapshot["passwordField"]
        call("close")
        wait_for(lambda s: s["password"] == "")
        print("PASS: password entry survives a live list rebuild and clears on close")
        call("open")
        write_state(scan_delay=0.7, read_delay=0.2)
        call("refresh")
        write_state(radio=False)
        emit()
        wait_for(lambda s: not s["radio"] and not s["networks"] and not s["scanning"])
        time.sleep(0.4)
        assert not json.loads(call("snapshot"))["radio"], "Late scan restored stale radio state"
        write_state(radio=True, read_delay=0, scan_delay=0.05, scan_fail=True)
        emit()
        wait_for(lambda s: s["radio"])
        call("refresh")
        wait_for(lambda s: not s["scanning"])
        write_state(scan_fail=False)
        print("PASS: queued reads and late/failed scans preserve current state")
        emit("stop")
        time.sleep(1.3)
        write_state(ssid="Alpha")
        emit()
        wait_for(lambda s: s["ssid"] == "Alpha")
        call("reload")
        call("open")
        wait_for(lambda s: s["ssid"] == "Alpha")
        assert process.poll() is None
        log.seek(0)
        text = log.read()
        assert "ReferenceError" not in text and "TypeError" not in text, text
        invocations = [json.loads(line) for line in calls.read_text().splitlines()]
        assert all("--rescan" in command and command[command.index("--rescan") + 1] == "no"
          for command in invocations if "list" in command and "wifi" in command)
        print("PASS: watcher recovery and soft reload retain working live updates")
    finally:
      process.terminate()
      try:
        process.wait(timeout=5)
      except subprocess.TimeoutExpired:
        process.kill()
        process.wait()
      os.close(event_fd)
