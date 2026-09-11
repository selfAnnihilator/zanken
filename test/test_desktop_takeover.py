"""Exercise configuration rollback in disposable homes, never the host desktop."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class DesktopTakeoverTests(unittest.TestCase):
  def test_configuration_stage_failure_automatically_restores(self):
    with tempfile.TemporaryDirectory() as directory:
      home = Path(directory) / 'home'
      (home / '.config/niri').mkdir(parents=True)
      (home / '.config/niri/config.kdl').write_text('original')
      tools = Path(directory) / 'tools'
      tools.mkdir()
      command = tools / 'zanken-theme-set-templates'
      command.write_text('#!/bin/bash\nexit 42\n')
      command.chmod(0o755)
      result = subprocess.run(['bash', str(ROOT / 'install/config/replace-desktop.sh')],
        env={**os.environ, 'HOME': str(home), 'PATH': str(tools) + ':' + os.environ['PATH'],
             'ZANKEN_INSTALL': str(ROOT / 'install'), 'ZANKEN_PATH': str(ROOT)},
        capture_output=True, text=True)
      self.assertEqual(result.returncode, 42, result.stderr)
      self.assertEqual((home / '.config/niri/config.kdl').read_text(), 'original')
      self.assertFalse((home / '.config/foot').exists())
      self.assertIn('Configuration restored', result.stdout)

  def test_fresh_lock_falls_back_without_touching_host_session(self):
    with tempfile.TemporaryDirectory() as directory:
      command = Path(directory) / 'swaylock'
      command.write_text('#!/bin/bash\nprintf "%s\\n" "$@"\n')
      command.chmod(0o755)
      result = subprocess.run(['bash', str(ROOT / 'bin/zanken-system-lock')],
        env={**os.environ, 'HOME': directory, 'PATH': directory + ':' + os.environ['PATH']},
        capture_output=True, text=True)
      self.assertEqual(result.returncode, 0, result.stderr)
      self.assertIn('--daemonize', result.stdout)

  def run_shell(self, home, body):
    return subprocess.run(['bash', '-eEc',
      'source "$SOURCE/install/helpers/desktop-backup.sh"\n' + body],
      env={**os.environ, 'HOME': str(home), 'SOURCE': str(ROOT)},
      text=True, capture_output=True)

  def test_restore_preserves_originals_and_unrelated_files(self):
    with tempfile.TemporaryDirectory() as directory:
      home = Path(directory)
      for name in ('.config/niri/config.kdl', '.config/foot/foot.ini',
                   '.config/git/config', '.bashrc', '.mozilla/profile/data'):
        path = home / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text('original')
      result = self.run_shell(home, '''
desktop_backup
printf candidate > "$HOME/.config/niri/config.kdl"
mkdir -p "$HOME/.config/zanken"
printf new > "$HOME/.config/zanken/quick-browser"
desktop_restore
desktop_restore
''')
      self.assertEqual(result.returncode, 0, result.stderr)
      self.assertEqual((home / '.config/niri/config.kdl').read_text(), 'original')
      self.assertFalse((home / '.config/zanken').exists())
      for name in ('.config/git/config', '.bashrc', '.mozilla/profile/data'):
        self.assertEqual((home / name).read_text(), 'original')
      backup = next(home.glob('zanken-desktop-backup.*'))
      self.assertEqual(len(list(backup.glob('failed.*'))), 2)

  def test_symlinked_parent_rejected_before_backup(self):
    with tempfile.TemporaryDirectory() as directory:
      home = Path(directory) / 'home'
      external = Path(directory) / 'external'
      home.mkdir()
      external.mkdir()
      (home / '.config').symlink_to(external)
      result = self.run_shell(home, 'desktop_backup')
      self.assertNotEqual(result.returncode, 0)
      self.assertIn('Symlinked parent', result.stderr)
      self.assertEqual(list(external.iterdir()), [])
      self.assertEqual(list(home.glob('zanken-desktop-backup.*')), [])

  def test_symlinked_niri_target_roundtrips_without_writing_target(self):
    with tempfile.TemporaryDirectory() as directory:
      home = Path(directory) / 'home'
      external = Path(directory) / 'dotfiles'
      (home / '.config').mkdir(parents=True)
      external.mkdir()
      (external / 'config.kdl').write_text('external')
      (home / '.config/niri').symlink_to(external)
      result = self.run_shell(home, '''
desktop_backup
mv "$HOME/.config/niri" "$DESKTOP_BACKUP/displaced-niri"
mkdir "$HOME/.config/niri"
printf candidate > "$HOME/.config/niri/config.kdl"
desktop_restore
''')
      self.assertEqual(result.returncode, 0, result.stderr)
      self.assertTrue((home / '.config/niri').is_symlink())
      self.assertEqual((external / 'config.kdl').read_text(), 'external')

  def test_takeover_excludes_full_system_stages(self):
    script = (ROOT / 'install/desktop.sh').read_text()
    for forbidden in ('login/all.sh', 'config/all.sh', 'packaging/base.sh', 'preflight/all.sh'):
      self.assertNotIn(forbidden, script)
    self.assertIn('gum confirm --default=false', script)
    self.assertIn('WAYLAND_DISPLAY', script)
