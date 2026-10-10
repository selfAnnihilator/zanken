import QtQuick
import QtCore
import Quickshell.Io

// Qt's Wayland clipboard only receives updates while a shell window has
// focus. Data-control watches the regular clipboard without taking focus.
Item {
  id: history

  property string storePath: StandardPaths.writableLocation(StandardPaths.CacheLocation) + "/qs-clipboard.json"
  property int maxItems: 750
  property var entries: []

  function save() {
    store.setText(JSON.stringify(entries));
  }

  function record(text) {
    if (!text || text.trim().length === 0) return;
    const remaining = entries.filter(function(item) { return item.content !== text; });
    entries = [{content: text, time: Date.now()}].concat(remaining).slice(0, maxItems);
    save();
  }

  function clear() {
    entries = [];
    save();
  }

  function remove(index) {
    entries = entries.filter(function(item, i) { return i !== index; });
    save();
  }

  FileView {
    id: store
    path: history.storePath
    blockLoading: true
  }

  Process {
    id: watcher
    command: ["wl-paste", "--type", "text", "--watch", "bash", "-c",
      "if [[ ${CLIPBOARD_STATE:-data} == \"data\" ]]; then jq -Rsc .; fi"]
    stdout: SplitParser {
      onRead: line => {
        try {
          const text = JSON.parse(line);
          if (typeof text === "string") history.record(text);
        } catch (error) {
          console.warn("Clipboard history: invalid watcher event", error);
        }
      }
    }
    onExited: retry.restart()
  }

  Timer {
    id: retry
    interval: 1000
    onTriggered: watcher.running = true
  }

  Component.onCompleted: {
    try {
      const saved = JSON.parse(store.text() || "[]");
      if (Array.isArray(saved)) {
        entries = saved.filter(function(item) {
          return item && typeof item.content === "string";
        }).slice(0, maxItems);
      }
    } catch (error) {
      console.warn("Clipboard history: could not load saved entries", error);
    }
    watcher.running = true;
  }
}
