#!/usr/bin/env bash
# Install Hollow Knight Hornet cursor theme (converts Windows .ani → X11 xcursor)

THEME_DIR="$HOME/.local/share/icons/Hornet"
CURSORS_DIR="$THEME_DIR/cursors"
ZIP_SRC="$OMARCHY_PATH/default/cursors/hornet.zip"
TMP_DIR="$(mktemp -d)"

mkdir -p "$CURSORS_DIR"

# Extract and convert .ani files
unzip -q "$ZIP_SRC" -d "$TMP_DIR"
for f in "$TMP_DIR"/*.ani; do
  win2xcur "$f" -o "$CURSORS_DIR/"
done
rm -rf "$TMP_DIR"

# Write theme metadata
cat > "$THEME_DIR/cursor.theme" <<'EOF'
[Icon Theme]
Name=Hornet
Comment=Hollow Knight - Hornet Cursor
EOF

# Create X11 cursor name symlinks
python3 - <<'PYEOF'
import os

cursors_dir = os.path.expanduser("~/.local/share/icons/Hornet/cursors")
os.chdir(cursors_dir)

mapping = {
    "Hornet normal": [
        "default", "left_ptr", "arrow", "top_left_arrow",
    ],
    "Hornet help": [
        "help", "question_arrow", "d9ce0ab604afda186df5a78083fe3b12",
    ],
    "Hornet work": [
        "progress", "left_ptr_watch",
        "08e8e1c95fe2fc01f976f1e063a24ccd",
        "3ecb610c1bf2410f44200f48c566dbfa",
    ],
    "Hornet busy": [
        "wait", "watch",
    ],
    "Hornet text": [
        "text", "xterm", "ibeam",
    ],
    "Hornet unavailable": [
        "not-allowed", "crossed_circle", "no-drop", "circle",
        "03b6e0fcb3499374a867c041f52298f0",
    ],
    "Hornet vert": [
        "ns-resize", "size_ver", "n-resize", "s-resize", "col-resize",
        "00008160000006810000408080010102",
    ],
    "Hornet horz": [
        "ew-resize", "size_hor", "e-resize", "w-resize", "row-resize",
        "028006030e0e7ebffc7f7070c0600140",
    ],
    "Hornet dgn1": [
        "nwse-resize", "size_fdiag", "nw-resize", "se-resize",
        "c7088f0f3e6c8088236ef8e1e3e70000",
    ],
    "Hornet dgn2": [
        "nesw-resize", "size_bdiag", "ne-resize", "sw-resize",
        "fcf1c3c7cd4491d801f1e1c78f100000",
    ],
    "Hornet move": [
        "all-scroll", "fleur", "move",
    ],
    "Hornet link": [
        "alias", "dnd-link", "3085a0e285430894940527032f8b26df",
    ],
    "Hornet precision": [
        "crosshair", "cross",
    ],
    "Hornet hand": [
        "pointer", "hand2", "hand1", "pointing_hand",
        "e29285e634086352946a0e7090d73106",
    ],
    "Hornet alt": [
        "copy", "dnd-copy",
    ],
    "Hornet location": [
        "cell", "plus",
    ],
    "Hornet person": [
        "context-menu",
    ],
}

for target, names in mapping.items():
    for name in names:
        if os.path.exists(name):
            os.remove(name)
        os.symlink(target, name)
PYEOF
