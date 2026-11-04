import os
from pathlib import Path
import shlex
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class InstallerConsoleTests(unittest.TestCase):
  def run_console(self, stage, after=''):
    with tempfile.TemporaryDirectory() as directory:
      folder = Path(directory)
      for name, body in {'sudo': 'exit 0', 'gum': 'echo UNEXPECTED_MENU; exit 0'}.items():
        path = folder / name
        path.write_text('#!/bin/bash\n' + body + '\n')
        path.chmod(0o755)
      (folder / 'stage.sh').write_text(stage)
      runner = folder / 'runner.sh'
      runner.write_text('''#!/bin/bash
set -eEo pipefail
source "$SOURCE/install/helpers/presentation.sh"
source "$SOURCE/install/helpers/errors.sh"
source "$SOURCE/install/helpers/logging.sh"
before=$(stty -g)
run_logged "$STAGE"
[[ $(stty -g) == "$before" ]] || { echo TERMINAL_NOT_RESTORED; exit 99; }
echo STAGE_COMPLETED
''' + after)
      result = subprocess.run(['script', '-qec', 'bash ' + shlex.quote(str(runner)), '/dev/null'],
        env={**os.environ, 'PATH': directory + ':' + os.environ['PATH'],
          'SOURCE': str(ROOT), 'STAGE': str(folder / 'stage.sh'),
          'ZANKEN_INSTALL': str(ROOT / 'install'), 'TERM': 'linux',
          'ZANKEN_INSTALL_LOG_FILE': str(folder / 'install.log')},
        input='', text=True, capture_output=True, timeout=8)
      return result

  def test_stage_terminal_settings_are_restored(self):
    result = self.run_console('stty -echo -onlcr </dev/tty\necho stage-output\n')
    self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
    self.assertIn('STAGE_COMPLETED', result.stdout)

  def test_failure_report_is_once_and_returns_original_status(self):
    result = self.run_console('echo failure-context\nexit 42\n')
    self.assertEqual(result.returncode, 42, result.stdout + result.stderr)
    self.assertEqual(result.stdout.count('Installation stopped'), 1)
    self.assertIn('failure-context', result.stdout)
    self.assertNotIn('UNEXPECTED_MENU', result.stdout)

  def test_child_failure_does_not_open_parent_error_ui(self):
    result = self.run_console('echo stage-output\n', '(false) &\nwait $! || true\necho PARENT_ALIVE\n')
    self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
    self.assertIn('PARENT_ALIVE', result.stdout)
    self.assertNotIn('UNEXPECTED_MENU', result.stdout)
    self.assertNotIn('Installation stopped', result.stdout)
