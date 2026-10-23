"""Private Zellij workspace for integration checks; no desktop focus is taken."""

import fcntl
import codecs
import errno
import json
import os
from pathlib import Path
import re
import shutil
import struct
import subprocess
import tempfile
import termios
import threading
import time


class Workspace:
  def __init__(self, evidence, extra="", log=True, temp_parent=None, emulate=False, answer_queries=False):
    self.root = Path(tempfile.mkdtemp(prefix=".zj-audit-", dir=temp_parent))
    self.evidence = Path(evidence)
    self.evidence.mkdir(parents=True, exist_ok=True)
    self.source = Path(__file__).resolve().parents[1] / "config/zellij"
    self.exe = shutil.which("zellij")
    self.session = "audit"
    self.clients = []
    self.results = []
    self.logging = log
    self.emulate = emulate
    self.answer_queries = answer_queries
    if emulate:
      import pyte
      self.screen = pyte.Screen(265, 57)
      # Zellij emits private status queries newer than pyte supports.
      self.screen.report_device_status = lambda *args, **kwargs: None
      self.screen.report_device_attributes = lambda *args, **kwargs: None
      self.stream = pyte.Stream(self.screen)
    for name in ("config", "cache", "data", "runtime", "sockets", "layouts", "files"):
      (self.root / name).mkdir(mode=0o700)
    shutil.copytree(self.source / "layouts", self.root / "layouts", dirs_exist_ok=True)
    shutil.copytree(self.source / "plugins", self.root / "config/zellij/plugins", dirs_exist_ok=True)
    for layout in (self.root / "layouts").glob("*.kdl"):
      layout.write_text(layout.read_text().replace("file:~/.config/zellij/plugins/", f"file:{self.root / 'config/zellij/plugins'}/"))
    self.original = (self.source / "config.kdl").read_text()
    self.config = self.root / "config.kdl"
    self.config.write_text(self.original.replace("file:~/.config/zellij/plugins/", f"file:{self.root / 'config/zellij/plugins'}/") + f'\nlayout_dir "{self.root / "layouts"}"\n' + extra)
    self.env = os.environ.copy()
    self.env.pop("ZELLIJ", None)
    self.env.pop("ZELLIJ_SESSION_NAME", None)
    self.env.update(
      XDG_CONFIG_HOME=str(self.root / "config"), XDG_CACHE_HOME=str(self.root / "cache"),
      XDG_DATA_HOME=str(self.root / "data"), XDG_RUNTIME_DIR=str(self.root / "runtime"),
      ZELLIJ_SOCKET_DIR=str(self.root / "sockets"), ZELLIJ_CONFIG_DIR=str(self.root),
      ZELLIJ_CONFIG_FILE=str(self.config), TERM="xterm-256color", EDITOR="nvim", VISUAL="nvim",
      PATH=str(self.source.parents[1] / "bin") + ":" + os.environ["PATH"],
    )
    self.cwd = self.root
    self.proc = None
    self.master = None

  def cli(self, *args, check=True):
    result = subprocess.run([self.exe, *args], env=self.env, text=True,
                            capture_output=True, timeout=15)
    if check and result.returncode:
      raise AssertionError(result.stderr + result.stdout)
    return result

  def action(self, *args, session=None):
    return self.cli("--session", session or self.session, "action", *args).stdout

  def panes(self):
    return json.loads(self.action("list-panes", "--all", "--json"))

  def tabs(self):
    return json.loads(self.action("list-tabs", "--all", "--json"))

  def tab(self):
    return next(t for t in self.tabs() if t["active"])

  def terminals(self):
    tab = self.tab()["tab_id"]
    return [p for p in self.panes() if not p["is_plugin"] and p["tab_id"] == tab]

  def frame(self, pane, ansi=False, session=None):
    result = subprocess.run(
      ["timeout", ".15", self.exe, "--session", session or self.session, "subscribe",
       "--pane-id", pane, "--format", "raw" if ansi else "json", *(["--ansi"] if ansi else [])], env=self.env, text=True, capture_output=True,
    )
    if ansi:
      if not result.stdout:
        raise AssertionError(f"No ANSI frame for {pane}")
      return result.stdout
    frames = [json.loads(line) for line in result.stdout.splitlines() if line.startswith("{")]
    if not frames:
      raise AssertionError(f"No frame for {pane}: {result.stderr}")
    return "\n".join(frames[-1]["viewport"])

  def plugin(self, name):
    return next(p for p in sorted(self.panes(), key=lambda p: p["tab_id"] == self.tab()["tab_id"], reverse=True) if p.get("plugin_url") in (name, "zellij:" + name, "filepicker" if name == "strider" else name) or str(p.get("plugin_url", "")).endswith("/" + name + ".wasm"))

  def pid(self, name):
    return f"plugin_{self.plugin(name)['id']}"

  def text(self, name):
    if name == "status-bar" and self.plugin(name)["is_suppressed"]:
      return ""
    return self.frame(self.pid(name))

  def guide(self):
    info = self.plugin("status-bar")
    return "" if info["is_suppressed"] else self.frame(f"plugin_{info['id']}")

  def locked(self):
    text = self.guide()
    return not text.strip() or "INTERFACE LOCKED" in text

  def key(self, value, pause=.12):
    parts = ["+"] if value == "+" else value.split("+")
    name = parts[-1]
    mods = parts[:-1]
    aliases = {"Return": b"\r", "Escape": b"\x1b", "Tab": b"\t", "BackSpace": b"\x7f",
               "Space": b" ", "Up": b"\x1b[A", "Down": b"\x1b[B", "Left": b"\x1b[D",
               "Right": b"\x1b[C", "Home": b"\x1b[H", "End": b"\x1b[F",
               "Delete": b"\x1b[3~", "PageUp": b"\x1b[5~", "PageDown": b"\x1b[6~"}
    data = aliases.get(name, name.encode())
    if mods == ["Shift"] and name == "Tab":
      data = b"\x1b[Z"
    elif mods == ["Ctrl"] and (len(name) == 1 or name == "Space"):
      data = bytes([ord(" " if name == "Space" else name) & 31])
    elif mods == ["Alt"] and name == "Escape":
      data = b"\x1b[27;3u"
    elif mods == ["Alt"]:
      data = b"\x1b" + data
    elif mods:
      modifier = 1 + sum({"Shift": 1, "Alt": 2, "Ctrl": 4, "Super": 8}[m] for m in mods)
      if name in ("Up", "Down", "Left", "Right", "Home", "End"):
        data = f"\x1b[1;{modifier}{chr(aliases[name][-1])}".encode()
      elif name in ("BackSpace", "Delete"):
        data = f"\x1b[{'127' if name == 'BackSpace' else '57349'};{modifier}u".encode()
      else:
        code = {"Return": 13, "Space": 32, "Tab": 9, "Escape": 27}.get(name, ord(name) if len(name) == 1 else 0)
        data = f"\x1b[{code};{modifier}u".encode()
    os.write(self.master, data)
    time.sleep(pause)

  def type(self, value):
    os.write(self.master, value.encode())
    time.sleep(.15)

  def enter(self, key):
    if self.locked():
      self.key("Alt+g")
    self.key("Ctrl+" + key)

  def open(self, name):
    self.enter("o")
    self.key({"session-manager": "w", "plugin-manager": "p", "configuration": "c",
              "about": "a", "share": "s", "layout-manager": "v"}[name])
    self.wait(lambda: bool(self.plugin(name)))
    self.wait(lambda: bool(self.text(name)))
    if "Allow? (y/n)" in self.text(name):
      self.key("y")
      self.wait(lambda: "Allow? (y/n)" not in self.text(name))
    return self.text(name)

  def close(self, name):
    self.action("close-pane", "--pane-id", self.pid(name))

  def wait(self, predicate, seconds=5):
    until = time.monotonic() + seconds
    while time.monotonic() < until:
      try:
        if predicate():
          return
      except (AssertionError, StopIteration, ValueError, subprocess.TimeoutExpired):
        pass
      time.sleep(.08)
    raise AssertionError("State did not settle")

  def check(self, label, condition=True):
    if not condition:
      raise AssertionError(label)
    self.results.append(label)
    (self.evidence / "checks.json").write_text(json.dumps(self.results, indent=2))
    print("PASS", label, flush=True)

  def snapshot(self, name, tag):
    (self.evidence / (tag + ".txt")).write_text(self.text(name))

  def start(self, name=None, resurrect=False, launcher=False):
    name = name or self.session
    master, slave = os.openpty()
    fcntl.ioctl(slave, termios.TIOCSWINSZ, struct.pack("HHHH", 57, 265, 0, 0))

    def prepare():
      os.setsid()
      fcntl.ioctl(slave, termios.TIOCSCTTY, 0)

    command = [str(self.source.parents[1] / "bin/zanken-launch-zellij"), name] if launcher else (
      [self.exe, "attach", "--create", name] if resurrect else [self.exe, "--session", name]
    )
    proc = subprocess.Popen(command, env=self.env, cwd=self.cwd,
                            stdin=slave, stdout=slave, stderr=slave, preexec_fn=prepare)
    os.close(slave)
    self.clients.append((proc, master))
    self.proc, self.master = proc, master

    def drain():
      log = (self.evidence / (name + ".ansi")).open("wb") if self.logging else None
      decoder = codecs.getincrementaldecoder("utf-8")("replace")
      query_tail = b""
      try:
        while True:
          data = os.read(master, 65536)
          if not data:
            break
          if log:
            log.write(data)
          if self.answer_queries:
            query_data = query_tail + data
            device_queries = query_data.count(b"\x1b[c")
            query_tail = query_data[-2:]
            if device_queries:
              os.write(master, b"\x1b[?1;2c" * device_queries)
          if self.emulate:
            self.stream.feed(decoder.decode(data))
      except OSError:
        pass
      finally:
        if log:
          log.close()

    threading.Thread(target=drain, daemon=True).start()
    # A CLI probe before this version initializes SessionData can panic its
    # server when that short-lived client disconnects. Let startup settle first.
    time.sleep(.35)
    self.wait(lambda: "status-bar" in self.action("list-panes", "--all", "--json", session=name), 10)
    # A detached server can answer before the new frontend has attached.
    self.wait(lambda: any(tab["active"] for tab in self.tabs()), 10)
    status = self.plugin("status-bar")
    stable = 0
    until = time.monotonic() + 8
    while stable < 4 and time.monotonic() < until:
      # A background guide may request permissions before it has a visible pane.
      self.action("send-keys", "--pane-id", f"plugin_{status['id']}", "y")
      text = self.guide()
      if "permission" in text.lower():
        self.action("send-keys", "--pane-id", f"plugin_{status['id']}", "y")
        stable = 0
      elif "INTERFACE LOCKED" in text or not text.strip():
        stable += 1
      else:
        stable = 0
      time.sleep(.15)
    if stable != 4:
      (self.evidence / (name + "-startup-guide.txt")).write_text(text)
      (self.evidence / (name + "-startup-panes.json")).write_text(self.action("list-panes", "--all", "--json"))
    assert stable == 4, "Status bar did not finish permission initialization: " + text[:200]
    try:
      top = self.plugin("zjstatus")
    except StopIteration:
      top = None
    if top:
      def top_ready():
        text = self.text("zjstatus")
        if "permission" in text.lower():
          self.action("send-keys", "--pane-id", f"plugin_{top['id']}", "y")
          return False
        return bool(text.strip()) and "Loading" not in text
      self.wait(top_ready, 10)
    self.check("private session namespace", "main [" not in self.cli("list-sessions", "--no-formatting").stdout)
    return proc, master

  def __enter__(self):
    try:
      self.start()
    except BaseException as error:
      self.__exit__(type(error), error, error.__traceback__)
      raise
    return self

  def __exit__(self, kind, value, trace):
    if kind is not None and self.logging:
      try:
        (self.evidence / "failure-panes.json").write_text(json.dumps(self.panes(), indent=2))
        for pane in self.panes():
          kind_name = "plugin" if pane["is_plugin"] else "terminal"
          (self.evidence / f"failure-{kind_name}-{pane['id']}.txt").write_text(self.frame(f"{kind_name}_{pane['id']}"))
      except Exception:
        pass
    # The socket namespace is private; only sessions created in this fixture appear.
    listing = self.cli("list-sessions", "--no-formatting", check=False).stdout
    for line in listing.splitlines():
      name = re.split(r" \[Created", line)[0].strip()
      if name:
        self.cli("kill-session", name, check=False)
    for proc, master in self.clients:
      if proc.poll() is None:
        proc.terminate()
      try:
        proc.wait(timeout=3)
      except subprocess.TimeoutExpired:
        proc.kill()
        proc.wait()
      os.close(master)
    if kind is None:
      for attempt in range(5):
        try:
          shutil.rmtree(self.root)
          break
        except OSError as error:
          if error.errno != errno.ENOTEMPTY or attempt == 4:
            raise
          # Fish completion-cache writers can finish just after session exit.
          time.sleep(.2)
    else:
      print("Failure fixture retained:", self.root, flush=True)
