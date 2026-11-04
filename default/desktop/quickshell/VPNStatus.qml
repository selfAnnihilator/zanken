import QtQuick
import QtCore
import Quickshell.Io

// Optional local VPN controller. Commands are argv arrays, never shell text.
Item {
  id: vpn
  property var statusCommand: []
  property var verifyCommand: []
  property var openCommand: []
  property var closeCommand: []
  property bool nativeTray: false
  property string backgroundStatePath: ""
  readonly property bool backgroundClosed: {
    if (!backgroundStatePath) return nativeTray;
    try { return JSON.parse(backgroundState.text()).closed === true; }
    catch (error) { return nativeTray; }
  }
  property string closeError: ""
  readonly property bool closing: closer.running
  readonly property bool backgroundActive: enabled && !backgroundClosed
  property string state: "disabled"
  property string uplinkKind: "none"
  property var connection: ({})
  readonly property string connectionLabel: connection.display_name || "VPN"
  property real lastStatus: 0
  readonly property bool enabled: statusCommand.length > 0
  readonly property bool isProtected: backgroundActive && state === "connected"
  readonly property bool needsAttention: backgroundActive && state !== "connected" && state !== "disconnected"
  readonly property string description: closeError || ({
    connected: "VPN protected · " + connectionLabel,
    disconnected: "VPN off · regular internet",
    paused: "Internet paused · VPN guard on",
    checking: "VPN checking · not yet verified",
    unverified: "VPN not verified · open controls",
    unprotected: "VPN protection incomplete · open controls",
    unavailable: "VPN status unavailable · open controls"
  })[state] || "VPN status unavailable"

  function poll() {
    if (backgroundActive && !statusProbe.running) statusProbe.running = true;
  }

  function open() {
    if (openCommand.length > 0 && !launcher.running) launcher.running = true;
  }

  function closeCompletely() {
    if (closeCommand.length > 0 && !closer.running) {
      closeError = "";
      closer.running = true;
    }
  }

  onBackgroundActiveChanged: {
    closeError = "";
    lastStatus = 0;
    if (backgroundActive) {
      state = "checking";
      poll();
      if (verifyCommand.length > 0 && !verifyProbe.running) verifyProbe.running = true;
    } else {
      statusProbe.running = false;
      verifyProbe.running = false;
      state = enabled ? "disconnected" : "disabled";
    }
  }

  // A session-local marker allows closing the VPN monitor without closing
  // Quickshell. Opening the controls clears it and resumes monitoring.
  FileView {
    id: backgroundState
    path: vpn.backgroundStatePath
    printErrors: false
    preload: true
    watchChanges: true
    onFileChanged: reload()
  }

  FileView {
    id: settings
    path: StandardPaths.writableLocation(StandardPaths.ConfigLocation) + "/zanken/vpn-status.json"
    printErrors: false
    watchChanges: true
    onFileChanged: reload()
    onLoaded: {
      try {
        const config = JSON.parse(settings.text());
        vpn.nativeTray = config.nativeTray === true;
        vpn.backgroundStatePath = typeof config.backgroundStatePath === "string" ? config.backgroundStatePath : "";
        vpn.statusCommand = Array.isArray(config.statusCommand) ? config.statusCommand : [];
        vpn.verifyCommand = Array.isArray(config.verifyCommand) ? config.verifyCommand : [];
        vpn.openCommand = Array.isArray(config.openCommand) ? config.openCommand : [];
        vpn.closeCommand = Array.isArray(config.closeCommand) ? config.closeCommand : [];
        vpn.state = vpn.backgroundActive ? "checking" : vpn.enabled ? "disconnected" : "disabled";
        vpn.poll();
        if (vpn.backgroundActive && vpn.verifyCommand.length > 0 && !verifyProbe.running) verifyProbe.running = true;
      } catch (error) {
        vpn.state = "unavailable";
      }
    }
    onLoadFailed: {
      vpn.statusCommand = [];
      vpn.verifyCommand = [];
      vpn.openCommand = [];
      vpn.closeCommand = [];
      vpn.nativeTray = false;
      vpn.backgroundStatePath = "";
      vpn.state = "disabled";
    }
  }

  Process {
    id: statusProbe
    command: vpn.statusCommand
    stdout: StdioCollector { id: statusOutput }
    onExited: (code, status) => {
      if (!vpn.backgroundActive) return;
      try {
        if (code !== 0) throw new Error("status failed");
        const result = JSON.parse(statusOutput.text);
        vpn.state = result.state;
        vpn.uplinkKind = result.uplink_kind || "none";
        vpn.connection = result.connection || {};
        vpn.lastStatus = Date.now();
      } catch (error) {
        vpn.state = "unavailable";
      }
    }
  }

  // The fast local check never waits for a website. The separate verifier
  // updates a short-lived proof cache even when the controls window is closed.
  Process {
    id: verifyProbe
    command: vpn.verifyCommand
    stdout: StdioCollector {}
    onExited: vpn.poll()
  }
  Process { id: launcher; command: vpn.openCommand }
  Process {
    id: closer
    command: vpn.closeCommand
    onExited: (code, status) => {
      if (code !== 0) vpn.closeError = "Could not close VPN controls · open controls and Disconnect to retry";
      vpn.poll();
    }
  }
  Timer {
    interval: 2000; repeat: true; running: vpn.backgroundActive
    onTriggered: {
      if (vpn.lastStatus > 0 && Date.now() - vpn.lastStatus > 5000) vpn.state = "unavailable";
      vpn.poll();
    }
  }
  Timer {
    interval: 20000; repeat: true; running: vpn.backgroundActive && vpn.verifyCommand.length > 0
    onTriggered: if (!verifyProbe.running) verifyProbe.running = true
  }
}
