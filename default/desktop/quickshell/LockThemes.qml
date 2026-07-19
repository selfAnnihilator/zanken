import QtQuick
import Quickshell
import Quickshell.Io

// Lists qylock themes from ~/.local/share/qylock/themes/.
// Marks the current theme (from ~/.config/qylock/theme) as active.
// Selection drives zanken-qylock-theme-set via parent activate().
Item {
    id: lockThemes

    required property bool active

    property var items: []
    property bool loaded: false
    readonly property bool running: probeProc.running

    function clear() {
        lockThemes.items = [];
        lockThemes.loaded = false;
    }

    function refresh() {
        probeProc.command = ["bash", "-c",
              "T=\"$HOME/.local/share/qylock/themes\"; "
            + "C=$(cat \"$HOME/.config/qylock/theme\" 2>/dev/null | tr -d '[:space:]'); "
            + "for d in \"$T\"/*/; do "
            + "  [ -d \"$d\" ] || continue; "
            + "  n=$(basename \"$d\"); "
            + "  if [ -f \"$d/Main.qml\" ]; then "
            + "    m=' '; [ \"$n\" = \"$C\" ] && m='*'; "
            + "    printf '===%s\\t%s\\n' \"$n\" \"$m\"; "
            + "  else "
            + "    for s in \"$d\"*/; do "
            + "      [ -d \"$s\" ] || continue; "
            + "      [ -f \"$s/Main.qml\" ] || continue; "
            + "      sn=\"$n/$(basename $s)\"; "
            + "      m=' '; [ \"$sn\" = \"$C\" ] && m='*'; "
            + "      printf '===%s\\t%s\\n' \"$sn\" \"$m\"; "
            + "    done; "
            + "  fi; "
            + "done"];
        probeProc.running = false;
        probeProc.running = true;
    }

    function ingest(text) {
        const chunks = (text || "").split("===");
        const out = [];
        for (let i = 0; i < chunks.length; i++) {
            const chunk = chunks[i];
            if (!chunk) continue;
            const nl = chunk.indexOf("\n");
            if (nl < 0) continue;
            const head = chunk.substring(0, nl);
            const parts = head.split("\t");
            const name = parts[0] || "";
            const marker = (parts[1] || " ").trim();
            if (!name) continue;
            const isActive = marker === "*";
            const kw = name + " lock theme lockscreen qylock sddm login"
                      + (isActive ? " active current" : "");
            out.push({
                title: name,
                category: isActive ? "ACTIVE" : "LOCK_THEME",
                keywords: kw,
                icon: isActive ? "󰌾" : "󰍁",
                exec: "",
                themeName: name,
                isLockTheme: true,
                isActive: isActive,
                swatches: [],
                rawCategory: false,
                _t: name.toLowerCase(),
                _k: kw.toLowerCase(),
                _c: "lock theme"
            });
        }
        out.sort((a, b) => {
            if (a.isActive !== b.isActive) return a.isActive ? -1 : 1;
            return a.title.localeCompare(b.title);
        });
        lockThemes.items = out;
        lockThemes.loaded = true;
    }

    onActiveChanged: { if (lockThemes.active) lockThemes.refresh(); }

    Component.onCompleted: lockThemes.refresh()

    Process {
        id: probeProc
        running: false
        command: ["true"]
        stdout: StdioCollector {
            onStreamFinished: { lockThemes.ingest(this.text || ""); }
        }
    }
}
