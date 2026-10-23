"""Check native and compatibility shortcuts by their effects in private sessions."""

from pathlib import Path
import time
import sys

from zellij_pty import Workspace


ROOT = Path("/tmp/zanken-zellij-deep-audit/results/native")


def focused(w):
  return next(p for p in sorted(w.terminals(), key=lambda p: p["is_floating"], reverse=True) if p["is_focused"])


def geometry(w):
  return {p["id"]: (p["pane_x"], p["pane_y"], p["pane_rows"], p["pane_columns"]) for p in w.terminals()}


def mode(w, leader, key):
  w.action("switch-mode", "locked")
  w.enter(leader)
  w.key(key)


def panes():
  with Workspace(ROOT / "panes") as w:
    first = focused(w)["id"]
    w.key("Alt+Shift+Return")
    second = focused(w)["id"]
    w.check("direct right split", len(w.terminals()) == 2)
    for key, target in [("h", first), ("l", second)]:
      w.key("Ctrl+Shift+" + key)
      w.check("direct focus " + key, focused(w)["id"] == target)
    w.key("Alt+Return")
    third = focused(w)["id"]
    w.check("direct down split", len(w.terminals()) == 3)
    for key, target in [("k", second), ("j", third)]:
      w.key("Ctrl+Shift+" + key)
      w.check("direct focus " + key, focused(w)["id"] == target)
    for key in ("Alt+z", "Alt+z"):
      before = focused(w)["is_fullscreen"]
      w.key(key)
      w.check("zoom toggles", focused(w)["is_fullscreen"] != before)
    for key in ("n", "Tab", "p", "h", "l", "k", "j", "Left", "Right", "Up", "Down"):
      axis = "pane_x" if key in ("h", "l", "Left", "Right") else "pane_y"
      if key not in ("n", "Tab", "p"):
        ordered = sorted(w.terminals(), key=lambda p: p[axis], reverse=key in ("h", "k", "Left", "Up"))
        target = ordered[0]
        if f"terminal_{target['id']}" not in w.action("list-clients"):
          w.action("focus-pane-id", f"terminal_{target['id']}")
      before = geometry(w)
      mode(w, "h", key)
      w.check("move mode " + key, geometry(w) != before)
    w.key("Escape")
    for key in ("h", "l", "j", "k", "Left", "Right", "Up", "Down"):
      axis = "pane_x" if key in ("h", "l", "Left", "Right") else "pane_y"
      candidates = [p for p in w.terminals() if p["pane_x"] > 0] if axis == "pane_y" else w.terminals()
      target = max(candidates, key=lambda p: p[axis]) if key in ("h", "k", "Left", "Up") else min(candidates, key=lambda p: p[axis])
      if f"terminal_{target['id']}" not in w.action("list-clients"):
        w.action("focus-pane-id", f"terminal_{target['id']}")
      before = focused(w)["id"]
      mode(w, "p", key)
      w.check("pane navigation " + key, focused(w)["id"] != before)
    w.key("Escape")
    mode(w, "p", "c")
    w.type("pane-name")
    w.key("Return")
    w.check("pane rename accepts", focused(w)["title"] == "pane-name")
    mode(w, "p", "c")
    w.type("cancelled")
    w.key("Escape")
    w.check("pane rename Escape restores", focused(w)["title"] == "pane-name")
    w.key("Escape")
    before = [(p["pane_content_columns"], p["pane_content_rows"]) for p in w.terminals()]
    mode(w, "p", "z")
    w.check("frame toggle", [(p["pane_content_columns"], p["pane_content_rows"]) for p in w.terminals()] != before)
    mode(w, "p", "z")
    for key in ("f", "f", "Shift+f", "Shift+f"):
      before = focused(w)["is_fullscreen"]
      mode(w, "p", key)
      w.check("pane fullscreen " + key, focused(w)["is_fullscreen"] != before)
    mode(w, "p", "e")
    w.check("pane embed-to-floating", focused(w)["is_floating"])
    mode(w, "p", "i")
    w.check("floating pin recorded", "pinned true" in w.action("dump-layout"))
    mode(w, "p", "i")
    mode(w, "p", "e")
    w.check("pane floating-to-embed", not focused(w)["is_floating"])
    mode(w, "p", "w")
    w.check("floating visibility opens", w.action("are-floating-panes-visible").strip() == "true")
    mode(w, "p", "w")
    result = w.cli("--session", w.session, "action", "are-floating-panes-visible", check=False)
    w.check("floating visibility hides", "false" in result.stdout + result.stderr)
    count = len(w.terminals())
    w.key("Alt+Escape")
    w.wait(lambda: len(w.terminals()) == count - 1)
    w.check("direct pane close")
    for key in ("n", "d", "r", "s"):
      count = len(w.terminals())
      mode(w, "p", key)
      w.check("pane create " + key, len(w.terminals()) == count + 1)
      mode(w, "p", "x")
      w.check("pane close x after " + key, len(w.terminals()) == count)


def tabs():
  with Workspace(ROOT / "tabs") as w:
    for index in range(2, 10):
      mode(w, "t", "n")
      w.wait(lambda: len(w.tabs()) == index)
      w.check("native new tab " + str(index), len(w.tabs()) == index)
    for index in range(1, 10):
      w.key("Alt+" + str(index))
      w.check("direct tab " + str(index), w.tab()["position"] == index - 1)
      mode(w, "t", str(10 - index))
      w.check("native tab " + str(10 - index), w.tab()["position"] == 9 - index)
    for key, delta in [("Alt+Right", 1), ("Alt+Left", -1)]:
      before = w.tab()["position"]
      w.key(key)
      w.check("direct previous/next " + key, w.tab()["position"] == (before + delta) % 9)
    w.key("Alt+5")
    for key, delta in [("Alt+Shift+Left", -1), ("Alt+Shift+Right", 1)]:
      before = w.tab()["position"]
      w.key(key)
      w.check("direct move tab " + key, w.tab()["position"] == before + delta)
    for key, delta in [("h", -1), ("Left", -1), ("Up", -1), ("k", -1),
                       ("l", 1), ("Right", 1), ("Down", 1), ("j", 1)]:
      before = w.tab()["position"]
      mode(w, "t", key)
      w.check("native tab navigation " + key, w.tab()["position"] == (before + delta) % 9)
    w.key("Escape")
    mode(w, "t", "r")
    w.type("audit-tab")
    w.key("Return")
    w.check("tab rename accepts", w.tab()["name"] == "audit-tab")
    mode(w, "t", "r")
    w.type("cancelled")
    w.key("Escape")
    w.check("tab rename cancels", w.tab()["name"] == "audit-tab")
    w.key("Escape")
    for key in ("b", "]", "["):
      w.key("Alt+Shift+Return")
      pane = focused(w)["id"]
      old_tab = w.tab()["tab_id"]
      mode(w, "t", key)
      w.check("break pane " + key, next(p for p in w.panes() if p["id"] == pane and not p["is_plugin"])["tab_id"] != old_tab)
    before = len(w.tabs())
    mode(w, "t", "x")
    w.check("native close tab", len(w.tabs()) == before - 1)
    w.key("Ctrl+Space")
    w.key("c")
    w.check("prefix new tab", len(w.tabs()) == before)
    w.key("Ctrl+b")
    w.key("r")
    w.type("prefix-tab")
    w.key("Return")
    w.check("prefix rename tab", w.tab()["name"] == "prefix-tab")
    for key, delta in [("p", -1), ("n", 1)]:
      old = w.tab()["position"]
      w.key("Ctrl+Space")
      w.key(key)
      w.check("prefix tab " + key, w.tab()["position"] == (old + delta) % len(w.tabs()))


def groups():
  for key in ("Escape", "Tab", "s", "f", "e", "b", "l", "r", "c"):
    with Workspace(ROOT / ("groups-" + key)) as w:
      w.key("Alt+Shift+Return")
      selected = [p["id"] for p in w.terminals()]
      w.key("Alt+Return")
      if key == "e":
        for pane in selected:
          if f"terminal_{pane}" not in w.action("list-clients"):
            w.action("focus-pane-id", f"terminal_{pane}")
          w.action("toggle-pane-embed-or-floating")
      w.key("Alt+g")
      for pane in selected:
        if f"terminal_{pane}" not in w.action("list-clients"):
          w.action("focus-pane-id", f"terminal_{pane}")
        w.key("Alt+p")
      w.wait(lambda: bool(w.plugin("multiple-select")))
      w.check("group action menu opens", "2 SELECTED PANES" in w.text("multiple-select"))
      old = w.plugin("multiple-select")
      w.key(key)
      if key == "Tab":
        new = w.plugin("multiple-select")
        w.check("group Tab moves menu", (old["pane_x"], old["pane_y"]) != (new["pane_x"], new["pane_y"]))
        w.key("Escape")
      else:
        w.wait(lambda: not any(p.get("plugin_url") == "zellij:multiple-select" for p in w.panes()))
        terminals = [p for p in w.panes() if not p["is_plugin"]]
        if key == "c":
          # Zellij retains one terminal when a group closes the entire tab.
          w.check("group close removes selected panes", not any(p["id"] in selected for p in terminals))
        elif key in ("f", "e"):
          w.check("group " + key + " changes pane type", all(p["is_floating"] == (key == "f") for p in terminals if p["id"] in selected))
        elif key == "s":
          w.check("group stack changes layout", "stacked=true" in w.action("dump-layout"))
        elif key in ("b", "l", "r"):
          w.check("group break " + key, len(w.tabs()) >= 1 and len(terminals) >= 2)
        else:
          w.check("group Escape clears selection", all(not p["index_in_pane_group"] for p in terminals))


def resize():
  with Workspace(ROOT / "resize") as w:
    w.key("Alt+Shift+Return")
    w.key("Alt+Return")
    for key in ("h", "H", "l", "L", "j", "J", "k", "K", "Left", "Right", "Up", "Down", "=", "+", "-"):
      axis = "pane_x" if key.lower() in ("h", "l", "left", "right") else "pane_y"
      if key not in ("=", "+", "-"):
        candidates = [p for p in w.terminals() if p["pane_x"] > 0] if axis == "pane_y" else w.terminals()
        target = max(candidates, key=lambda p: p[axis]) if key.lower() in ("h", "k", "left", "up") else min(candidates, key=lambda p: p[axis])
        if f"terminal_{target['id']}" not in w.action("list-clients"):
          w.action("focus-pane-id", f"terminal_{target['id']}")
      before = geometry(w)
      mode(w, "n", key)
      w.check("resize " + key, geometry(w) != before)
    w.key("Escape")
    for key in ("Left", "Right", "Up", "Down"):
      axis = "pane_x" if key in ("Left", "Right") else "pane_y"
      candidates = [p for p in w.terminals() if p["pane_x"] > 0] if axis == "pane_y" else w.terminals()
      target = max(candidates, key=lambda p: p[axis]) if key in ("Left", "Up") else min(candidates, key=lambda p: p[axis])
      if f"terminal_{target['id']}" not in w.action("list-clients"):
        w.action("focus-pane-id", f"terminal_{target['id']}")
      before = geometry(w)
      w.key("Ctrl+Alt+Shift+" + key)
      w.check("direct resize " + key, geometry(w) != before)


def search():
  with Workspace(ROOT / "search", emulate=True) as w:
    w.type("for n in (seq 1 180); printf 'AUDIT_%03d needle NEEDLE needles\\n' $n; end")
    w.key("Return")
    time.sleep(.5)
    terminal = f"terminal_{focused(w)['id']}"
    w.enter("s")
    for key, down in [("Up", False), ("Down", True), ("k", False), ("j", True),
                      ("PageUp", False), ("PageDown", True), ("Left", False), ("Right", True),
                      ("Ctrl+b", False), ("Ctrl+f", True), ("h", False), ("l", True), ("u", False), ("d", True)]:
      # Start midway so scrolling in either direction has meaningful output.
      w.action("scroll-to-top")
      w.action("page-scroll-down")
      before = w.frame(terminal)
      w.key(key)
      w.check("scroll " + key, w.frame(terminal) != before)
    w.key("s")
    w.type("needlex")
    w.key("BackSpace")
    w.key("Return")
    w.check("search input edits and accepts", "Search down" in w.guide())

    def style(word):
      for row, text in enumerate(w.screen.display):
        if "needle NEEDLE needles" in text and "AUDIT_" in text:
          start = text.index(word) if word != "needles" else text.rindex(word)
          return tuple(w.screen.buffer[row][col].bg for col in range(start, start + 6))
      raise AssertionError("No search fixture row on the physical screen")

    for key, word, label in (("c", "NEEDLE", "case sensitivity"), ("o", "needles", "whole words")):
      before = style(word)
      w.key(key)
      w.check("search " + label + " changes match highlighting", style(word) != before)
    w.action("scroll-to-bottom")
    w.wait(lambda: any("AUDIT_180 " in row for row in w.screen.display))
    w.key("p")  # Select the final match from the current bottom viewport.
    before = tuple(w.screen.display)
    w.key("n")
    w.check("search stops at bottom with wrapping disabled", not any("AUDIT_001 " in row for row in w.screen.display))
    w.key("w")
    w.key("n")
    w.wait(lambda: any("AUDIT_001 " in row for row in w.screen.display))
    w.check("W enables wrapping to the first match")
    w.key("p")
    w.wait(lambda: any("AUDIT_180 " in row for row in w.screen.display))
    w.check("search previous wraps back to the final match")
    w.key("Ctrl+c")
    w.check("search Ctrl+C returns to application", w.locked())
    for cancel in ("Escape", "Ctrl+c"):
      w.enter("s")
      w.key("s")
      w.type("cancelled")
      w.key(cancel)
      w.check("search entry cancel " + cancel, "Scroll half page" in w.guide())
      w.key("Escape")


def helpers():
  with Workspace(ROOT / "helpers") as w:
    w.key("Ctrl+Space")
    w.key("C")
    w.wait(lambda: any(p["is_floating"] and not p["is_plugin"] for p in w.panes()))
    pane = next(p for p in w.panes() if p["is_floating"] and not p["is_plugin"])
    w.wait(lambda: "New session" in w.frame(f"terminal_{pane['id']}"))
    w.type("helper-newx")
    w.key("BackSpace")
    w.key("Return")
    w.session = "helper-new"
    w.wait(lambda: len(w.terminals()) > 0, 15)
    w.check("prefix C creates and attaches a named session")
    w.key("Ctrl+b")
    w.key("R")
    w.wait(lambda: any(p["is_floating"] and not p["is_plugin"] for p in w.panes()))
    pane = next(p for p in w.panes() if p["is_floating"] and not p["is_plugin"])
    w.wait(lambda: "Rename session" in w.frame(f"terminal_{pane['id']}"))
    w.key("Ctrl+u")
    w.type("helper-renamed")
    w.key("Return")
    w.session = "helper-renamed"
    w.wait(lambda: len(w.terminals()) > 0, 15)
    w.check("prefix R renames the session")
    for keys, target in [(("Alt+Down",), "audit"), (("Alt+Up",), "helper-renamed"),
                          (("Ctrl+Space", "N"), "audit"), (("Ctrl+b", "P"), "helper-renamed")]:
      for key in keys:
        w.key(key)
      w.session = target
      w.wait(lambda: len(w.terminals()) > 0 and "terminal_" in w.action("list-clients"), 15)
      w.check("session cycle " + ", ".join(keys))
    w.key("Ctrl+Space")
    w.key("?")
    w.wait(lambda: any(p["is_floating"] and not p["is_plugin"] for p in w.panes()))
    pane = next(p for p in w.panes() if p["is_floating"] and not p["is_plugin"])
    w.wait(lambda: "Zellij" in w.frame(f"terminal_{pane['id']}"))
    w.key("q")
    w.wait(lambda: not any(p["is_floating"] and not p["is_plugin"] for p in w.panes()))
    w.check("prefix ? opens a readable reference and q closes it")
    w.key("Ctrl+b")
    w.key("d")
    w.wait(lambda: w.proc.poll() is not None)
    w.check("prefix d detaches while session stays live", "EXITED" not in w.cli("list-sessions", "--no-formatting").stdout)


def scroll_commands():
  w = Workspace(ROOT / "scroll-commands")
  copy = w.root / "copy"
  clipboard = w.root / "clipboard.txt"
  copy.write_text(f"#!/bin/bash\ncat > '{clipboard}'\n")
  copy.chmod(0o700)
  w.config.write_text(w.config.read_text().replace('copy_command "wl-copy"', f'copy_command "{copy}"'))
  emitter = w.root / "emit.py"
  emitter.write_text("import sys\n" + "\n".join(
    f"sys.stdout.write({content!r})"
    for content in [
      "\x1b]133;A\x07AUDIT_PROMPT_ONE \x1b]133;B\x07first\x1b]133;C\x07\r\n" + "FIRST_OUTPUT\r\n" * 80 + "\x1b]133;D;0\x07",
      "\x1b]133;A\x07AUDIT_PROMPT_TWO \x1b]133;B\x07second\x1b]133;C\x07\r\n" + "SECOND_OUTPUT\r\n" * 80 + "\x1b]133;D;0\x07",
    ]
  ))
  with w:
    w.type("python3 " + str(emitter))
    w.key("Return")
    w.wait(lambda: "SECOND_OUTPUT" in w.frame("terminal_0"))
    w.enter("s")
    w.key("c")
    w.wait(lambda: clipboard.exists())
    w.check("scroll C copies command output to private clipboard", "SECOND_OUTPUT" in clipboard.read_text())
    w.check("copy restores application input", w.locked())
    w.enter("s")
    before = w.frame("terminal_0")
    w.key("[")
    w.key("[")
    w.check("previous prompt navigation", w.frame("terminal_0") != before)
    before = w.frame("terminal_0")
    w.key("]")
    w.check("next prompt navigation", w.frame("terminal_0") != before)
    w.key("m")
    w.check("select command retains scroll controls", "Scroll half page" in w.guide())
    w.key("Escape")
    w.enter("s")
    before = {p["id"] for p in w.terminals()}
    w.key("e")
    w.wait(lambda: any(p["id"] not in before for p in w.terminals()))
    w.check("scroll E opens the configured editor", any("nvim" in str(p.get("pane_command")) for p in w.terminals()))
    w.type(":q!")
    w.key("Return")
    w.wait(lambda: {p["id"] for p in w.terminals()} == before)
    w.check("scrollback editor accepts keys and closes")


def aliases():
  with Workspace(ROOT / "aliases", answer_queries=True) as w:
    for key in ("h", "v"):
      old = len(w.terminals())
      w.key("Ctrl+Space")
      w.key(key)
      w.wait(lambda: len(w.terminals()) == old + 1)
      w.check("prefix split " + key)
    for key in ("z", "z"):
      before = focused(w)["is_fullscreen"]
      w.key("Ctrl+b")
      w.key(key)
      w.check("prefix zoom", focused(w)["is_fullscreen"] != before)
    for key in ("{", "}"):
      before = geometry(w)
      w.key("Ctrl+Space")
      w.key(key)
      w.check("prefix move " + key, geometry(w) != before)
    w.key("Alt+Escape")
    w.check("direct close pane", len(w.terminals()) == 2)
    w.key("Ctrl+Space")
    w.key("[")
    w.check("prefix enters scroll mode", "Scroll half page" in w.guide())
    w.key("Escape")
    w.action("new-tab")
    w.key("Ctrl+b")
    w.key("Tab")
    w.check("prefix last-tab toggle", w.tab()["position"] == 0)
    w.enter("o")
    w.key("d")
    w.wait(lambda: w.proc.poll() is not None)
    w.check("native session D detaches")
    w.start(resurrect=True)
    w.key("Alt+g")
    w.key("Ctrl+q")
    w.wait(lambda: w.proc.poll() is not None)
    w.check("native Ctrl+Q quits only the private session")


if __name__ == "__main__":
  for group in sys.argv[1:] or ("panes", "tabs", "groups", "resize", "search", "helpers", "scroll_commands", "aliases"):
    globals()[group]()
