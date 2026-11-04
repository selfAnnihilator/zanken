import pathlib
import subprocess
import unittest
import tempfile

ROOT = pathlib.Path(__file__).resolve().parents[1]


class FreshVMTests(unittest.TestCase):
  def test_invalid_option_is_read_only(self):
    result = subprocess.run(
      ['bash', str(ROOT / 'test/install-fresh-vm.sh'), '--invalid'],
      capture_output=True, text=True)
    self.assertEqual(result.returncode, 2)
    self.assertIn('Usage:', result.stderr)

  def test_preparation_precedes_installer(self):
    source = (ROOT / 'test/install-fresh-vm.sh').read_text()
    self.assertLess(source.index('prepare_limine_packages\n'), source.index('/boot.sh'))
    self.assertIn('makepkg --syncdeps)', source)
    self.assertNotIn('makepkg --install', source)
    self.assertIn('$commit:refs/heads/dev', source)
    self.assertIn('[[ $mode == "--install" ]] || exit 0', source)

  def test_vm_identity_and_confirmation_gate(self):
    source = (ROOT / 'test/install-fresh-vm.sh').read_text()
    guard = source.split('vm_type=', 1)[1].split('[[ -f /etc/arch-release', 1)[0]
    guard = 'vm_type=' + guard
    for identity in ('kvm', 'qemu', 'none', 'docker'):
      with self.subTest(identity=identity):
        result = subprocess.run(['bash', '-c',
          'fail() { exit 17; }; systemd-detect-virt() { echo ' + identity + '; };\n' + guard],
          capture_output=True, text=True)
        self.assertEqual(result.returncode, 0 if identity in ('kvm', 'qemu') else 17)

  def test_existing_install_is_rejected(self):
    source = (ROOT / 'test/install-fresh-vm.sh').read_text()
    guard = source[source.index('[[ ! -e $HOME/.local/share/zanken'):source.index('\nrepo=')]
    with tempfile.TemporaryDirectory() as directory:
      home = pathlib.Path(directory)
      setup = 'fail() { exit 17; }; HOME=' + directory + '\n'
      def check(expected):
        result = subprocess.run(['bash', '-c', setup + guard], capture_output=True)
        self.assertEqual(result.returncode, expected)
      check(0)
      (home / '.config/zanken').mkdir(parents=True)
      check(17)
      (home / '.config/zanken').rmdir()
      (home / '.local/share').mkdir(parents=True)
      (home / '.local/share/zanken').symlink_to(home / 'missing')
      check(17)
