"""Run inside a private D-Bus session: verify real Quickshell generation reload."""

import os
from pathlib import Path
import subprocess
import tempfile
import time


with tempfile.TemporaryDirectory(prefix="zanken-qs-check-") as directory:
  root = Path(directory)
  runtime = root / "runtime"
  runtime.mkdir(mode=0o700)
  config = root / "config"
  (config / "quickshell").mkdir(parents=True)
  for number in (1, 2):
    generation = root / str(number)
    generation.mkdir()
    (generation / "shell.qml").write_text('''import Quickshell
import Quickshell.Io
ShellRoot {
  IpcHandler {
    target: "zanken"
    function reload(): void { Quickshell.reload(false); }
    function releaseIdentity(): string { return "%s"; }
  }
}
''' % number)
  (root / "current").symlink_to(root / "1")
  (config / "quickshell/zanken").symlink_to(root / "current")
  environment = {**os.environ, "XDG_RUNTIME_DIR": str(runtime), "XDG_CONFIG_HOME": str(config),
                 "QT_QPA_PLATFORM": "offscreen", "QS_NO_RELOAD_POPUP": "1"}
  environment.pop("WAYLAND_DISPLAY", None)
  environment.pop("DISPLAY", None)
  with (root / "qs.log").open("w+") as log:
    process = subprocess.Popen(["qs", "-c", "zanken"], env=environment, stdout=log, stderr=log)
    try:
      def call(method):
        return subprocess.run(["qs", "-c", "zanken", "ipc", "call", "zanken", method],
                              env=environment, text=True, capture_output=True, timeout=5)

      def await_identity(expected):
        deadline = time.monotonic() + 6
        result = None
        while time.monotonic() < deadline:
          result = call("releaseIdentity")
          if result.returncode == 0 and result.stdout.strip().strip('"') == expected:
            return
          time.sleep(0.1)
        log.seek(0)
        raise AssertionError(f"Expected identity {expected}: {result.stdout} {result.stderr}\n{log.read()}")

      await_identity("1")
      (root / "next").symlink_to(root / "2")
      os.replace(root / "next", root / "current")
      call("reload")
      await_identity("2")
      assert process.poll() is None, "Quickshell process restarted"
      print("Quickshell changed generation with the same process")
    finally:
      process.terminate()
      try:
        process.wait(timeout=5)
      except subprocess.TimeoutExpired:
        process.kill()
        process.wait()
