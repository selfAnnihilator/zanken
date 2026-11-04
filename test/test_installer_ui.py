"""Test real stage runner with fake sudo and renderer; no packages or credentials."""
import os
import shlex
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class InstallerUITests(unittest.TestCase):
  def test_makepkg_auth_uses_cached_credentials(self):
    # Exercise Arch's real config loader and run_pacman function, without sudo
    # or package writes. The fake sudo rejects the cache-invalidating -k flag.
    makepkg = Path('/usr/bin/makepkg')
    if not makepkg.exists():
      self.skipTest('Arch makepkg required')
    source = makepkg.read_text()
    function = source[source.index('run_pacman() {'):].split('\n}\n', 1)[0] + '\n}\n'
    with tempfile.TemporaryDirectory() as directory:
      folder = Path(directory)
      for name, body in {
        'sudo': 'for arg; do [[ $arg == "-k" ]] && { echo "sudo: a password is required" >&2; exit 1; }; done\nexit 0',
        'pacman-conf': 'echo /nonexistent-zanken-test',
      }.items():
        path = folder / name
        path.write_text('#!/bin/bash\n' + body + '\n')
        path.chmod(0o755)
      base = folder / 'base.conf'
      base.write_text('CARCH=fixture\n')
      script = '''source /usr/share/makepkg/util/config.sh
config="$SOURCE/install/helpers/makepkg.conf"
[[ -f $config ]] || config=$ZANKEN_MAKEPKG_BASE_CONF
source_makepkg_config "$config"
[[ $CARCH == fixture ]] || exit 9
PACMAN_PATH=/usr/bin/pacman
''' + function + '\nrun_pacman -S go\n'
      result = subprocess.run(['bash', '-O', 'extglob', '-c', script],
        env={**os.environ, 'PATH': directory + ':' + os.environ['PATH'],
          'SOURCE': str(ROOT), 'ZANKEN_MAKEPKG_BASE_CONF': str(base)},
        capture_output=True, text=True)
      self.assertEqual(result.returncode, 0, result.stderr)

  def test_installer_sudo_shim_does_not_enter_desktop_path(self):
    with tempfile.TemporaryDirectory() as directory:
      folder = Path(directory)
      (folder / 'bin').mkdir()
      command = folder / 'bin/zanken-release'
      command.write_text('#!/bin/bash\nprintf "%s" "$PATH"\n')
      command.chmod(0o755)
      shim = str(ROOT / 'install/helpers/noninteractive')
      result = subprocess.run(['bash', str(ROOT / 'install/post-install/release.sh')],
        env={**os.environ, 'PATH': shim + ':' + os.environ['PATH'],
        'ZANKEN_INSTALL': str(ROOT / 'install'), 'ZANKEN_REPOSITORY': directory,
        'ZANKEN_RELEASE_INSTALL': '1', 'ZANKEN_RELEASE_MODE': 'dev',
        'ZANKEN_INSTALL_COMMIT': 'fixture'}, capture_output=True, text=True)
      self.assertEqual(result.returncode, 0, result.stderr)
      self.assertNotIn(shim, result.stdout)

  def test_authentication_prompt_is_cleared_before_progress(self):
    with tempfile.TemporaryDirectory() as directory:
      folder = Path(directory)
      sudo = folder / 'sudo'
      sudo.write_text('''#!/bin/bash
[[ $1 == "-n" ]] && exit 1
printf 'MOCK PASSWORD PROMPT: '
stty -echo
read -r answer
stty echo
[[ $answer == "fixture-only" ]]
''')
      sudo.chmod(0o755)
      runner = folder / 'runner.sh'
      runner.write_text('''#!/bin/bash
set -e
source "$SOURCE/install/helpers/logging.sh"
clear_logo() { printf '\\033[H\\033[2J'; }
installer_status() { echo "$1"; }
installer_authenticate
echo PROGRESS_AFTER_AUTH
''')
      result = subprocess.run(['script', '-qec', 'bash ' + shlex.quote(str(runner)), '/dev/null'],
        input='fixture-only\n', env={**os.environ, 'PATH': directory + ':' + os.environ['PATH'],
        'SOURCE': str(ROOT)}, capture_output=True, text=True, timeout=5)
      self.assertEqual(result.returncode, 0, result.stderr + result.stdout)
      output = result.stdout
      self.assertLess(output.index('MOCK PASSWORD PROMPT'), output.rindex('\x1b[2J'))
      self.assertLess(output.rindex('\x1b[2J'), output.index('PROGRESS_AFTER_AUTH'))

  def test_stage_failure_propagates_and_renderers_stop(self):
    with tempfile.TemporaryDirectory() as directory:
      folder = Path(directory)
      sudo = folder / 'sudo'
      sudo.write_text('#!/bin/bash\nexit 0\n')
      sudo.chmod(0o755)
      stage = folder / 'stage.sh'
      stage.write_text('''[[ $MAKEPKG_CONF == "$ZANKEN_INSTALL/helpers/makepkg.conf" ]] || exit 98
[[ -n $ZANKEN_MAKEPKG_BASE_CONF ]] || exit 97
echo before
false
echo SHOULD_NOT_RUN
''')
      log = folder / 'install.log'
      result = subprocess.run(['bash', '-c', '''
source "$SOURCE/install/helpers/logging.sh"
clear_logo() { echo CLEARED; }
start_log_output() { sleep 30 & monitor_pid=$!; }
run_logged "$STAGE"
status=$?
[[ -z ${monitor_pid:-} && -z ${ZANKEN_AUTH_PID:-} ]] || exit 99
exit "$status"
'''], env={**os.environ, 'PATH': directory + ':' + os.environ['PATH'],
      'SOURCE': str(ROOT), 'STAGE': str(stage), 'ZANKEN_INSTALL': str(ROOT / 'install'),
      'ZANKEN_INSTALL_LOG_FILE': str(log)}, text=True, capture_output=True, timeout=5)
      self.assertEqual(result.returncode, 1, result.stderr)
      self.assertIn('CLEARED', result.stdout)
      self.assertIn('before', log.read_text())
      self.assertNotIn('SHOULD_NOT_RUN', log.read_text())

  def test_no_old_branding_or_blind_retry(self):
    for name in ('presentation', 'logging', 'errors'):
      text = (ROOT / f'install/helpers/{name}.sh').read_text()
      self.assertNotIn('OMARCHY', text)
      self.assertNotIn('discord.gg', text)
      self.assertNotIn('Retry installation', text)
