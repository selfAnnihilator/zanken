.pragma library

// Sentinel values for the search/state drills.
const fileCategory = "Files";
const ghCategory = "GitHub";
const favCategory = "Favourites";
const histCategory = "History";
const procCategory = "Processes";
const themeCategory = "Themes";
const lockThemeCategory = "Lock Theme";
const keybindCategory = "Keybinds";

// fd already respects .gitignore, the global ignore file, and skips
// hidden files by default. These excludes catch build dirs that
// aren't always gitignored.
const fdExcludes = [
    "node_modules", "target", "dist", "build", ".cache",
    ".venv", "__pycache__", ".tox", ".next", ".nuxt"
];

const imageExts = [
    "png", "jpg", "jpeg", "webp", "gif", "bmp", "ico", "avif", "svg"
];

const textExts = [
    "md", "txt", "qml", "lua", "toml", "sh", "bash", "zsh", "fish",
    "py", "js", "mjs", "cjs", "ts", "tsx", "jsx", "json", "jsonc",
    "yaml", "yml", "rs", "go", "c", "h", "cpp", "hpp", "cc", "hh",
    "html", "css", "scss", "conf", "ini", "cfg", "log", "csv", "xml",
    "rb", "java", "kt", "swift", "php", "sql", "vim", "el", "tex",
    "gitignore", "gitconfig", "dockerfile", "makefile", "env"
];

const fileIcons = {
    "png": "󰋩", "jpg": "󰋩", "jpeg": "󰋩", "webp": "󰋩", "gif": "󰋩",
    "bmp": "󰋩", "ico": "󰋩", "avif": "󰋩", "svg": "󰜡", "tiff": "󰋩",
    "mp4": "󰕧", "mkv": "󰕧", "webm": "󰕧", "mov": "󰕧", "avi": "󰕧",
    "m4v": "󰕧", "flv": "󰕧",
    "mp3": "󰝚", "flac": "󰝚", "ogg": "󰝚", "wav": "󰝚", "m4a": "󰝚",
    "opus": "󰝚", "aac": "󰝚",
    "pdf": "󰈦", "epub": "󰂺", "djvu": "󰈦",
    "doc": "󰈬", "docx": "󰈬", "odt": "󰈬", "rtf": "󰈬",
    "xls": "󰈛", "xlsx": "󰈛", "ods": "󰈛",
    "ppt": "󰈧", "pptx": "󰈧", "odp": "󰈧",
    "zip": "󰗄", "tar": "󰗄", "gz": "󰗄", "xz": "󰗄", "bz2": "󰗄",
    "7z": "󰗄", "rar": "󰗄", "zst": "󰗄",
    "md": "󰍔", "txt": "󰈙", "log": "󰦪", "csv": "󰈛",
    "json": "󰘦", "jsonc": "󰘦", "yaml": "󰈙", "yml": "󰈙",
    "toml": "󰈙", "xml": "󰗀", "ini": "󰒓", "cfg": "󰒓",
    "conf": "󰒓", "env": "󰒓",
    "sh": "󱆃", "bash": "󱆃", "zsh": "󱆃", "fish": "󰈺",
    "lua": "󰢱", "vim": "",
    "html": "󰌝", "css": "󰌜", "scss": "󰌜", "sass": "󰌜",
    "py": "󰌠", "js": "󰌞", "mjs": "󰌞", "cjs": "󰌞",
    "ts": "󰛦", "tsx": "󰜈", "jsx": "󰜈",
    "rs": "󱘗", "go": "󰟓", "java": "󰬷", "kt": "󱈙",
    "swift": "󰛥", "rb": "󰴭", "php": "󰌟",
    "c": "󰙱", "h": "󰙱", "cpp": "󰙲", "hpp": "󰙲", "cc": "󰙲", "hh": "󰙲",
    "qml": "󰢫", "sql": "󰆼", "el": "", "tex": "",
    // Dotless filenames: fileExt() returns the whole lowercased name.
    "gitignore": "", "gitconfig": "",
    "dockerfile": "󰡨", "makefile": "󰣪"
};

// Synthetic rows at root level. Activating one sets the categoryFilter
// instead of executing a command. `target` matches against item.category;
// "App" is the bucket all .desktop entries land in. fileCategory and
// ghCategory route to their respective search drills.
const categoryNav = [
    { title: "Quick",   icon: "󱎫", category: "Browse", isCategory: true, target: "Quick",       keywords: "quick settings panel tray toggle popup display weather calendar aether screenshots videos brightness volume mute" },
    { title: "Apps",    icon: "󰀻", category: "Browse", isCategory: true, target: "App",         keywords: "apps applications launcher programs software desktop" },
    { title: "Files",   icon: "󰉋", category: "Browse", isCategory: true, target: fileCategory,  keywords: "files file search find folder browse path open image picture document text fd" },
    { title: "GitHub",  icon: "󰊤", category: "Browse", isCategory: true, target: ghCategory,    keywords: "github gh repo repository search code clone star issue pull request pr open source git" },
    { title: "Favourites", icon: "󰓎", category: "Browse", isCategory: true, target: favCategory,  keywords: "favourites favorites favs starred pinned bookmarks marked" },
    { title: "Style",   icon: "󰏘", category: "Browse", isCategory: true, target: "Style",       keywords: "style theme appearance look font background corners waybar screensaver" },
    { title: "Setup",   icon: "󰒓", category: "Browse", isCategory: true, target: "Setup",       keywords: "setup config audio wifi bluetooth power monitors keybindings defaults dns security" },
{ title: "System",  icon: "󰐥", category: "Browse", isCategory: true, target: "System",      keywords: "system lock suspend hibernate logout restart reboot shutdown power" },
    { title: "Trigger", icon: "󰚥", category: "Browse", isCategory: true, target: "Trigger",     keywords: "trigger reminder transcode capture share toggle hardware" },
    { title: "Capture", icon: "󰄀", category: "Browse", isCategory: true, target: "Capture",     keywords: "capture screenshot screenrecord ocr text extraction color picker" },
    { title: "Learn",   icon: "󰂺", category: "Browse", isCategory: true, target: "Learn",       keywords: "learn docs manual help keybindings wiki cheatsheet" },
    { title: "Processes", icon: "󰍛", category: "Browse", isCategory: true, target: procCategory,     keywords: "processes process kill task manager ps top htop activity cpu memory" },
    { title: "Themes",    icon: "󰸌", category: "Browse", isCategory: true, target: themeCategory,        keywords: "themes theme palette color swatch switcher dark light apply" },
    { title: "Lock Theme", icon: "󰌾", category: "Browse", isCategory: true, target: lockThemeCategory, keywords: "lock theme qylock sddm lockscreen login pixel anime" },
    { title: "Keybindings", icon: "󰌌", category: "Browse", isCategory: true, target: keybindCategory,  keywords: "keybindings shortcuts hotkeys super niri binds reference cheatsheet" },
    { title: "Update",    icon: "󰚰", category: "Browse", isCategory: true, target: "Update",       keywords: "update sync zanken git pull upgrade packages install" }
];

// Every leaf action zanken-menu can dispatch is flattened here with a
// synonym list so search hits non-obvious terms. `exec` is the bash run
// verbatim; `tui` (when set) is the wrapper command name that prefixes
// exec so the launch lands in a real terminal.
const zankenItems = [
    // ----- Quick -----
    // Mirrors the standalone QuickSettings sheet's targets: popup togglers
    // and one-shot device toggles. Reached as a drill-down (Quick) or by
    // typing the action name; Alt+Space binds straight into this category.
    { title: "Display",          icon: "󰍹", category: "Quick", keywords: "display monitor brightness warmth gamma night light blue temperature dim screen",       exec: "qs -c zanken ipc call display toggle" },
    { title: "Weather",          icon: "󰖐", category: "Quick", keywords: "weather forecast temperature wttr rain sun wind humidity uv sunrise sunset outdoor",    exec: "qs -c zanken ipc call weather toggle" },
    { title: "Calendar",         icon: "󰃭", category: "Quick", keywords: "calendar date month day today schedule planner agenda holidays",                       exec: "qs -c zanken ipc call calendar toggle" },
    { title: "Aether Themes",    icon: "󰏘", category: "Quick", keywords: "aether theme blueprint palette swatch picker wallpaper generate",                      exec: "qs -c zanken ipc call aether toggle" },
    { title: "Screenshots",      icon: "󰄀", category: "Quick", keywords: "screenshots shots browse pictures captures images recent gallery",                      exec: "qs -c zanken ipc call screenshots toggle" },
    { title: "Videos",           icon: "󰟞", category: "Quick", keywords: "videos films clips recordings recent browse gallery library",                          exec: "qs -c zanken ipc call videos toggle" },
    { title: "Mute Audio",       icon: "󰝟", category: "Quick", keywords: "mute audio unmute silence toggle volume sound speaker pamixer quick",                  exec: "pamixer -t" },
    { title: "Reset Display",    icon: "󰜉", category: "Quick", keywords: "reset display brightness warmth gamma default daylight identity full restore",          exec: "qs -c zanken ipc call display reset" },
    { title: "Blank Screen",     icon: "󰹐", category: "Quick", keywords: "blank screen off dpms suspend display monitor sleep dark",                              exec: "qs -c zanken ipc call display blank" },
    { title: "Refresh Weather",  icon: "󰜉", category: "Quick", keywords: "weather refresh reload update wttr fetch",                                              exec: "qs -c zanken ipc call weather refresh" },
    { title: "Audio Mixer",      icon: "󰕾", category: "Quick", keywords: "audio mixer pavucontrol pipewire pulse volume sink source device level",                exec: "zanken-launch-audio" },
    { title: "Wi-Fi Picker",     icon: "󰖩", category: "Quick", keywords: "wifi wireless network connect picker chooser ssid signal nmcli",                       exec: "zanken-launch-wifi" },
    { title: "Bluetooth Picker", icon: "󰂯", category: "Quick", keywords: "bluetooth bt pair connect device picker headset speaker keyboard mouse",                exec: "zanken-launch-bluetooth" },
    { title: "System Monitor",   icon: "󰍛", category: "Quick", keywords: "cpu memory process monitor btop top htop performance load activity",                   exec: "zanken-launch-or-focus-tui btop" },

    // ----- Style -----
    { title: "Theme",            icon: "󰸌", category: "Style",   keywords: "theme color palette dark light mode appearance look style scheme switcher kanagawa tokyo dragon nord gruvbox", exec: "qs -c zanken ipc call palette openCategory \"Themes\"" },
    { title: "Background",       icon: "󰸉", category: "Style",   keywords: "background wallpaper image desktop picture backdrop bg",                                                 exec: "zanken-theme-bg-switcher" },
    { title: "Font",             icon: "󰛖", category: "Style",   keywords: "font typeface monospace typography family character glyph nerd",                                        exec: "zanken-font-pick", tui: "zanken-launch-tui" },
    { title: "Round Corners",    icon: "󰘇", category: "Style",   keywords: "corners radius round soft rounded border edge shape navbar cloud popup",                              exec: "qs -c zanken ipc call corners round" },
    { title: "Sharp Corners",    icon: "󰝣", category: "Style",   keywords: "corners radius sharp square hard flat border edge shape navbar slab popup",                            exec: "qs -c zanken ipc call corners sharp" },

    // ----- Setup -----
{ title: "Enable Hibernate",     icon: "󰤁", category: "Setup",   keywords: "hibernate enable setup swap sleep power disk s4",                                                  exec: "zanken-hibernation-setup",  tui: "zanken-launch-floating-terminal-with-presentation" },
    { title: "Disable Hibernate",    icon: "󰤁", category: "Setup",   keywords: "hibernate disable remove swap sleep power",                                                             exec: "zanken-hibernation-remove", tui: "zanken-launch-floating-terminal-with-presentation" },
    { title: "Niri Config",          icon: "󰢨", category: "Setup",   keywords: "niri compositor config window manager kdl edit settings",                                              exec: "zanken-launch-editor ~/.config/niri/config.kdl" },
    { title: "Default: Qutebrowser", icon: "󰖟", category: "Setup",   keywords: "default browser set qutebrowser keyboard vim",                                                             exec: "zanken-default-browser qutebrowser" },
    { title: "Default: Chrome",      icon: "󰊯", category: "Setup",   keywords: "default browser set chrome google chromium",                                                           exec: "zanken-default-browser chrome" },
    { title: "Default: Brave",       icon: "󰖟", category: "Setup",   keywords: "default browser set brave",                                                                            exec: "zanken-default-browser brave" },
    { title: "Default: Firefox",     icon: "󰈹", category: "Setup",   keywords: "default browser set firefox",                                                                          exec: "zanken-default-browser firefox" },
    { title: "Default: Edge",        icon: "󰇩", category: "Setup",   keywords: "default browser set edge microsoft",                                                                   exec: "zanken-default-browser edge" },
    { title: "Default: Zen",         icon: "󰖟", category: "Setup",   keywords: "default browser set zen",                                                                              exec: "zanken-default-browser zen" },
    { title: "Default: Alacritty",   icon: "󰆍", category: "Setup",   keywords: "default terminal set alacritty",                                                                       exec: "zanken-default-terminal alacritty" },
    { title: "Default: Ghostty",     icon: "󰆍", category: "Setup",   keywords: "default terminal set ghostty",                                                                         exec: "zanken-default-terminal ghostty" },
    { title: "Default: Kitty",       icon: "󰆍", category: "Setup",   keywords: "default terminal set kitty",                                                                           exec: "zanken-default-terminal kitty" },
    { title: "Default: Foot",        icon: "󰆍", category: "Setup",   keywords: "default terminal set foot",                                                                            exec: "zanken-default-terminal foot" },
    { title: "Default: Neovim",      icon: "󰕷", category: "Setup",   keywords: "default editor set neovim nvim",                                                                       exec: "zanken-default-editor nvim" },
    { title: "Default: VSCode",      icon: "󱩼", category: "Setup",   keywords: "default editor set vscode visual studio code",                                                         exec: "zanken-default-editor code" },
    { title: "Default: Cursor",      icon: "󱩼", category: "Setup",   keywords: "default editor set cursor ai ide",                                                                     exec: "zanken-default-editor cursor" },
    { title: "Default: Zed",         icon: "󱩼", category: "Setup",   keywords: "default editor set zed fast",                                                                          exec: "zanken-default-editor zeditor" },
    { title: "Default: Helix",       icon: "󱩼", category: "Setup",   keywords: "default editor set helix hx modal",                                                                    exec: "zanken-default-editor helix" },
    { title: "DNS",              icon: "󰱔", category: "Setup",   keywords: "dns resolver network domain server nameserver",                                                       exec: "zanken-setup-dns",                  tui: "zanken-launch-floating-terminal-with-presentation" },
    { title: "Fingerprint",      icon: "󰈷", category: "Setup",   keywords: "fingerprint biometric security login auth fingerprint reader",                                         exec: "zanken-setup-security-fingerprint", tui: "zanken-launch-floating-terminal-with-presentation" },
    { title: "Fido2 Key",        icon: "󰌆", category: "Setup",   keywords: "fido2 yubikey hardware key security 2fa auth",                                                          exec: "zanken-setup-security-fido2",       tui: "zanken-launch-floating-terminal-with-presentation" },
    { title: "XCompose",         icon: "󰞅", category: "Setup",   keywords: "xcompose compose key special characters accents typing emoji input",                                  exec: "zanken-launch-editor ~/.XCompose" },

    // ----- System -----
    { title: "Lock Screen",         icon: "󰌾", category: "System", keywords: "lock screen security hyprlock password",                                            exec: "zanken-system-lock" },
    { title: "Force Screensaver",   icon: "󱄄", category: "System", keywords: "screensaver force start show idle",                                              exec: "zanken-launch-screensaver force" },
    { title: "Suspend",             icon: "󰒲", category: "System", keywords: "suspend sleep power down ram s3",                                                 exec: "systemctl suspend" },
    { title: "Hibernate",           icon: "󰤁", category: "System", keywords: "hibernate disk power down s4 swap",                                               exec: "systemctl hibernate" },
    { title: "Logout",              icon: "󰍃", category: "System", keywords: "logout signout exit session end",                                                  exec: "zanken-system-logout" },
    { title: "Restart Computer",    icon: "󰜉", category: "System", keywords: "restart reboot reset power cycle",                                                exec: "zanken-system-reboot" },
    { title: "Shutdown",            icon: "󰐥", category: "System", keywords: "shutdown poweroff off halt turn off",                                              exec: "zanken-system-shutdown" },

    // ----- Capture -----
    { title: "Screenshot",          icon: "󰄀", category: "Capture", keywords: "screenshot screen capture image png shot snip print",                              exec: "zanken-capture-screenshot" },
    { title: "Screen Record",       icon: "󰑊", category: "Capture", keywords: "screen record video capture mp4 gif",                                              exec: "zanken-capture-screenrecording" },
    { title: "Text Extraction (OCR)",icon: "󰴑", category: "Capture", keywords: "ocr text extract recognize image scan copy",                                       exec: "zanken-capture-text-extraction" },
    { title: "Color Picker",        icon: "󰃉", category: "Capture", keywords: "color picker hex rgb dropper sample eyedropper",                                  exec: "zanken-capture-colorpicker" },
    { title: "Notes",               icon: "󰍔", category: "Capture", keywords: "notes note markdown scratchpad journal nvim neovim editor write text omni-notes",  exec: "bash -c 'mkdir -p \"$HOME/Documents/omni-notes\" && cd \"$HOME/Documents/omni-notes\" && nvim .'", tui: "zanken-launch-tui" },

    // ----- Trigger -----
    { title: "Set Reminder",        icon: "󰔛", category: "Trigger", keywords: "reminder alarm timer notify wake notification",                                    exec: "zanken-reminder-set", tui: "zanken-launch-tui" },
    { title: "Show Reminders",      icon: "󰔛", category: "Trigger", keywords: "reminders show list pending",                                                       exec: "zanken-reminder show" },
    { title: "Clear Reminders",     icon: "󰔛", category: "Trigger", keywords: "reminders clear delete remove all",                                                 exec: "zanken-reminder clear" },
    { title: "Transcode Media",     icon: "󰧸", category: "Trigger", keywords: "transcode media video audio convert compress mp4 mp3",                              exec: "zanken-transcode" },

    // ----- Learn -----
    { title: "Zanken Manual",      icon: "󰂺", category: "Learn", keywords: "zanken manual docs documentation help learn",                                         exec: "zanken-launch-webapp 'https://learn.omacom.io/2/the-zanken-manual'" },
    { title: "Niri Wiki",           icon: "󱤇", category: "Learn", keywords: "niri wiki docs documentation help wayland compositor window manager",                  exec: "zanken-launch-webapp 'https://github.com/YaLTeR/niri/wiki'" },
    { title: "Arch Wiki",           icon: "󰣇", category: "Learn", keywords: "arch wiki docs documentation help linux",                                              exec: "zanken-launch-webapp 'https://wiki.archlinux.org/title/Main_page'" },
    { title: "Neovim Keymaps",      icon: "󰕷", category: "Learn", keywords: "neovim nvim keymaps shortcuts lazyvim reference",                                      exec: "zanken-launch-webapp 'https://www.lazyvim.org/keymaps'" },
    { title: "Bash Cheatsheet",     icon: "󱆃", category: "Learn", keywords: "bash shell cheatsheet reference scripting",                                            exec: "zanken-launch-webapp 'https://devhints.io/bash'" },

    // ----- Update -----
    { title: "Sync Zanken",       icon: "󰚰", category: "Update", keywords: "sync zanken git pull update upgrade repo shell scripts",                           exec: "zanken-zanken-sync",           tui: "zanken-launch-floating-terminal-with-presentation" },
    { title: "System Packages",   icon: "󰮯", category: "Update", keywords: "pacman yay packages system upgrade update arch linux",                             exec: "yay -Syu --noconfirm",          tui: "zanken-launch-floating-terminal-with-presentation" }
];

// Pre-lowercases `title`/`keywords`/`category` onto `_t`/`_k`/`_c` so the
// per-keystroke scoring loop doesn't re-lowercase the same strings on
// every character.
function annotate(items) {
    const out = new Array(items.length);
    for (let i = 0; i < items.length; i++) {
        const it = items[i];
        out[i] = Object.assign({}, it, {
            _t: (it.title || "").toLowerCase(),
            _k: (it.keywords || "").toLowerCase(),
            _c: (it.category || "").toLowerCase()
        });
    }
    return out;
}

function basename(p) {
    const s = p.lastIndexOf("/");
    return s >= 0 ? p.substring(s + 1) : p;
}
function dirname(p) {
    const s = p.lastIndexOf("/");
    return s >= 0 ? p.substring(0, s) : "";
}
function tildify(p, homeDir) {
    return (homeDir && p.indexOf(homeDir) === 0)
        ? "~" + p.substring(homeDir.length)
        : p;
}
function fileExt(path) {
    const name = basename(path);
    const dot = name.lastIndexOf(".");
    if (dot <= 0) return name.toLowerCase(); // dotless name (Makefile)
    return name.substring(dot + 1).toLowerCase();
}
function fileIcon(path) {
    return fileIcons[fileExt(path)] || "";
}
function openUrl(url) {
    return "xdg-open " + JSON.stringify(url);
}
function formatStars(n) {
    if (n >= 1000000) return (n / 1000000).toFixed(1) + "m";
    if (n >= 1000)    return (n / 1000).toFixed(1) + "k";
    return "" + n;
}

// Stable identity per item — path wins (files, repos, PRs), exec next
// (apps, zanken actions), title+category last (synthetic rows).
function itemKey(item) {
    if (!item) return "";
    return item.path || item.exec || (item.title + "|" + item.category);
}
