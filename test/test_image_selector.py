"""Keep the wallpaper picker responsive with a large, uncached collection."""
import os
from pathlib import Path
import socket
import subprocess
import tempfile
import threading
import time
import unittest


ROOT = Path(__file__).resolve().parents[1]


class ImageSelectorTests(unittest.TestCase):
  def test_lazy_open_does_not_fork_a_converter_for_every_wallpaper(self):
    with tempfile.TemporaryDirectory() as directory:
      base = Path(directory)
      home = base / 'home'
      images = home / 'Pictures' / 'wallpaper'
      tools = base / 'tools'
      runtime = base / 'runtime'
      images.mkdir(parents=True)
      tools.mkdir()
      runtime.mkdir()
      for index in range(24):
        (images / f'wallpaper-{index:02}.jpg').write_bytes(b'fixture')

      events = base / 'conversions.log'
      converter = tools / 'magick'
      converter.write_text('#!/bin/bash\n'
        'printf "start %s\\n" "$BASHPID" >> "$CONVERSION_EVENTS"\n'
        'sleep 0.25\n'
        'printf "done %s\\n" "$BASHPID" >> "$CONVERSION_EVENTS"\n'
        'printf fixture > "${@: -1}"\n')
      converter.chmod(0o755)

      socket_path = runtime / 'zanken-image-selector.sock'
      server = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
      server.bind(str(socket_path))
      server.listen(1)

      def accept_selection():
        connection, _ = server.accept()
        with connection:
          payload = bytearray()
          while chunk := connection.recv(65536):
            payload.extend(chunk)
        fields = payload.decode().split('\t')
        Path(fields[3]).touch()

      listener = threading.Thread(target=accept_selection, daemon=True)
      listener.start()
      try:
        result = subprocess.run(
          ['bash', str(ROOT / 'bin/zanken-menu-images'), '--lazy-thumbnails', str(images)],
          env={**os.environ, 'HOME': str(home), 'XDG_RUNTIME_DIR': str(runtime),
               'CONVERSION_EVENTS': str(events), 'ZANKEN_PATH': str(ROOT),
               'PATH': str(tools) + ':' + os.environ['PATH']},
          capture_output=True, text=True, timeout=8)
        self.assertEqual(result.returncode, 0, result.stderr)
        listener.join(timeout=1)
        time.sleep(0.4)

        active = peak = 0
        for event in events.read_text().splitlines() if events.exists() else []:
          active += 1 if event.startswith('start ') else -1
          peak = max(peak, active)
        self.assertLessEqual(peak, 2, f'picker opened with {peak} concurrent conversions')
      finally:
        server.close()


if __name__ == '__main__':
  unittest.main()
