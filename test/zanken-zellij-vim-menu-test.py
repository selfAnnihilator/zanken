"""Exercise Vim navigation and literal text entry in private menu instances."""

import argparse
from pathlib import Path
import socket

from zellij_pty import Workspace


def open_menu(w, plugins, name):
  url = "file:" + str((plugins / (name + ".wasm")).resolve())
  pane = w.action("launch-plugin", "--floating", url).strip()
  w.wait(lambda: bool(w.plugin(name)))
  w.wait(lambda: bool(w.text(name)))
  if "Allow? (y/n)" in w.text(name):
    w.key("y")
  w.wait(lambda: "Allow? (y/n)" not in w.text(name))
  w.wait(lambda: any(hint in w.text(name) for hint in ("Manage:", "jk:", "hjkl:")))
  return pane


def about(root, plugins):
  with Workspace(root) as w:
    open_menu(w, plugins, "about")
    w.check("original About help remains visible", "Help:" in w.text("about") and "ESC" in w.text("about"))
    w.key("j")
    w.key("k")
    for _ in range(5):
      w.key("j")
    w.key("l")
    w.key("h")
    w.check("About h/l only navigate", "What's new?" in w.text("about"))
    w.key("Return")
    w.check("About j/k select and Enter opens detail", "Title frames" in w.text("about"))
    w.check("original detail help remains visible", "Help:" in w.text("about") and "ESC" in w.text("about"))
    w.key("h")
    w.key("l")
    w.check("About detail h/l cannot go back or open", "Title frames" in w.text("about"))
    w.key("Escape")
    w.check("About Escape returns to menu", "What's new?" in w.text("about"))
    w.key("?")
    before = w.text("about")
    w.key("j")
    w.check("tips j advances", w.text("about") != before)
    w.key("k")
    w.check("tips k goes back", w.text("about") == before)


def configuration(root, plugins):
  with Workspace(root) as w:
    pane = open_menu(w, plugins, "configuration")
    w.check("original configuration help remains visible", "Help:" in w.text("configuration"))
    w.key("l")
    w.key("l")
    before = w.frame(pane, ansi=True)
    w.key("j")
    w.check("configuration j moves selected modifier", w.frame(pane, ansi=True) != before)
    w.key("k")
    w.key("h")
    w.key("Space")
    w.check("configuration h/l reach shortcut capture", "Enter new key" in w.text("configuration"))
    w.key("h")
    w.check("shortcut capture accepts literal h", "Enter new key" not in w.text("configuration") and "Alt g" not in w.text("configuration"))
    w.key("Ctrl+c")
    w.key("Tab")
    before = w.frame(pane, ansi=True)
    w.key("j")
    w.check("preset j selects", w.frame(pane, ansi=True) != before)
    w.key("k")
    before = w.frame(pane, ansi=True)
    w.key("l")
    w.key("h")
    w.check("preset h/l cannot open or close menus", w.frame(pane, ansi=True) == before)


def layouts(root, plugins):
  with Workspace(root) as w:
    pane = open_menu(w, plugins, "layout-manager")
    w.type("hjkl")
    w.check("layout starts in literal search", "hjkl" in w.text("layout-manager"))
    w.key("Escape")
    w.key("Escape")
    before = w.frame(pane, ansi=True)
    w.key("j")
    w.check("layout management j selects", w.frame(pane, ansi=True) != before)
    w.key("k")
    w.check("layout management k reverses selection", w.frame(pane, ansi=True) == before)
    w.key("n")
    w.key("r")
    w.type("hjkl-fixture")
    w.key("Return")
    w.key("Return")
    w.wait(lambda: (w.root / "layouts/hjkl-fixture.kdl").exists())
    w.check("new layout name accepts literal Vim letters")
    w.key("Escape")
    w.key("Escape")
    w.key("Escape")
    # A fresh menu starts searching. Clear it once to reach management mode.
    if any((p.get("plugin_url") or "").endswith("layout-manager.wasm") for p in w.panes()):
      w.close("layout-manager")
    pane = open_menu(w, plugins, "layout-manager")
    w.key("Escape")
    w.key("j")
    before = len(w.tabs())
    w.key("l")
    w.key("h")
    w.check("layout h/l cannot open or close layouts", len(w.tabs()) == before and "Manage:" in w.text("layout-manager"))
    w.key("Return")
    w.wait(lambda: len(w.tabs()) > before)
    w.check("explicit Enter opens selected layout")
    open_menu(w, plugins, "layout-manager")
    w.key("Escape")
    w.key("Escape")
    w.wait(lambda: not any((p.get("plugin_url") or "").endswith("layout-manager.wasm") for p in w.panes()))
    w.check("native Escape closes layout management")


def preserved(root, plugins):
  with Workspace(root) as w:
    w.open("session-manager")
    w.type("hjkl")
    w.check("session letters retain search input", "Session: hjkl" in w.text("session-manager"))
    w.close("session-manager")
    w.open("plugin-manager")
    w.type("hjkl")
    w.check("plugin letters retain search input", "SEARCH: hjkl" in w.text("plugin-manager"))
    w.key("Escape")
    w.key("Ctrl+a")
    w.type("hjkl")
    w.check("plugin URL retains literal text", "Enter Plugin URL: hjkl" in w.text("plugin-manager"))
    w.close("plugin-manager")
    w.action("launch-plugin", "--floating", "zellij:strider")
    w.wait(lambda: bool(w.text("strider")))
    w.type("hjkl")
    w.check("file picker letters retain search input", "hjkl" in w.text("strider"))


def sharing(root, plugins):
  with socket.socket() as listener:
    listener.bind(("127.0.0.1", 0))
    port = listener.getsockname()[1]
  with Workspace(root, extra=f'web_server_ip "127.0.0.1"\nweb_server_port {port}\n', log=False) as w:
    try:
      open_menu(w, plugins, "share")
      w.wait(lambda: "Web server:" in w.text("share"))
      w.key("t")
      w.key("Escape")
      w.key("t")
      w.key("n")
      w.type("hjkl-token")
      w.key("Return")
      w.check("token name keeps literal Vim letters", "hjkl-token" in w.cli("web", "--list-tokens").stdout)
      w.key("Escape")
      w.key("j")
      w.key("k")
      w.key("r")
      w.type("hjkl-renamed")
      w.key("Return")
      w.check("token jk navigation and literal rename", "hjkl-renamed" in w.cli("web", "--list-tokens").stdout)
      w.key("h")
      w.key("l")
      w.check("token h/l cannot go back or confirm", "Web server:" not in w.text("share"))
      w.key("Escape")
      w.check("token native Escape returns", "Web server:" in w.text("share"))
    finally:
      w.cli("web", "--revoke-all-tokens", check=False)
      w.cli("web", "--stop", check=False)


def guide(root, plugins):
  with Workspace(root) as w:
    for leader, labels in [
      ("o", ("Session Manager", "Configure", "Layout Manager", "Plugin Manager", "About", "Share")),
      ("p", ("New", "Fullscreen", "Close")),
      ("t", ("New", "Close")),
    ]:
      w.enter(leader)
      text = w.guide()
      w.check("native " + leader + " guide lists configured actions", all(label.lower() in text.lower() for label in labels))
      if leader == "o":
        w.check("Session header keeps Ctrl+O", "Ctrl o" in text.splitlines()[0])
        count = len(w.panes())
        w.key("h")
        w.key("l")
        w.check("Session h/l do not open tools", len(w.panes()) == count and "Layout Manager" in w.guide())
        w.key("v")
        w.wait(lambda: bool(w.plugin("layout-manager")))
        if "permission" in w.text("layout-manager").lower():
          w.key("y")
        w.check("Session v explicitly opens Layout Manager")
        w.close("layout-manager")
      else:
        w.key("Escape")


def guide_swap(root, plugins):
  w = Workspace(root)
  layout = w.root / "layouts/zanken.kdl"
  layout.write_text(layout.read_text().replace('location="status-bar"', 'location="zellij:status-bar"'))
  with w:
    old = w.plugin("status-bar")
    def geometry():
      return {p["id"]: (p["pane_x"], p["pane_y"], p["pane_rows"], p["pane_columns"])
              for p in w.panes() if not p["is_plugin"]}
    before = geometry()
    if old["is_suppressed"]:
      duplicate = w.action("launch-plugin", "--floating", "--no-focus", "--configuration", "hide_when_locked=true", "file:" + str((plugins / "status-bar.wasm").resolve())).strip()
      w.wait(lambda: not any(p["is_plugin"] and "plugin_" + str(p["id"]) == duplicate for p in w.panes()))
      w.check("background guide removes a duplicate without resizing terminals", before == geometry())
      w.check("original background guide remains", w.plugin("status-bar")["id"] == old["id"])
      w.enter("o")
      w.wait(lambda: "Configure" in w.guide())
      w.check("background guide still shows Session tools", all(label in w.guide() for label in ("Configure", "About", "Share", "Plugin Manager", "Layout Manager")))
      return
    new = w.action("launch-plugin", "--floating", "--no-focus", "--configuration", "hide_when_locked=true", "file:" + str((plugins / "status-bar.wasm").resolve())).strip()
    w.wait(lambda: bool(w.frame(new)))
    for _ in range(12):
      if "permission" in w.frame(new).lower():
        w.action("send-keys", "--pane-id", new, "y")
      if not w.frame(new).strip():
        break
    w.action("set-pane-borderless", "--pane-id", new, "--borderless")
    w.action("pipe", "--name", "zanken-replace-guide", "--", new.removeprefix("plugin_") + ":" + str(old["id"]))
    w.wait(lambda: not any(p["is_plugin"] and p["id"] == old["id"] for p in w.panes()))
    info = next(p for p in w.panes() if p["is_plugin"] and "plugin_" + str(p["id"]) == new)
    w.check("guide replacement preserves terminals and geometry", before == geometry())
    w.check("guide replacement preserves two rows", info["pane_rows"] == 2 and not info["is_floating"])
    w.enter("o")
    w.check("replacement shows Session menu hints", all(label in w.guide() for label in ("Configure", "About", "Share", "Plugin Manager", "Layout Manager")))


def quicknav_tip(root, plugins):
  with Workspace(root) as w:
    w.key("Alt+g")
    text = w.guide()
    w.snapshot("status-bar", "quicknav-tip")
    w.check("QuickNav tip describes opening a pane", "open new pane" in text)
    w.check("configured new-pane shortcut is not shown as unbound", "UNBOUND" not in text)
    w.check("QuickNav tip shows Alt+n", "Alt+<n>" in "".join(text.split()))
    before = len(w.terminals())
    w.key("Alt+n")
    w.wait(lambda: len(w.terminals()) == before + 1)
    w.check("displayed Alt+n shortcut creates a pane")
    w.check("pane creation returns to hidden locked guide", not w.guide().strip())


def on_demand(root, plugins):
  with Workspace(root) as w:
    geometry = lambda: {p["id"]: (p["pane_x"], p["pane_y"], p["pane_rows"], p["pane_columns"])
                        for p in w.terminals()}
    before = geometry()
    w.check("guide is blank at startup", not w.guide().strip())
    w.snapshot("status-bar", "locked-guide")
    for leader, labels in [("Alt+g", ("PANE", "SESSION")),
                           ("Ctrl+Space", ("Split down", "Split right", "Fullscreen")),
                           ("Ctrl+b", ("Split down", "Split right", "Fullscreen"))]:
      w.key(leader)
      w.wait(lambda: bool(w.guide().strip()))
      w.check("guide appears after " + leader, bool(w.guide().strip()))
      w.check("guide shows controls after " + leader, all(label.lower() in w.guide().lower() for label in labels))
      w.snapshot("status-bar", leader.replace("+", "-") + "-guide")
      w.key("Escape")
      w.wait(lambda: not w.guide().strip())
      w.check("Escape clears " + leader + " hints", not w.guide().strip())
      w.check("mode change preserves terminal geometry", geometry() == before)
    w.key("Alt+g")
    w.key("Alt+g")
    w.check("Alt+G hides the guide again", not w.guide().strip())
    for leader in ("p", "t", "n", "h", "s", "o"):
      w.enter(leader)
      w.check("native " + leader + " hints remain available", bool(w.guide().strip()))
      w.key("Escape")
      w.check("native " + leader + " exit clears stale hints", not w.guide().strip())
    text = w.open("about")
    w.check("popup keeps its own keyboard help", "Help:" in text and "ESC" in text)
    w.check("popup launch clears bottom guide", not w.guide().strip())
    w.key("Escape")
    w.type("printf 'ON_DEMAND_%s\\n' INPUT_OK")
    w.key("Return")
    w.wait(lambda: "ON_DEMAND_INPUT_OK" in w.frame("terminal_" + str(w.terminals()[0]["id"])))
    w.check("application input still works with hidden guide")


GROUPS = {"about": about, "configuration": configuration, "layouts": layouts,
          "preserved": preserved, "sharing": sharing, "guide": guide, "guide_swap": guide_swap,
          "on_demand": on_demand, "quicknav_tip": quicknav_tip}


if __name__ == "__main__":
  parser = argparse.ArgumentParser(description=__doc__)
  parser.add_argument("--plugins", type=Path, default=Path(__file__).resolve().parents[1] / "config/zellij/plugins")
  parser.add_argument("--group", choices=["all", *GROUPS], default="all")
  parser.add_argument("--evidence", type=Path, default=Path("/tmp/zanken-zellij-vim-menu-checks"))
  args = parser.parse_args()
  for name, run in GROUPS.items():
    if args.group in ("all", name):
      print("AUDIT", name, flush=True)
      run(args.evidence / name, args.plugins)
