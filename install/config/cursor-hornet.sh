#!/bin/bash
# Install Hollow Knight Hornet cursor theme (converts Windows .ani → X11 xcursor)

THEME_DIR="$HOME/.local/share/icons/Hornet"
CURSORS_DIR="$THEME_DIR/cursors"
ZIP_SRC="$ZANKEN_PATH/default/cursors/hornet.zip"

mkdir -p "$CURSORS_DIR"

# Extract and convert .ani files using Python (no unzip/win2xcur dependency issues)
python3 - "$ZIP_SRC" "$CURSORS_DIR" <<'PYEOF'
import sys, os, zipfile, struct, subprocess, tempfile

zip_src, cursors_dir = sys.argv[1], sys.argv[2]

if not os.path.exists(zip_src):
    print(f"cursor-hornet: zip not found: {zip_src}", file=sys.stderr)
    sys.exit(1)

if not subprocess.run(["which", "win2xcur"], capture_output=True).returncode == 0:
    print("cursor-hornet: win2xcur not found, skipping conversion", file=sys.stderr)
    sys.exit(1)

with tempfile.TemporaryDirectory() as tmp:
    with zipfile.ZipFile(zip_src) as zf:
        zf.extractall(tmp)
    for root, dirs, files in os.walk(tmp):
        for fname in files:
            if fname.lower().endswith(".ani"):
                fpath = os.path.join(root, fname)
                subprocess.run(["win2xcur", fpath, "-o", cursors_dir], check=True)

# Write theme metadata
theme_dir = os.path.dirname(cursors_dir)
with open(os.path.join(theme_dir, "cursor.theme"), "w") as f:
    f.write("[Icon Theme]\nName=Hornet\nComment=Hollow Knight - Hornet Cursor\n")

# Create X11 cursor name symlinks (use lexists to handle broken symlinks from prior runs)
os.chdir(cursors_dir)

mapping = {
    "Hornet normal": ["default", "left_ptr", "arrow", "top_left_arrow"],
    "Hornet help": ["help", "question_arrow", "d9ce0ab604afda186df5a78083fe3b12"],
    "Hornet work": ["progress", "left_ptr_watch",
                    "08e8e1c95fe2fc01f976f1e063a24ccd", "3ecb610c1bf2410f44200f48c566dbfa"],
    "Hornet busy": ["wait", "watch"],
    "Hornet text": ["text", "xterm", "ibeam"],
    "Hornet unavailable": ["not-allowed", "crossed_circle", "no-drop", "circle",
                           "03b6e0fcb3499374a867c041f52298f0"],
    "Hornet vert": ["ns-resize", "size_ver", "n-resize", "s-resize", "col-resize",
                    "00008160000006810000408080010102"],
    "Hornet horz": ["ew-resize", "size_hor", "e-resize", "w-resize", "row-resize",
                    "028006030e0e7ebffc7f7070c0600140"],
    "Hornet dgn1": ["nwse-resize", "size_fdiag", "nw-resize", "se-resize",
                    "c7088f0f3e6c8088236ef8e1e3e70000"],
    "Hornet dgn2": ["nesw-resize", "size_bdiag", "ne-resize", "sw-resize",
                    "fcf1c3c7cd4491d801f1e1c78f100000"],
    "Hornet move": ["all-scroll", "fleur", "move"],
    "Hornet link": ["alias", "dnd-link", "3085a0e285430894940527032f8b26df"],
    "Hornet precision": ["crosshair", "cross"],
    "Hornet hand": ["pointer", "hand2", "hand1", "pointing_hand",
                    "e29285e634086352946a0e7090d73106"],
    "Hornet alt": ["copy", "dnd-copy"],
    "Hornet location": ["cell", "plus"],
    "Hornet person": ["context-menu"],
}

for target, names in mapping.items():
    for name in names:
        if os.path.lexists(name):
            os.remove(name)
        os.symlink(target, name)

print("cursor-hornet: done")
PYEOF

# Set Hornet as active cursor theme in GTK3, GTK4, and ~/.icons/default
mkdir -p "$HOME/.config/gtk-3.0"
if [ -f "$HOME/.config/gtk-3.0/settings.ini" ]; then
    sed -i 's/^gtk-cursor-theme-name=.*/gtk-cursor-theme-name=Hornet/' "$HOME/.config/gtk-3.0/settings.ini"
else
    printf '[Settings]\ngtk-cursor-theme-name=Hornet\ngtk-cursor-theme-size=24\n' > "$HOME/.config/gtk-3.0/settings.ini"
fi

mkdir -p "$HOME/.config/gtk-4.0"
if [ -f "$HOME/.config/gtk-4.0/settings.ini" ]; then
    sed -i 's/^gtk-cursor-theme-name=.*/gtk-cursor-theme-name=Hornet/' "$HOME/.config/gtk-4.0/settings.ini"
    grep -q 'gtk-cursor-theme-size' "$HOME/.config/gtk-4.0/settings.ini" || sed -i '/gtk-cursor-theme-name/a gtk-cursor-theme-size=24' "$HOME/.config/gtk-4.0/settings.ini"
else
    printf '[Settings]\ngtk-cursor-theme-name=Hornet\ngtk-cursor-theme-size=24\n' > "$HOME/.config/gtk-4.0/settings.ini"
fi

mkdir -p "$HOME/.icons/default"
cat > "$HOME/.icons/default/index.theme" <<'EOF'
[Icon Theme]
Name=Default
Comment=Default cursor theme
Inherits=Hornet
EOF

if [[ ${ZANKEN_INSTALL_MODE:-full} != "desktop" ]]; then
  gsettings set org.gnome.desktop.interface cursor-theme Hornet 2>/dev/null || true
  gsettings set org.gnome.desktop.interface cursor-size 24 2>/dev/null || true
fi

# libXcursor searches ~/.icons, not ~/.local/share/icons — symlink so it finds the theme
mkdir -p "$HOME/.icons"
ln -snf "$HOME/.local/share/icons/Hornet" "$HOME/.icons/Hornet"
