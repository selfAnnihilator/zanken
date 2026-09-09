//@ pragma UseQApplication
import QtQuick
import Quickshell
import Quickshell.Io

// Combined entry point: one Quickshell process hosting both the navbar and
// the omni-menu command palette. Both share the same Theme instance, so an
// zanken theme swap propagates atomically to bar + popups + palette.
//
// Launch with:
//   qs -n -d -c zanken
//
// Toggle the palette from a Hyprland keybind. The shell registers
// GlobalShortcut entries so the keypress is delivered to the running
// process directly (no `qs` client fork on the hot path):
//   bind = SUPER, SPACE, global, quickshell:palette-toggle
//   bind = ALT,   SPACE, global, quickshell:palette-quick
ShellRoot {
    id: root

    Theme { id: theme }

    Navbar {
        id: nav
        theme: theme
        onPaletteToggleRequested: omni.toggle()
        onPaletteOpenCategoryRequested: function(cat) { omni.open(); omni.categoryFilter = cat; }
        onPaletteOpenQuickTileRequested: function(key) { omni.openQuickTile(key) }
    }
    OmniMenu { id: omni; theme: theme; navbar: nav }
    NotificationsPopup { root: nav }
    NotificationToast  { root: nav }
    ClipboardPopup     { root: nav }
    TrayPopup          { root: nav }

    // A soft reload preserves the Quickshell process and its service
    // connections. In particular, it avoids disconnecting browser MPRIS
    // players, which can make YouTube advance a paused video.
    IpcHandler {
        target: "zanken"
        function releaseIdentity(): string {
            return "ZANKEN_SOURCE_GENERATION";
        }
        function reload(): void {
            Quickshell.reload(false);
        }
    }
}
