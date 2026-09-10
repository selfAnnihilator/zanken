"""Boot access regression tests; privileged operations are simulated, never run."""
import pathlib
import subprocess
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]


class InstallerPermissionsTests(unittest.TestCase):
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
