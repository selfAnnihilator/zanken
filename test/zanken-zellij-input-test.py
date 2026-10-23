"""PTY integration regression: locked-default actions must restore input.

Run with python3; --config can check an older configuration as a negative control.
All sessions, layouts and plugin configuration used here are temporary.
"""

import argparse
import fcntl
import json
import os
from pathlib import Path
import shutil
import subprocess
import struct
import tempfile
import termios
import threading
import time


def main():
  parser = argparse.ArgumentParser(description=__doc__)
  source = Path(__file__).resolve().parents[1] / "config/zellij"
  parser.add_argument("--config", type=Path, default=source / "config.kdl")
  parser.add_argument("--popup", choices=["layout-manager", "session-manager", "plugin-manager",
                                         "configuration", "about", "share"])
  args = parser.parse_args()
  for executable in ("zellij", "fish", "nvim"):
    if not shutil.which(executable):
      raise SystemExit(f"Requires {executable}")

  session = f"zanken-input-test-{time.time_ns()}"
  env = os.environ.copy()
  env.pop("ZELLIJ", None)
  env.pop("ZELLIJ_SESSION_NAME", None)
  zellij = shutil.which("zellij")
  client = None
  master = None
  completed = False
  try:
    with tempfile.TemporaryDirectory(prefix="zanken-zellij-input-", delete=False) as directory:
      config = Path(directory)
      env.update(
        XDG_CONFIG_HOME=str(config / "xdg-config"),
        XDG_CACHE_HOME=str(config / "xdg-cache"),
        XDG_DATA_HOME=str(config / "xdg-data"),
        XDG_RUNTIME_DIR=str(config / "runtime"),
        ZELLIJ_SOCKET_DIR=str(config / "sockets"),
        ZELLIJ_CONFIG_DIR=directory,
        ZELLIJ_CONFIG_FILE=str(config / "config.kdl"),
        TERM="xterm-256color", EDITOR="nvim", VISUAL="nvim",
      )
      # Runtime plugin APIs need an explicit layout_dir, not just --config-dir.
      (config / "config.kdl").write_text(
        args.config.read_text().replace("file:~/.config/zellij/plugins/", f"file:{config / 'plugins'}/") + f'\nlayout_dir "{config / "layouts"}"\n'
      )
      shutil.copytree(source / "layouts", config / "layouts")
      shutil.copytree(source / "plugins", config / "plugins")
      template = (source / "layouts/zanken.kdl").read_text()
      for count, name in [(2, "input-two"), (3, "input-three")]:
        body = "  tab {\n" + "".join(f'    pane name="INPUT_{i}"\n' for i in range(count)) + "  }"
        layout = template.replace("  tab {\n    pane\n  }", body)
        (config / "layouts" / f"{name}.kdl").write_text(layout)
      command = [zellij, "--config-dir", directory, "--session", session]

      def action(*values):
        for _ in range(15):
          result = subprocess.run(command + ["action", *values], env=env, capture_output=True, text=True)
          if result.returncode == 0:
            return result.stdout
          if "There is no active session" not in result.stderr:
            break
          time.sleep(.2)
        raise AssertionError(result.stderr + result.stdout)

      def panes():
        return json.loads(action("list-panes", "--all", "--json"))

      def viewport(pane):
        result = subprocess.run(
          ["timeout", ".3", *command, "subscribe", "--pane-id", pane, "--format", "json"],
          env=env, capture_output=True, text=True,
        )
        frames = [json.loads(line) for line in result.stdout.splitlines() if line.startswith("{")]
        if not frames:
          for _ in range(12):
            time.sleep(.15)
            result = subprocess.run(["timeout", ".3", *command, "subscribe", "--pane-id", pane, "--format", "json"], env=env, capture_output=True, text=True)
            frames = [json.loads(line) for line in result.stdout.splitlines() if line.startswith("{")]
            if frames:
              break
        assert frames, f"No viewport for {pane}"
        return "\n".join(frames[-1]["viewport"])

      def key(value):
        parts = value.split("+")
        keys = {"Return": b"\r", "Escape": b"\x1b", "Tab": b"\t", "BackSpace": b"\x7f",
                "Up": b"\x1b[A", "Down": b"\x1b[B", "End": b"\x1b[F",
                "Delete": b"\x1b[3~", "slash": b"/", "question": b"?"}
        value = keys.get(parts[-1], parts[-1].encode())
        if "Ctrl" in parts[:-1]:
          value = bytes([ord(parts[-1]) & 31])
        if "Alt" in parts[:-1]:
          value = b"\x1b" + value
        os.write(master, value)
        time.sleep(.15)

      def type_text(value):
        os.write(master, value.encode())
        time.sleep(.25)

      def manage_layout(pane):
        # Escape first clears search text, then leaves the search field.
        for _ in range(4):
          if not any(line.strip().startswith("Layout:") for line in viewport(pane).splitlines()):
            return
          key("Escape")
        raise AssertionError("Layout Manager did not leave search mode: " + viewport(pane))

      def guide():
        current = next(t["tab_id"] for t in json.loads(action("list-tabs", "--all", "--json")) if t["active"])
        status = next(p for p in panes() if (p.get("plugin_url") in ("status-bar", "zellij:status-bar") or str(p.get("plugin_url")).endswith("/status-bar.wasm")) and p["tab_id"] == current)
        return viewport(f"plugin_{status['id']}")

      def locked():
        text = guide()
        return not text.strip() or "INTERFACE LOCKED" in text

      def enter(mode_key):
        if locked():
          key("Alt+g")
        key(f"Ctrl+{mode_key}")

      master, slave = os.openpty()
      fcntl.ioctl(slave, termios.TIOCSWINSZ, struct.pack("HHHH", 57, 265, 0, 0))

      def prepare_terminal():
        os.setsid()
        fcntl.ioctl(slave, termios.TIOCSCTTY, 0)

      client = subprocess.Popen(command, env=env, cwd=directory, stdin=slave,
                                stdout=slave, stderr=slave, preexec_fn=prepare_terminal)
      os.close(slave)

      def drain_terminal():
        with (config / "terminal.log").open("wb") as log:
          while True:
            try:
              data = os.read(master, 65536)
            except OSError:
              break
            if not data:
              break
            log.write(data)

      threading.Thread(target=drain_terminal, daemon=True).start()
      for _ in range(100):
        ready = subprocess.run(command + ["action", "list-panes", "--json", "--all"],
                               env=env, text=True, capture_output=True)
        if ready.returncode == 0 and "status-bar" in ready.stdout:
          break
        time.sleep(.1)
      else:
        raise AssertionError("Test terminal session did not start: " + ready.stderr + ready.stdout)
      status = next(p for p in panes() if str(p.get("plugin_url")).removeprefix("zellij:") == "status-bar" or str(p.get("plugin_url")).endswith("/status-bar.wasm"))
      stable = 0
      for _ in range(30):
        text = viewport(f"plugin_{status['id']}")
        if "permission" in text.lower():
          action("send-keys", "--pane-id", f"plugin_{status['id']}", "y")
          stable = 0
        elif "INTERFACE LOCKED" in text or not text.strip():
          stable += 1
          if stable == 4:
            break
        time.sleep(.15)
      assert stable == 4, "Guide permission initialization did not settle"

      enter("p")
      key("r")
      assert locked(), "Native split left application input disabled"
      time.sleep(.8)
      type_text("printf '%s\\n' ZANKEN_APP_INPUT_OK")
      key("Return")
      screen = action("dump-screen")
      assert "ZANKEN_APP_INPUT_OK" in screen.splitlines(), "New pane cannot run typed input: " + screen
      print("PASS native split restores application input", flush=True)

      for mode_key in ("p", "t", "n", "h", "s", "o"):
        for exit_key in ("Escape", "Return"):
          enter(mode_key)
          key(exit_key)
          assert locked(), f"Ctrl+{mode_key} / {exit_key} did not restore input"
      print("PASS Enter and Escape leave all six guide modes for application input", flush=True)

      for shortcut, name in [("v", "layout-manager"), ("w", "session-manager"),
                             ("p", "plugin-manager"), ("c", "configuration"),
                             ("a", "about"), ("s", "share")]:
        if args.popup and args.popup != name:
          continue
        enter("o")
        key(shortcut)
        time.sleep(.4)
        plugin = next(p for p in panes() if p.get("plugin_url") == f"zellij:{name}" or str(p.get("plugin_url")).endswith("/" + name + ".wasm"))
        assert locked(), f"{name} opened with its keyboard input disabled"
        pane = f"plugin_{plugin['id']}"
        if "Allow? (y/n)" in viewport(pane):
          key("y")
          time.sleep(.4)
        if name == "layout-manager":
          assert "input-three" in viewport(pane) and "input-two" in viewport(pane), "Test layouts are not isolated"
          type_text("zanken")
          text = viewport(pane)
          assert any("Layout:" in line and "zanken" in line for line in text.splitlines()), text
          manage_layout(pane)
          key("slash")
          type_text("defaul")
          key("Tab")
          text = viewport(pane)
          assert any("Layout:" in line and "default" in line for line in text.splitlines()), text
          key("BackSpace")
          assert any("Layout:" in line and "defaul" in line for line in viewport(pane).splitlines())
          manage_layout(pane)
          before = viewport(pane)
          key("Down")
          assert viewport(pane) != before, "Layout navigation did not change the pane preview"
          key("Up")
          assert viewport(pane) == before, "Layout Up did not restore the previous preview"
          key("question")
          assert "Retain:" in viewport(pane), "More options did not open"
          before = viewport(pane)
          key("t")
          assert viewport(pane) != before, "Retain option did not change"
          for _ in range(3):
            key("t")
          key("a")
          assert viewport(pane) != before, "Apply target did not change"
          key("a")
          key("question")
          print("PASS layout navigation, search, completion, Backspace and options", flush=True)

          key("r")
          assert "Rename Layout:" in viewport(pane)
          # Some versions put the full layout path in the rename field.
          os.write(master, b"\x1b[F" + b"\x7f" * 256)
          time.sleep(.3)
          type_text("input-renamed")
          key("Return")
          assert (config / "layouts/input-renamed.kdl").is_file(), "Layout rename was not saved: " + viewport(pane)
          manage_layout(pane)
          key("Delete")
          assert not (config / "layouts/input-renamed.kdl").exists(), "Layout delete failed"
          print("PASS layout rename and delete on temporary copies", flush=True)

          key("n")
          assert "Save Layout of Current Session" in viewport(pane)
          key("Tab")
          key("r")
          type_text("input-saved")
          key("Return")
          key("Return")
          assert (config / "layouts/input-saved.kdl").is_file(), "Saving the session layout failed"
          manage_layout(pane)
          key("i")
          assert "Import" in viewport(pane), "Import layout screen did not open"
          action("paste", "--pane-id", pane, template)
          key("r")
          type_text("input-imported")
          key("Return")
          key("Return")
          assert (config / "layouts/input-imported.kdl").is_file(), "Importing a pasted layout failed"
          print("PASS new layout and import save", flush=True)

          # The popup starts each operation in search mode.
          type_text("input-two")
          old_tabs = json.loads(action("list-tabs", "--all", "--json"))
          key("Return")
          time.sleep(.4)
          new_tabs = json.loads(action("list-tabs", "--all", "--json"))
          assert len(new_tabs) == len(old_tabs) + 1, "Enter did not open the selected layout"
          assert len([p for p in panes() if not p["is_plugin"] and p["tab_id"] == next(t["tab_id"] for t in new_tabs if t["active"])]) == 2
          print("PASS Enter opens selected layout as a tab", flush=True)
          action("close-tab")
          enter("o")
          key("v")
          time.sleep(.4)
          plugin = next(p for p in panes() if str(p.get("plugin_url")).endswith("/layout-manager.wasm"))
          pane = f"plugin_{plugin['id']}"
          type_text("input-two")
          manage_layout(pane)
          # Select a writable fixture in management mode before Edit.
          before_ids = {p["id"] for p in panes() if not p["is_plugin"]}
          key("e")
          time.sleep(.5)
          editors = [p for p in panes() if not p["is_plugin"] and p["id"] not in before_ids]
          assert editors, "Edit did not open a terminal editor"
          assert any(".kdl" in str(p.get("pane_command", "")) for p in editors), editors
          for editor in editors:
            action("close-pane", "--pane-id", f"terminal_{editor['id']}")
          print("PASS Edit opens the selected temporary layout", flush=True)
          # Relaunch after the editor, then apply only inside this test session.
          enter("o")
          key("v")
          time.sleep(.3)
          plugin = next(p for p in panes() if str(p.get("plugin_url")).endswith("/layout-manager.wasm"))
          pane = f"plugin_{plugin['id']}"
          # Close/reopen resets any retained search state.
          action("close-pane", "--pane-id", pane)
          enter("o")
          key("v")
          time.sleep(.3)
          type_text("input-two")
          key("Alt+w")
          time.sleep(.5)
          active = next(t for t in json.loads(action("list-tabs", "--all", "--json")) if t["active"])
          applied = [p for p in panes() if not p["is_plugin"] and p["tab_id"] == active["tab_id"]]
          assert len(applied) == 2 and len({p["pane_x"] for p in applied}) == 1 and len({p["pane_y"] for p in applied}) == 2, applied
          print("PASS Alt+W applies the layout to the temporary session", flush=True)
          continue
        elif name in ("session-manager", "plugin-manager"):
          pane = f"plugin_{plugin['id']}"
          before = viewport(pane)
          type_text("zanken")
          assert viewport(pane) != before, f"{name} search did not respond"
          key("BackSpace")
          key("Escape")
          if name == "plugin-manager":
            key("Ctrl+a")
            assert "URL" in viewport(pane) or "Url" in viewport(pane), "Add plugin did not open"
            type_text("zellij:about")
            assert "zellij:about" in viewport(pane), "Plugin URL input failed"
        elif name == "about":
          pane = f"plugin_{plugin['id']}"
          for _ in range(5):
            key("Down")
          key("Return")
          assert "New UI" in viewport(pane), "About page navigation did not respond"
          key("Escape")
          assert "Title frames" not in viewport(pane), "Escape did not leave the About detail page"
        elif name == "configuration":
          pane = f"plugin_{plugin['id']}"
          before = viewport(pane)
          key("Tab")
          assert viewport(pane) != before, "Configuration tab navigation did not respond"
        elif name == "share":
          # No server is enabled by this test; verify its disabled state is shown.
          assert "server" in viewport(f"plugin_{plugin['id']}").lower()
        print(f"PASS {name} {'disabled-server notice' if name == 'share' else 'internal controls'}", flush=True)
        action("close-pane", "--pane-id", f"plugin_{plugin['id']}")
        time.sleep(.2)
      completed = True
  finally:
    subprocess.run([zellij, "kill-session", session], env=env, capture_output=True)
    if client is not None:
      if client.poll() is None:
        client.terminate()
      client.wait(timeout=5)
    subprocess.run([zellij, "delete-session", session], env=env, capture_output=True)
    if master is not None:
      os.close(master)
    if completed:
      shutil.rmtree(directory)
    else:
      print(f"Test configuration retained for diagnosis: {directory}", flush=True)


if __name__ == "__main__":
  main()
