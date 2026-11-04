import os
from pathlib import Path
import subprocess
import sys
import tempfile
import time
import unittest


ROOT = Path(__file__).resolve().parents[1]
HELPER = ROOT / 'lib/zanken/powerprofiles.py'


class PowerProfileSyncTests(unittest.TestCase):
  def setUp(self):
    self.directory = tempfile.TemporaryDirectory(prefix='zanken-power-test-')
    self.addCleanup(self.directory.cleanup)
    self.root = Path(self.directory.name)
    self.platform = self.root / 'platform_profile'
    self.daemon = self.root / 'daemon'
    self.log = self.root / 'writes'
    self.platform.write_text('low-power\n')
    self.daemon.write_text('balanced')
    self.log.touch()
    executable = self.root / 'powerprofilesctl'
    executable.write_text('''#!/bin/bash
set -euo pipefail
if [[ -f $TEST_ROOT/unavailable ]]; then exit 1; fi
case "$1" in
  get) cat "$TEST_ROOT/daemon" ;;
  set)
    printf '%s' "$2" > "$TEST_ROOT/daemon"
    printf '%s\\n' "$2" >> "$TEST_ROOT/writes"
    case "$2" in
      power-saver) platform=low-power ;;
      *) platform=$2 ;;
    esac
    printf '%s\\n' "$platform" > "$TEST_ROOT/platform_profile"
    ;;
esac
''')
    executable.chmod(0o755)
    env = dict(os.environ, TEST_ROOT=str(self.root),
               PATH=str(self.root) + ':' + os.environ['PATH'])
    self.process = subprocess.Popen(
      [sys.executable, str(HELPER), '--platform-profile', str(self.platform),
       '--interval', '0.05'], env=env, stdout=subprocess.DEVNULL,
      stderr=subprocess.DEVNULL)
    self.addCleanup(self.stop)

  def stop(self):
    if self.process.poll() is None:
      self.process.terminate()
      self.process.wait(timeout=3)

  def wait_for(self, expected, timeout=3):
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
      if self.daemon.read_text() == expected:
        return
      if self.process.poll() is not None:
        self.fail('Power profile listener exited before synchronizing firmware')
      time.sleep(0.02)
    self.fail(f'Firmware mode did not reach the power service: {expected}')

  def test_firmware_keys_and_software_controls_stay_in_sync(self):
    # Reproduce Fn+Q changing firmware while the daemon caches Balanced.
    self.wait_for('power-saver')
    for hardware, daemon in [('performance', 'performance'),
                             ('balanced', 'balanced'),
                             ('low-power', 'power-saver')]:
      self.platform.write_text(hardware + '\n')
      self.wait_for(daemon)
    time.sleep(0.15)
    writes = self.log.read_text().splitlines()
    self.assertEqual(writes, ['power-saver', 'performance', 'balanced', 'power-saver'])

    # A manual menu selection already updates both; do not write it again.
    self.daemon.write_text('balanced')
    self.platform.write_text('balanced\n')
    time.sleep(0.2)
    self.assertEqual(self.log.read_text().splitlines(), writes)
    self.assertEqual(self.daemon.read_text(), 'balanced')

  def test_custom_firmware_mode_is_not_overwritten(self):
    self.wait_for('power-saver')
    writes = self.log.read_text()
    self.platform.write_text('custom\n')
    time.sleep(0.2)
    self.assertEqual(self.platform.read_text().strip(), 'custom')
    self.assertEqual(self.log.read_text(), writes)

  def test_transient_daemon_failure_is_retried(self):
    self.wait_for('power-saver')
    marker = self.root / 'unavailable'
    marker.touch()
    self.platform.write_text('performance\n')
    time.sleep(0.2)
    self.assertEqual(self.daemon.read_text(), 'power-saver')
    marker.unlink()
    self.wait_for('performance', timeout=7)


if __name__ == '__main__':
  unittest.main()
