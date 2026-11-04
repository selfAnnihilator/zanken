import importlib.util
from pathlib import Path
import tempfile
import unittest

SOURCE = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('boot', SOURCE / 'lib/zanken/boot.py')
boot = importlib.util.module_from_spec(spec)
spec.loader.exec_module(boot)

HOOKS = 'HOOKS=(base udev keyboard autodetect modconf kms keymap block encrypt filesystems fsck)\n'


class BootTest(unittest.TestCase):
  def setUp(self):
    self.tmp = tempfile.TemporaryDirectory()
    self.addCleanup(self.tmp.cleanup)
    self.root = Path(self.tmp.name)
    self.calls = []
    self.write('etc/mkinitcpio.conf', HOOKS)

  def command(self, *args):
    self.calls.append(args)
    return ''

  def write(self, name, text):
    path = self.root / name
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text)
    return path

  def read(self, name):
    return (self.root / name).read_text()

  def test_limine_default_gets_args_once(self):
    self.write('etc/default/limine', 'KERNEL_CMDLINE[default]+="root=UUID=x rw"\n')
    boot.apply(None, self.root, self.command)
    boot.apply(None, self.root, self.command)
    text = self.read('etc/default/limine')
    self.assertEqual(text.count('splash'), 1)
    self.assertEqual(text.count('quiet'), 1)
    self.assertIn(('mkinitcpio', '-P'), self.calls)

  def test_limine_default_with_existing_splash_is_untouched(self):
    original = 'KERNEL_CMDLINE[default]+="root=UUID=x quiet splash"\n'
    self.write('etc/default/limine', original)
    boot.apply(None, self.root, self.command)
    self.assertEqual(self.read('etc/default/limine'), original)

  def test_grub(self):
    self.write('etc/default/grub', 'GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3"\nGRUB_TIMEOUT=5\n')
    self.write('boot/grub/grub.cfg', '')
    boot.apply(None, self.root, self.command)
    self.assertIn('GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet splash"', self.read('etc/default/grub'))
    self.assertIn('GRUB_TIMEOUT=5', self.read('etc/default/grub'))
    self.assertTrue(any(call[0] == 'grub-mkconfig' for call in self.calls))

  def test_systemd_boot_and_uki(self):
    self.write('boot/loader/entries/arch.conf', 'title Arch\noptions root=UUID=x rw\n')
    self.write('etc/kernel/cmdline', 'root=UUID=x rw\n')
    boot.apply(None, self.root, self.command)
    self.assertIn('options root=UUID=x rw quiet splash', self.read('boot/loader/entries/arch.conf'))
    self.assertEqual(self.read('etc/kernel/cmdline'), 'root=UUID=x rw quiet splash\n')

  def test_plain_limine_config(self):
    self.write('boot/limine.conf', '/Arch\n    cmdline: root=UUID=x rw\n')
    boot.apply(None, self.root, self.command)
    self.assertIn('cmdline: root=UUID=x rw quiet splash', self.read('boot/limine.conf'))

  def test_no_bootloader_still_adds_hook(self):
    boot.apply(None, self.root, self.command)
    self.assertIn('udev plymouth keyboard', self.read('etc/mkinitcpio.conf'))

  def test_hook_goes_after_systemd_and_into_winning_dropin(self):
    self.write('etc/mkinitcpio.conf.d/hooks.conf', 'HOOKS=(base systemd autodetect sd-encrypt filesystems)\n')
    boot.apply(None, self.root, self.command)
    self.assertIn('base systemd plymouth autodetect', self.read('etc/mkinitcpio.conf.d/hooks.conf'))
    self.assertEqual(self.read('etc/mkinitcpio.conf'), HOOKS)

  def test_existing_plymouth_hook_is_kept(self):
    text = 'HOOKS=(base udev plymouth filesystems)\n'
    self.write('etc/mkinitcpio.conf', text)
    boot.apply(None, self.root, self.command)
    self.assertEqual(self.read('etc/mkinitcpio.conf'), text)

  def test_failure_restores_everything(self):
    self.write('etc/default/grub', 'GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3"\n')
    def fail(*args):
      if args[0] == 'mkinitcpio' and len(self.calls) == 0:
        self.calls.append(args)
        raise RuntimeError('mkinitcpio failed')
      self.calls.append(args)
      return ''
    with self.assertRaises(RuntimeError):
      boot.apply(None, self.root, fail)
    self.assertEqual(self.read('etc/mkinitcpio.conf'), HOOKS)
    self.assertEqual(self.read('etc/default/grub'), 'GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3"\n')

  def test_missing_hooks_array_fails_before_backup(self):
    (self.root / 'etc/mkinitcpio.conf').write_text('# nothing\n')
    with self.assertRaisesRegex(ValueError, 'No mkinitcpio HOOKS'):
      boot.apply(None, self.root, self.command)
    self.assertFalse((self.root / 'var/lib/zanken').exists())


if __name__ == '__main__':
  unittest.main()
