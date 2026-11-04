import QtQuick
import Quickshell.Io

// Refresh each time the picker opens; names stay argv values when activated.
Item {
  id: sessions

  required property bool active
  property var items: []
  property bool loaded: false
  property string error: ""
  readonly property bool running: probe.running

  function refresh() {
    sessions.loaded = false;
    sessions.error = "";
    probe.running = true;
  }

  onActiveChanged: {
    if (active) refresh();
    else {
      probe.running = false;
      sessions.items = [];
    }
  }

  Process {
    id: probe
    command: ["zanken-cmd-zellij-session", "list"]
    stdout: StdioCollector {
      onStreamFinished: {
        if (!sessions.active) return;
        try {
          const records = JSON.parse(this.text);
          sessions.items = records.map(function(record) {
            const status = record.window_id !== null ? "Focus window"
                         : record.saved ? "Restore saved session" : "Open in new window";
            return {
              title: record.name,
              category: status,
              rawCategory: true,
              icon: "",
              exec: "",
              isZellijSession: true,
              sessionName: record.name,
              _t: record.name.toLowerCase(),
              _k: "zellij terminal workspace session " + status.toLowerCase(),
              _c: status.toLowerCase()
            };
          });
        } catch (error) {
          sessions.items = [];
          sessions.error = "COULD NOT LOAD SESSIONS";
        }
        sessions.loaded = true;
      }
    }
    onExited: function(code, status) {
      if (sessions.active && (code !== 0 || status !== 0)) {
        sessions.error = "COULD NOT LOAD SESSIONS";
        sessions.loaded = true;
      }
    }
  }
}
