import os
import pathlib
import subprocess
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]


class PackageReuseTests(unittest.TestCase):
  def test_bootstrap_keeps_existing_helper(self):
    with tempfile.TemporaryDirectory() as directory:
      folder = pathlib.Path(directory)
      for name, content in {
        'yay': 'exit 0',
        'zanken-pkg-add': 'exit 0',
        'zanken-cmd-missing': 'command -v "$1" >/dev/null && exit 1; exit 0',
        'sudo': 'exit 0',
        'git': 'echo UNEXPECTED_DOWNLOAD; exit 98',
      }.items():
        path = folder / name
        path.write_text('#!/bin/bash\n' + content + '\n')
        path.chmod(0o755)
      result = subprocess.run(['bash', '-e', str(ROOT / 'install/preflight/pacman.sh')],
        env={**os.environ, 'PATH': directory + ':' + os.environ['PATH'], 'ZANKEN_ONLINE_INSTALL': 'true'},
        capture_output=True, text=True)
      self.assertEqual(result.returncode, 0, result.stderr)
      self.assertNotIn('UNEXPECTED_DOWNLOAD', result.stdout)

  def test_mixed_batch_does_not_request_installed_yay(self):
    for helper in ('zanken-pkg-add', 'zanken-pkg-aur-add'):
      with self.subTest(helper=helper), tempfile.TemporaryDirectory() as directory:
        folder = pathlib.Path(directory)
        scripts = {
          # Dependency satisfaction also handles an installed yay-bin provider.
          'pacman': '#!/bin/bash\n[[ $1 == -T && $2 == yay ]] && exit 0\n[[ $1 == -T && -f $FAKE_STATE ]] && exit 0\nexit 1\n',
          'zanken-pkg-missing': '#!/bin/bash\nexit 0\n',
          'yay': '#!/bin/bash\nprintf "%s\\n" "$@" >> "$FAKE_CALLS"\ntouch "$FAKE_STATE"\n',
          'zanken-pkg-aur-add': '#!/bin/bash\nprintf "%s\\n" "$@" >> "$FAKE_CALLS"\ntouch "$FAKE_STATE"\n',
        }
        for name, content in scripts.items():
          path = folder / name
          path.write_text(content)
          path.chmod(0o755)
        calls = folder / 'calls'
        env = {**os.environ, 'PATH': directory + ':' + os.environ['PATH'],
               'FAKE_STATE': str(folder / 'installed'), 'FAKE_CALLS': str(calls)}
        result = subprocess.run(['bash', str(ROOT / 'bin' / helper), 'yay', 'new-app'],
                                env=env, capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertNotIn('yay', calls.read_text().splitlines())
        self.assertIn('new-app', calls.read_text().splitlines())
