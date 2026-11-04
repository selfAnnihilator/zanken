import importlib.util
from pathlib import Path
import tempfile
import unittest

SOURCE = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('login', SOURCE / 'lib/zanken/login.py')
login = importlib.util.module_from_spec(spec)
spec.loader.exec_module(login)


class LoginTest(unittest.TestCase):
  def setUp(self):
    self.tmp = tempfile.TemporaryDirectory()
    self.addCleanup(self.tmp.cleanup)
    self.root = Path(self.tmp.name)
    self.calls = []

  def command(self, *args):
    self.calls.append(args)
    return ''

  def test_password_login_repeat_restore_and_unrelated_config(self):
    conf = self.root / 'etc/sddm.conf.d/custom.conf'
    conf.parent.mkdir(parents=True)
    conf.write_text('[Users]\nMinimumUid=1001\n')
    backup = login.apply(SOURCE, self.root, self.command)
    original = (self.root / login.CONF).read_text()
    login.apply(SOURCE, self.root, self.command)
    self.assertEqual(original, (self.root / login.CONF).read_text())
    self.assertIn('User=\n', original)
    self.assertTrue(all('--now' not in call for call in self.calls))
    login.restore(backup, self.root, self.command)
    self.assertFalse((self.root / login.CONF).exists())
    self.assertEqual(conf.read_text(), '[Users]\nMinimumUid=1001\n')

  def test_failure_restores_previous_theme_and_service_links(self):
    theme = self.root / 'usr/share/sddm/themes/pixel-sakura'
    theme.mkdir(parents=True)
    (theme / 'custom').write_text('keep')
    target = self.root / 'etc/systemd/system/default.target'
    target.parent.mkdir(parents=True)
    target.symlink_to('/usr/lib/systemd/system/multi-user.target')
    def fail(*args):
      if 'set-default' in args:
        target.unlink()
        target.symlink_to('/usr/lib/systemd/system/graphical.target')
        raise RuntimeError('failed activation')
      return ''
    with self.assertRaises(RuntimeError):
      login.apply(SOURCE, self.root, fail)
    self.assertEqual((theme / 'custom').read_text(), 'keep')
    self.assertEqual(str(target.readlink()), '/usr/lib/systemd/system/multi-user.target')

  def test_conflicting_manager_stops_before_backup(self):
    target = self.root / 'etc/systemd/system/display-manager.service'
    target.parent.mkdir(parents=True)
    target.symlink_to('/usr/lib/systemd/system/gdm.service')
    with self.assertRaisesRegex(ValueError, 'Another display manager'):
      login.apply(SOURCE, self.root, self.command)
    self.assertFalse((self.root / 'var/lib/zanken').exists())

  def test_higher_priority_configuration_is_not_silently_ignored(self):
    conf = self.root / 'etc/sddm.conf'
    conf.parent.mkdir(parents=True)
    conf.write_text('[Autologin]\nUser=somebody\n')
    with self.assertRaisesRegex(ValueError, 'overrides'):
      login.preflight(SOURCE, self.root)


if __name__ == '__main__':
  unittest.main()
