"""Boot access regression tests; privileged operations are simulated, never run."""
import pathlib
import subprocess
import unittest
import tempfile

ROOT = pathlib.Path(__file__).resolve().parents[1]


class InstallerPermissionsTests(unittest.TestCase):
  def test_missing_boot_packages_fail_preflight(self):
    helper = (ROOT / "install/helpers/limine-packages.sh").read_text()
    result = self.shell(helper + '\npacman() { return 1; }\nprepare_limine_packages')
    self.assertEqual(result.returncode, 1)
    self.assertIn("boot configuration was not changed", result.stderr)
    stage = (ROOT / "install/login/limine-snapper.sh").read_text()
    self.assertLess(stage.index('prepare_limine_packages || exit 1'), stage.index('sudo tee'))

  def test_local_package_identity_and_install_route(self):
    helper = (ROOT / "install/helpers/limine-packages.sh").read_text()
    with tempfile.TemporaryDirectory() as directory:
      for package in ('limine-snapper-sync', 'limine-mkinitcpio-hook'):
        folder = pathlib.Path(directory) / package
        folder.mkdir()
        (folder / (package + '-1-1-x86_64.pkg.tar.zst')).touch()
      setup = helper + '\nZANKEN_LIMINE_PACKAGE_DIR=' + directory + '''
pacman() {
  [[ $1 == -Qp ]] || return 99
  case "$2" in
    */limine-snapper-sync/*) echo 'limine-snapper-sync 1-1' ;;
    *) echo 'limine-mkinitcpio-hook 1-1' ;;
  esac
}
'''
      result = self.shell(setup + '\nprepare_limine_packages && printf "%s\\n" "${limine_package_args[@]}"')
      self.assertEqual(result.returncode, 0, result.stderr)
      self.assertEqual(result.stdout.splitlines()[:2], ['-U', '--needed'])
      self.assertEqual(len(result.stdout.splitlines()), 4)
      result = self.shell(setup + '\npacman() { echo "wrong-package 1"; }\nprepare_limine_packages')
      self.assertEqual(result.returncode, 1)

  def test_vm_guard_accepts_qemu_and_kvm_only(self):
    source = (ROOT / "test/resume-release-vm.sh").read_text()
    guard = source.split('export ZANKEN_PATH=', 1)[0]
    guard = guard[guard.index('vm_type='):]
    for identity, expected in [("qemu", 0), ("kvm", 0), ("none", 2), ("docker", 2)]:
      with self.subTest(identity=identity):
        result = self.shell('systemd-detect-virt() { echo ' + identity + '; }\n' + guard)
        self.assertEqual(result.returncode, expected, result.stderr)

  def shell(self, script):
    return subprocess.run(["bash", "-c", script], text=True, capture_output=True)

  def test_root_only_config_detection_and_read(self):
    source = (ROOT / "install/login/limine-snapper.sh").read_text()
    detection = source.split("  # Find config location\n", 1)[1].split(
      "  # Write /etc/default/limine", 1)[0]
    # The unprivileged pathname does not exist in the test namespace. Only
    # the simulated privileged view can see and read the boot configuration.
    detection = detection.replace("/boot/", "/nonexistent-zanken-test-esp/")
    result = self.shell('''
set -euo pipefail
sudo() {
  case "$1" in
    test) [[ $3 == /nonexistent-zanken-test-esp/EFI/BOOT/limine.conf ]] ;;
    grep) printf '  cmdline: root=UUID=test rw\n' ;;
    *) return 99 ;;
  esac
}
''' + detection + '\n[[ $CMDLINE == "root=UUID=test rw" ]]')
    self.assertEqual(result.returncode, 0, result.stderr)

  def test_boot_entry_validation_uses_privileged_reads(self):
    source = (ROOT / "install/login/limine-snapper.sh").read_text()
    validation = source.split("# Installing limine-mkinitcpio-hook above", 1)[1]
    validation = validation[validation.index("if ! "):].split(
      'if [[ -n $EFI ]]', 1)[0]
    validation = validation.replace("/boot/", "/nonexistent-zanken-test-esp/")
    result = self.shell('''
set -euo pipefail
sudo() {
  [[ $1 == grep ]] || { echo "Unexpected rebuild" >&2; return 99; }
}
''' + validation)
    self.assertEqual(result.returncode, 0, result.stderr)

  def test_error_handler_preserves_failure_status(self):
    source = (ROOT / "install/helpers/errors.sh").read_text()
    prefix = source.split("catch_errors() {", 1)[1].split("  stop_log_output", 1)[0]
    result = self.shell('''
ERROR_HANDLING=false
catch_errors() {
''' + prefix + '\nprintf "%s" "$exit_code"\n}\n(exit 37)\ncatch_errors')
    self.assertEqual(result.stdout, "37")

  def test_exit_handler_forwards_explicit_exit_status(self):
    source = (ROOT / "install/helpers/errors.sh").read_text()
    handler = source.split("exit_handler() {", 1)[1].split("# Set up traps", 1)[0]
    result = self.shell('''
ERROR_HANDLING=false
catch_errors() { printf '%s' "$1"; }
exit_handler() {
''' + handler + '\n(exit 42)\nexit_handler')
    self.assertEqual(result.stdout, "42")
