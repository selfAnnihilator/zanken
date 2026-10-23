"""Exercise built-in Zellij menus and submenus in private PTY workspaces."""

import argparse
import json
from pathlib import Path
import socket
import time

from zellij_pty import Workspace


def configuration(root):
  for save in (False, True):
    with Workspace(root / f"leaders-{save}") as w:
      w.open("configuration")
      before = w.config.read_text()
      w.key("Right")
      w.key("Space")
      w.check("unlock-key capture opens", "Enter new key" in w.text("configuration"))
      w.key("Escape")
      w.check("Escape cancels unlock-key capture", "Unlock Toggle:" in w.text("configuration"))
      w.key("Right")
      w.key("Right")
      for index, modifier in enumerate(("Ctrl", "Alt", "Super", "Shift")):
        if index:
          w.key("Down")
        summary = next(line for line in w.text("configuration").splitlines() if "Secondary Modifier:" in line)
        w.key("Space")
        after = next(line for line in w.text("configuration").splitlines() if "Secondary Modifier:" in line)
        w.check("secondary modifier " + modifier + " toggles", after != summary)
      for _ in range(3):
        w.key("Up")
      w.key("Space")
      summary = next(line for line in w.text("configuration").splitlines() if "Secondary Modifier:" in line)
      w.check("Up restores Ctrl selection", "Ctrl" not in summary.split("Secondary Modifier:")[1])
      w.key("Left")
      w.key("Space")
      w.key("Alt+x")
      w.check("new unlock key is captured", "Alt x" in w.text("configuration"))
      w.key("Ctrl+c")
      w.check("Ctrl+C resets pending changes", "Alt g" in w.text("configuration"))
      w.key("Right")
      w.key("Space")
      w.key("Alt+x")
      w.key("Ctrl+a" if save else "Return")
      w.wait(lambda: "applied" in w.text("configuration").lower())
      w.check("leader apply/save message", "applied" in w.text("configuration").lower())
      w.check("leader disk write matches action", (w.config.read_text() != before) == save)
      w.close("configuration")
      w.key("Alt+x")
      w.check("rebound unlock key actually unlocks", not w.locked())
      w.key("Alt+x")
      w.check("rebound unlock key actually locks", w.locked())

  for preset in (0, 1):
    for save in (False, True):
      with Workspace(root / f"preset-{preset}-{save}") as w:
        w.open("configuration")
        w.key("Tab")
        w.check("Tab opens mode presets", "Override keybindings" in w.text("configuration"))
        for _ in range(preset + 1):
          w.key("Down")
        w.key("Up")
        w.key("Down")
        before = w.config.read_text()
        w.key("Ctrl+a" if save else "Return")
        w.wait(lambda: "applied" in w.text("configuration").lower())
        w.check(f"preset {preset} apply/save", "applied" in w.text("configuration").lower())
        w.check("preset disk write matches action", (w.config.read_text() != before) == save)
        w.close("configuration")
        if preset == 0:
          w.type("printf '%s\\n' DEFAULT_PRESET_INPUT")
          w.key("Return")
          w.check("Default preset accepts application input", "DEFAULT_PRESET_INPUT" in w.action("dump-screen").splitlines())
        else:
          w.key("Ctrl+g")
          w.key("p")
          w.key("r")
          w.check("Unlock First preset enters pane mode and splits", len(w.terminals()) == 2)
          w.check("Unlock First exits to application input", w.locked())


def about(root):
  with Workspace(root / "pages") as w:
    for index in range(1, 8):
      w.open("about")
      main = w.text("about")
      for _ in range(index):
        w.key("Down")
      w.key("Up")
      w.key("Down")
      w.key("Return")
      text = w.text("about")
      w.check(f"About detail {index} opens", text != main and "What's new?" not in text)
      w.snapshot("about", f"detail-{index}")
      # Long pages expose scroll navigation; shorter pages keep their full text.
      w.key("Down")
      w.key("Up")
      w.key("Escape")
      w.check(f"About detail {index} Escape returns", "What's new?" in w.text("about"))
      w.close("about")
    w.open("about")
    w.key("?")
    start = w.text("about")
    w.check("usage tips open", "What's new?" not in start)
    for index in range(12):
      previous = w.text("about")
      w.key("Down")
      w.check(f"tip {index} next", w.text("about") != previous)
    w.key("Up")
    w.check("tips previous", w.text("about") != start)
    w.config.write_text(w.config.read_text().replace('show_startup_tips false', 'show_startup_tips true'))
    time.sleep(.3)
    w.key("Ctrl+c")
    w.wait(lambda: 'show_startup_tips false' in w.config.read_text())
    w.check("tips Ctrl+C saves startup opt-out", 'show_startup_tips false' in w.config.read_text())
    w.key("Escape")
    w.wait(lambda: not any((p.get("plugin_url") == "zellij:about" or str(p.get("plugin_url")).endswith("/about.wasm")) for p in w.panes()))
    w.check("tip Escape dismisses")

  # Explicit missing bindings expose the update/confirmation submenu.
  missing = Workspace(root / "missing")
  missing.config.write_text('default_mode "locked"\ndefault_shell "fish"\ndefault_layout "zanken"\n'
                            f'layout_dir "{missing.root / "layouts"}"\n'
                            'show_startup_tips false\nshow_release_notes false\n'
                            'keybinds clear-defaults=true {}\n')
  with missing as w:
    w.action("launch-plugin", "--floating", "zellij:about")
    w.wait(lambda: "About" in w.plugin("about")["title"] or "Zellij" in w.text("about"))
    w.key("u")
    w.check("missing-bindings update submenu", "Update Keybindings" in w.text("about"))
    before = w.config.read_text()
    w.key("n")
    w.check("missing-bindings cancel", w.config.read_text() == before and "What's new?" in w.text("about"))
    w.key("u")
    w.key("y")
    w.wait(lambda: w.config.read_text() != before)
    w.check("missing-bindings confirm saves", w.config.read_text() != before)
    w.key("Escape")
    w.check("updated keybindings return", "What's new?" in w.text("about"))


def plugins(root):
  w = Workspace(root)
  files = w.root / "files"
  (files / "folder").mkdir()
  (files / "folder/inside.txt").write_text("fixture\n")
  (files / ".hidden").write_text("fixture\n")
  w.config.write_text(w.config.read_text() + '\nplugins {\n  filepicker location="zellij:strider" {\n'
                      f'    cwd "{files}"\n  }}\n}}\n')
  w.cli("setup", "--dump-plugins", str(files))
  wasm = next(files.rglob("about.wasm"))
  local_wasm = files / "about.wasm"
  local_wasm.write_bytes(wasm.read_bytes())
  wasm = local_wasm
  w.cwd = files
  with w:
    w.open("about")
    target = w.pid("about")
    w.open("plugin-manager")
    manager = w.pid("plugin-manager")
    w.wait(lambda: w.plugin("plugin-manager")["title"] == "Plugin Manager")
    w.check("permission grant sets the Plugin Manager title")
    w.type("about")
    w.key("BackSpace")
    w.check("plugin search and Backspace", "abou" in w.text("plugin-manager"))
    w.type("t")
    w.wait(lambda: "about.wasm" in w.text("plugin-manager"))
    w.key("Down")
    collapsed = w.text("plugin-manager")
    w.key("Right")
    w.check("Right expands plugin details", w.text("plugin-manager") != collapsed)
    w.key("Left")
    w.check("Left collapses plugin details", w.text("plugin-manager") == collapsed)
    w.key("Return")
    w.check("Enter focuses selected plugin", target in w.action("list-clients"))
    for _ in range(5):
      w.key("Down")
    w.key("Return")
    w.check("reload fixture has detail state", "Title frames" in w.text("about"))
    if manager not in w.action("list-clients"):
      w.action("focus-pane-id", manager)
    w.key("Tab")
    w.wait(lambda: "What's new?" in w.text("about"))
    w.check("Tab reloads selected plugin and resets its state")
    if manager not in w.action("list-clients"):
      w.action("focus-pane-id", manager)
    w.key("Delete")
    w.wait(lambda: not any((p.get("plugin_url") == "zellij:about" or str(p.get("plugin_url")).endswith("/about.wasm")) for p in w.panes()))
    w.check("Delete closes selected plugin")
    w.key("Escape")
    w.key("Ctrl+a")
    w.check("Ctrl+A opens new-plugin form", "LOAD NEW PLUGIN" in w.text("plugin-manager"))
    w.type("zellij:about")
    w.key("Tab")
    w.type("audit-key")
    w.key("Tab")
    w.type("valuex")
    w.key("BackSpace")
    w.key("Return")
    w.check("configuration fields accept, edit and commit", "audit-key" in w.text("plugin-manager") and "value" in w.text("plugin-manager"))
    w.key("Down")
    w.key("Up")
    w.key("Down")
    w.key("Tab")
    w.type("-edit")
    w.key("Tab")
    w.type("-edit")
    w.key("Return")
    w.check("existing configuration pair is editable", "audit-key-edit" in w.text("plugin-manager"))
    w.key("Delete")
    w.check("Delete removes a configuration pair", "audit-key-edit" not in w.text("plugin-manager"))
    w.key("Ctrl+f")
    w.wait(lambda: any(p.get("plugin_url") in ("zellij:strider", "filepicker") for p in w.panes()))
    w.wait(lambda: "folder" in w.text("strider"))
    w.check("Ctrl+F opens the private file picker", "folder" in w.text("strider"))
    w.key("Ctrl+e")
    w.wait(lambda: ".hidden" in w.text("strider"))
    w.check("Ctrl+E shows hidden files")
    w.key("Ctrl+e")
    w.check("Ctrl+E hides hidden files", ".hidden" not in w.text("strider"))
    for open_key in ("Right", "Tab", "Return"):
      w.type("folder")
      w.key("Down")
      w.key("Up")
      w.key(open_key)
      w.wait(lambda: "inside.txt" in w.text("strider"))
      w.check(open_key + " enters the selected folder")
      w.key("Left")
      w.wait(lambda: "folder" in w.text("strider"))
      w.check("Left returns to the parent folder")
    w.type("aboutx")
    w.key("BackSpace")
    w.check("file-picker search and Backspace", "about" in w.text("strider").lower())
    w.key("Ctrl+c")
    w.snapshot("strider", "ctrl-c-before-redraw")
    w.key("Down")  # Upstream Ctrl+C changes state but does not request a redraw.
    w.check("Ctrl+C clears picker search", "folder" in w.text("strider"))
    w.type("about")
    w.key("Escape")
    w.check("Escape clears picker search", "folder" in w.text("strider"))
    w.type(wasm.name)
    w.key("Down")
    w.key("Return")
    w.wait(lambda: not any(p.get("plugin_url") in ("zellij:strider", "filepicker") for p in w.panes()))
    w.check("file selection returns a path to the form", wasm.name in w.text("plugin-manager"))
    w.key("Return")
    w.wait(lambda: any(p.get("plugin_url", "").endswith(wasm.name) for p in w.panes() if p.get("plugin_url")))
    w.check("Enter loads the selected local WASM plugin")
    if manager not in w.action("list-clients"):
      w.action("focus-pane-id", manager)
    w.key("Ctrl+a")
    w.key("Escape")
    w.check("Escape cancels the new-plugin form", "LOAD NEW PLUGIN" not in w.text("plugin-manager"))
    w.key("Ctrl+a")
    w.type("zellij:about")
    w.key("Ctrl+l")
    w.key("Return")
    w.wait(lambda: any(p.get("plugin_url") == "zellij:about" and not p["is_focused"] for p in w.panes()))
    w.check("Ctrl+L loads a plugin without taking focus", manager in w.action("list-clients"))


def sharing(root):
  with socket.socket() as listener:
    listener.bind(("127.0.0.1", 0))
    port = listener.getsockname()[1]
  with Workspace(root, extra=f'web_server_ip "127.0.0.1"\nweb_server_port {port}\n', log=False) as w:
    w.check("authentication store starts empty", not w.cli("web", "--list-tokens").stdout.strip())
    try:
      w.open("share")
      w.key("Return")
      w.wait(lambda: "Web server: RUNNING" in w.text("share"), 10)
      w.check("Enter starts private localhost web server", "online" in w.cli("web", "--status", "--port", str(port), "--timeout", "1").stdout)
      w.key("Space")
      w.wait(lambda: "Current session: SHARING" in w.text("share"))
      w.check("Space starts session sharing")
      w.key("Space")
      w.wait(lambda: "Current session: NOT SHARING" in w.text("share"))
      w.check("Space stops session sharing")
      w.key("t")
      w.check("T creates a token", "token_1" in w.cli("web", "--list-tokens").stdout)
      w.key("Escape")
      w.key("t")
      w.check("T opens existing token management", "revoke" in w.text("share").lower())
      for key, name in [("n", "audit-rw"), ("o", "audit-ro")]:
        w.key(key)
        w.type(name + "x")
        w.key("BackSpace")
        w.key("Return")
        w.check(key + " creates named token with editable name", name in w.cli("web", "--list-tokens").stdout)
        w.key("Escape")
      w.key("Down")
      w.key("Up")
      w.key("Down")
      w.key("r")
      w.type("audit-renamed")
      w.key("Return")
      w.check("R renames selected token", "audit-renamed" in w.cli("web", "--list-tokens").stdout)
      w.key("r")
      w.type("cancelled")
      w.key("Escape")
      w.check("Escape cancels token rename", "cancelled" not in w.cli("web", "--list-tokens").stdout)
      before = w.cli("web", "--list-tokens").stdout.splitlines()
      w.key("x")
      after = w.cli("web", "--list-tokens").stdout.splitlines()
      w.check("X revokes selected token", len(after) == len(before) - 1)
      w.key("Escape")  # Acknowledge the revocation status before the next action.
      w.key("Ctrl+x")
      w.check("Ctrl+X revokes all private tokens", not w.cli("web", "--list-tokens").stdout.strip())
      # A status notification consumes its first dismiss key.
      w.key("Escape")
      if "Web server:" not in w.text("share"):
        w.key("Escape")
      w.key("Ctrl+c")
      w.wait(lambda: "Web server: NOT RUNNING" in w.text("share"), 10)
      w.check("Ctrl+C stops the web server")
    finally:
      # This fixture's authentication store and socket namespace are private.
      w.cli("web", "--revoke-all-tokens", check=False)
      w.cli("web", "--stop", check=False)


def sessions(root):
  # /tmp has a special meaning in plugin APIs; use a real host path for cwd.
  w = Workspace(root, temp_parent=Path(__file__).resolve().parent)
  files = w.root / "files"
  w.config.write_text(w.config.read_text() + '\nplugins {\n  filepicker location="zellij:strider" {\n'
                      f'    cwd "{files}"\n  }}\n}}\n')

  def active():
    return {line.split(" [Created")[0].strip() for line in w.cli("list-sessions", "--no-formatting").stdout.splitlines() if "EXITED" not in line}

  def fresh():
    if any(p.get("plugin_url") == "zellij:session-manager" for p in w.panes()):
      w.close("session-manager")
    w.open("session-manager")
    time.sleep(.3)

  def select(name):
    fresh()
    w.type(name)
    w.key("Tab")
    w.key("Return")
    w.session = name
    w.wait(lambda: len(w.panes()) > 0)

  with w:
    for name in ("one", "two"):
      w.cli("attach", "--create-background", name)
    w.wait(lambda: {"audit", "one", "two"} <= active())
    fresh()
    w.type("onex")
    w.key("BackSpace")
    w.key("Down")
    w.key("Up")
    w.key("Tab")
    w.check("session search, Backspace and completion", "Session: one" in w.text("session-manager"))
    w.key("Return")
    w.session = "one"
    w.wait(lambda: "plugin_" not in w.action("list-clients"))
    w.check("Enter attaches to a selected live session")
    select("audit")
    w.check("picker attaches back to the original session")
    fresh()
    w.key("Ctrl+r")
    w.type("renamedx")
    w.key("BackSpace")
    w.key("Return")
    w.session = "renamed"
    w.wait(lambda: "renamed" in active())
    w.check("Ctrl+R rename is committed", "audit" not in active())
    fresh()
    w.key("Ctrl+r")
    w.type("cancelled")
    w.key("Escape")
    w.check("Escape cancels session rename", "cancelled" not in active())

    fresh()
    w.type("brandnewx")
    w.key("BackSpace")
    w.key("Return")
    w.check("new session opens layout choice", "New session layout:" in w.text("session-manager"))
    w.type("zanken")
    w.key("BackSpace")
    w.key("Down")
    w.key("Up")
    w.check("new-session layout filter edits", "zanke" in w.text("session-manager"))
    w.key("Escape")
    w.check("Escape returns from layout selection", "Session:" in w.text("session-manager"))
    w.key("Return")
    w.key("Ctrl+f")
    w.wait(lambda: any(p.get("plugin_url") in ("zellij:strider", "filepicker") for p in w.panes()))
    w.wait(lambda: "FIND:" in w.text("strider"))
    w.type("files")
    w.key("Tab")
    w.key("Return")
    w.wait(lambda: not any(p.get("plugin_url") in ("zellij:strider", "filepicker") for p in w.panes()))
    w.check("folder picker returns selected directory", str(files) in w.text("session-manager"))
    w.key("Ctrl+c")
    w.check("Ctrl+C clears selected directory", str(files) not in w.text("session-manager"))
    w.key("Ctrl+f")
    w.wait(lambda: any(p.get("plugin_url") in ("zellij:strider", "filepicker") for p in w.panes()))
    w.wait(lambda: "FIND:" in w.text("strider"))
    w.type("files")
    w.key("Tab")
    w.key("Return")
    w.wait(lambda: not any(p.get("plugin_url") in ("zellij:strider", "filepicker") for p in w.panes()))
    w.snapshot("session-manager", "selected-folder-before-create")
    w.check("second picker selected folder", f"New session folder: {files}" in w.text("session-manager"))
    w.key("Down")  # Explicitly select a layout so its cwd is applied.
    w.key("Return")
    w.session = "brandnew"
    w.wait(lambda: "brandnew" in active())
    w.wait(lambda: len(w.terminals()) > 0, 15)
    w.wait(lambda: all(p.get("pane_cwd") == str(files) for p in w.terminals()))
    w.check("Enter creates the session in the chosen directory", len(w.terminals()) > 0)
    (w.evidence / "created-session-cwd.json").write_text(json.dumps([p.get("pane_cwd") for p in w.terminals()]))
    fresh()
    w.key("Ctrl+a")
    w.wait(lambda: any("brandnew" in str(p) and p.name == "session-layout.kdl" for p in (w.root / "cache").rglob("*")))
    w.check("Ctrl+A saves a real resurrection layout")
    select("renamed")
    w.cli("kill-session", "brandnew")
    w.wait(lambda: "brandnew" not in active())
    select("brandnew")
    w.check("Enter resurrects a saved session", "brandnew" in active() and len(w.terminals()) > 0)
    select("renamed")
    w.cli("kill-session", "brandnew")
    fresh()
    w.type("brandnew")
    w.key("Down")
    w.key("Delete")
    w.wait(lambda: "brandnew" not in w.cli("list-sessions", "--no-formatting").stdout)
    w.check("Delete removes a saved/exited session")
    fresh()
    w.type("one")
    w.key("Down")
    w.key("Delete")
    w.wait(lambda: "one" not in active())
    w.check("Delete kills a selected live session")
    for cancel in ("n", "Escape", "Ctrl+c"):
      fresh()
      before = active()
      w.key("Ctrl+d")
      w.check("kill-all confirmation appears", "kill" in w.text("session-manager").lower())
      w.key(cancel)
      w.check(cancel + " cancels kill-all", active() == before)
    fresh()
    w.key("Ctrl+d")
    w.key("y")
    w.wait(lambda: active() == {"renamed"})
    w.check("Y confirms kill-all of only other private sessions")
    w.close("session-manager")
    original_proc, original_master = w.proc, w.master
    observer, _ = w.start("renamed")
    w.proc, w.master = original_proc, original_master
    fresh()
    w.key("Ctrl+x")
    w.wait(lambda: observer.poll() is not None)
    w.check("Ctrl+X disconnects other clients", original_proc.poll() is None)


GROUPS = {"configuration": configuration, "about": about, "plugins": plugins, "sharing": sharing,
          "sessions": sessions}


def main():
  parser = argparse.ArgumentParser(description=__doc__)
  parser.add_argument("--group", choices=["all", *GROUPS], default="all")
  parser.add_argument("--evidence", type=Path, default=Path("/tmp/zanken-zellij-deep-audit/results"))
  args = parser.parse_args()
  for name, run in GROUPS.items():
    if args.group in ("all", name):
      print("AUDIT", name, flush=True)
      run(args.evidence / name)


if __name__ == "__main__":
  main()
