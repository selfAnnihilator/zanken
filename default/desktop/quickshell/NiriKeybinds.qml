import QtQuick
import Quickshell
import Quickshell.Io
import "Data.js" as Data

// Reads ~/.config/niri/config.kdl and exposes the binds section as a flat
// list of searchable items for the OmniMenu keybind drill-down.
// Activated on entry, cleared on exit — same lifecycle as Processes/Themes.
Item {
    id: keybinds

    required property bool active

    property var items: []
    readonly property bool running: parseProc.running

    function clear() { keybinds.items = []; }

    function refresh() {
        const cfg = Quickshell.env("HOME") + "/.config/niri/config.kdl";
        parseProc.command = ["zanken-niri-keybindings", "--print-tsv", cfg];
        parseProc.running = false;
        parseProc.running = true;
    }

    function ingest(text) {
        const lines = text.split("\n");
        const out = [];
        for (let i = 0; i < lines.length; i++) {
            const ln = lines[i];
            if (!ln.trim()) continue;
            const parts = ln.split("\t");
            if (parts.length < 2) continue;
            const key     = parts[0] || "";
            const action  = parts[1] || "";
            const section = parts[2] || "";
            const kw = (key + " " + action + " " + section).toLowerCase();
            out.push({
                title:       key,
                category:    section || action,
                icon:        "󰌌",
                exec:        "",
                keywords:    kw,
                isKeybind:   true,
                rawCategory: true,
                _t: key.toLowerCase(),
                _k: kw,
                _c: (section || action).toLowerCase()
            });
        }
        keybinds.items = out;
    }

    onActiveChanged: {
        if (keybinds.active) keybinds.refresh();
        else keybinds.clear();
    }

    Process {
        id: parseProc
        running: false
        command: ["true"]
        stdout: StdioCollector {
            onStreamFinished: keybinds.ingest(this.text || "")
        }
    }
}
