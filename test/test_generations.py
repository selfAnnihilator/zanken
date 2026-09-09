"""Generation activation tests with real Git/signatures and fake desktop tools."""

import fcntl
import json
import os
from pathlib import Path
import shutil
import subprocess
import unittest

import test_release


class GenerationTests(unittest.TestCase):
  git = test_release.ReleaseTests.git
  cli = test_release.ReleaseTests.cli
  commit = test_release.ReleaseTests.commit
  write_manifest = test_release.ReleaseTests.write_manifest
  release = test_release.ReleaseTests.release

  def setUp(self):
    test_release.ReleaseTests.setUp(self)
    self.data = Path(self.env["XDG_DATA_HOME"]) / "zanken"
    self.config = Path(self.env["XDG_CONFIG_HOME"])
    self.state = Path(self.env["XDG_STATE_HOME"]) / "zanken/releases"
    tools = Path(self.temp.name) / "tools"
    tools.mkdir()
    niri = tools / "niri"
    niri.write_text('''#!/bin/bash
if [[ $1 == "validate" ]] && grep -q 'INVALID' "$3"; then exit 1; fi
exit "${NIRI_STATUS:-0}"
''')
    qs = tools / "qs"
    qs.write_text('''#!/bin/bash
if [[ ${CRASH_ACTIVATION:-0} == "1" ]]; then kill -KILL "$PPID"; exit 1; fi
if [[ ${QS_FAIL:-0} == "1" ]]; then exit 1; fi
if [[ ${*: -1} == "releaseIdentity" ]]; then
  basename "$(readlink "$XDG_DATA_HOME/zanken/current-release")"
fi
''')
    niri.chmod(0o755)
    qs.chmod(0o755)
    self.env["PATH"] = str(tools) + ":" + os.environ["PATH"]
    for name in ("bin/zanken", "bin/zanken-release", "bin/zanken-version", "bin/zanken-version-channel",
                 "bin/zanken-channel-set", "bin/zanken-update", "bin/zanken-update-available",
                 "lib/zanken/release.py", "lib/zanken/generations.py"):
      path = self.repo / name
      path.parent.mkdir(parents=True, exist_ok=True)
      shutil.copy2(test_release.ROOT / name, path)
    for name, content in [("default/desktop/niri/config.kdl", "// valid fixture\n"),
                          ("default/desktop/quickshell/shell.qml", "ZANKEN_SOURCE_GENERATION")]:
      path = self.repo / name
      path.parent.mkdir(parents=True, exist_ok=True)
      path.write_text(content)
    self.git("add", ".")
    self.commit()
    self.advance()

  def advance(self, version=None):
    commit = self.commit(version)
    self.git("update-ref", "refs/remotes/origin/dev", commit)
    return commit

  def installed(self):
    return json.loads((self.state / "installed.json").read_text())

  def test_public_version_mode_switch_and_update_commands(self):
    def public(*args):
      result = subprocess.run([str(self.repo / "bin/zanken"), *args], capture_output=True,
                              text=True, env={**self.env, "ZANKEN_PATH": str(self.repo)})
      self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
      return result.stdout.strip()
    self.assertEqual(public("version", "channel"), "unmanaged")
    public("channel", "set", "dev")
    self.assertEqual(public("version", "channel"), "dev")
    self.assertEqual(public("version"), "4.0.0-alpha")
    self.advance("4.1.0-alpha")
    public("update")
    self.assertEqual(public("version"), "4.1.0-alpha")
    public("release", "rollback")
    self.assertEqual(public("version"), "4.0.0-alpha")

  def test_update_badge_distinguishes_available_current_and_error(self):
    self.cli("switch", "dev")
    self.git("branch", "dev")
    self.git("remote", "add", "origin", str(self.repo))
    def probe():
      return subprocess.run([str(self.repo / "bin/zanken-update-available")], capture_output=True,
                            text=True, env={**self.env, "ZANKEN_PATH": str(self.repo)})
    self.assertEqual(probe().returncode, 0)
    self.advance("4.1.0-alpha")
    self.git("branch", "-f", "dev")
    self.assertEqual(probe().returncode, 1)
    self.git("remote", "set-url", "origin", str(Path(self.temp.name) / "missing"))
    self.assertEqual(probe().returncode, 2)

  def test_install_update_and_rollback_keep_source_untouched(self):
    head = self.git("rev-parse", "HEAD")
    first = self.cli("switch", "dev")
    self.assertEqual(first["current"]["commit"], head)
    self.assertEqual(first["health"], "config-validated; session-check-pending")
    self.assertTrue((self.data / "current-release/source/bin/zanken").is_file())
    self.assertEqual(self.cli("mode")["mode"], "dev")
    second_commit = self.advance("4.1.0-alpha")
    self.assertTrue(self.cli("check")["available"])
    second = self.cli("update")
    self.assertEqual(second["current"]["commit"], second_commit)
    self.assertEqual(second["previous"]["generation"], first["current"]["generation"])
    self.assertEqual(self.cli("version")["version"], "4.1.0-alpha")
    self.assertFalse(self.cli("check")["available"])
    self.cli("rollback")
    self.assertEqual(self.installed()["current"]["commit"], head)
    self.assertEqual(self.git("rev-parse", "HEAD"), second_commit)
    self.assertEqual(self.git("status", "--porcelain"), "")

  def test_repeated_switch_is_idempotent(self):
    first = self.cli("switch", "dev")
    self.assertEqual(first, self.cli("switch", "dev"))
    self.assertEqual(len(list((self.data / "releases").iterdir())), 1)

  def test_repeated_rollback_can_toggle_generations(self):
    first = self.cli("switch", "dev")["current"]["commit"]
    second = self.advance("4.1.0-alpha")
    self.cli("update")
    for expected in (first, second, first, second):
      self.assertEqual(self.cli("rollback")["current"]["commit"], expected)

  def test_killed_activation_is_recovered_from_journal(self):
    self.cli("switch", "dev")
    before = self.installed()
    self.advance("4.1.0-alpha")
    self.env.update({"WAYLAND_DISPLAY": "test-only", "CRASH_ACTIVATION": "1"})
    result = subprocess.run([str(test_release.CLI), "update"], capture_output=True,
                            text=True, env={**self.env, "ZANKEN_PATH": str(self.repo)})
    self.assertEqual(result.returncode, -9)
    self.assertTrue((self.state / "pending.json").exists())
    self.assertIn("recover first", self.cli("update", ok=False)["error"])
    self.env["CRASH_ACTIVATION"] = "0"
    self.cli("recover")
    self.assertEqual(self.installed(), before)
    self.assertEqual(Path(os.readlink(self.data / "current-release")).name, before["current"]["generation"])

  def test_source_drift_is_not_silently_overwritten(self):
    self.cli("switch", "dev")
    (self.data / "current-release/source/version").write_text("local edit")
    self.assertIn("source has changed", self.cli("update", ok=False)["error"])

  def test_missing_entry_point_is_detected_even_on_noop_update(self):
    self.cli("switch", "dev")
    (self.config / "niri/config.kdl").unlink()
    self.assertIn("entry points", self.cli("update", ok=False)["error"])

  def test_corrupt_installed_record_returns_structured_error(self):
    self.cli("switch", "dev")
    (self.state / "installed.json").write_text('{"schema_version": 1, "current": null, "previous": null, "transaction": "bad"}')
    self.assertIn("Invalid generation", self.cli("status", ok=False)["error"])

  def test_older_version_on_descendant_commit_still_requires_downgrade(self):
    self.advance("4.2.0-alpha")
    self.cli("switch", "dev")
    self.advance("4.1.0-alpha")
    self.assertIn("Older version", self.cli("update", ok=False)["error"])

  def test_changed_source_prevents_rollback(self):
    first = self.cli("switch", "dev")["current"]["generation"]
    self.advance("4.1.0-alpha")
    self.cli("update")
    (self.data / "releases" / first / "source/version").write_text("edited")
    self.assertIn("source has changed", self.cli("rollback", ok=False)["error"])

  def test_candidate_change_after_planning_is_rejected(self):
    before = self.git("rev-parse", "HEAD")
    self.advance("4.1.0-alpha")
    self.assertIn("changed after planning", self.cli("switch", "dev", "--expect-commit", before, ok=False)["error"])

  def test_bundle_contains_exact_commit_and_checksum(self):
    import hashlib
    import tarfile
    target = Path(self.temp.name) / "artifact"
    result = self.cli("bundle", "dev", "--output", str(target))
    digest = hashlib.sha256((target / "source.tar").read_bytes()).hexdigest()
    self.assertEqual((target / "SHA256SUMS").read_text(), f"{digest}  source.tar\n")
    with tarfile.open(target / "source.tar") as archive:
      self.assertEqual(archive.extractfile("version").read().decode().strip(), result["candidate"]["manifest"]["version"])
    self.cli("bundle", "dev", "--output", str(target), ok=False)

  def test_explicit_adoption_keeps_backups_and_local_overrides(self):
    niri = self.config / "niri/config.kdl"
    niri.parent.mkdir(parents=True)
    niri.write_text("// my prior config")
    override = self.config / "zanken/niri.kdl"
    override.parent.mkdir(parents=True)
    override.write_text("// machine override")
    self.cli("switch", "dev", ok=False)
    self.assertEqual(niri.read_text(), "// my prior config")
    self.cli("switch", "dev", "--adopt")
    backups = list(niri.parent.glob(".zanken-backup-*"))
    self.assertEqual(backups[0].read_text(), "// my prior config")
    self.assertEqual(override.read_text(), "// machine override")

  def test_validation_failure_never_changes_active_release(self):
    self.cli("switch", "dev")
    before = self.installed()
    pointer = os.readlink(self.data / "current-release")
    self.advance("4.1.0-alpha")
    self.env["NIRI_STATUS"] = "1"
    self.cli("update", ok=False)
    self.assertEqual(self.installed(), before)
    self.assertEqual(os.readlink(self.data / "current-release"), pointer)

  def test_session_health_success(self):
    self.env["WAYLAND_DISPLAY"] = "test-only"
    self.assertEqual(self.cli("switch", "dev")["health"], "session-verified")

  def test_failed_reload_restores_pointer_and_requires_recovery_if_reload_stays_broken(self):
    self.cli("switch", "dev")
    before = self.installed()
    self.advance("4.1.0-alpha")
    self.env.update({"WAYLAND_DISPLAY": "test-only", "QS_FAIL": "1"})
    self.cli("update", ok=False)
    self.assertEqual(self.installed(), before)
    self.assertEqual(Path(os.readlink(self.data / "current-release")).name, before["current"]["generation"])
    self.assertTrue((self.state / "pending.json").exists())
    self.env["QS_FAIL"] = "0"
    self.assertTrue(self.cli("recover")["recovered"])
    self.assertFalse((self.state / "pending.json").exists())

  def test_concurrent_operation_is_rejected(self):
    self.state.mkdir(parents=True)
    with (self.state / "lock").open("a") as lock:
      fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
      self.assertIn("in progress", self.cli("switch", "dev", ok=False)["error"])

  def test_schema_transition_is_rejected(self):
    self.cli("switch", "dev")
    self.manifest["config_schema"] = 2
    self.advance()
    self.assertIn("schema", self.cli("update", ok=False)["error"])

  def test_system_changes_require_migration_plan(self):
    self.cli("switch", "dev")
    migration = self.repo / "migrations/new.sh"
    migration.parent.mkdir()
    migration.write_text("echo external change")
    self.git("add", ".")
    self.advance()
    self.assertIn("migration plan", self.cli("update", ok=False)["error"])

  def test_non_descendant_requires_explicit_downgrade(self):
    earlier = self.git("rev-parse", "HEAD")
    self.advance("4.1.0-alpha")
    self.cli("switch", "dev")
    self.git("update-ref", "refs/remotes/origin/dev", earlier)
    self.cli("switch", "dev", ok=False)
    self.cli("switch", "dev", "--allow-downgrade")
    self.assertEqual(self.installed()["current"]["commit"], earlier)

  def test_stable_activation_requires_trusted_signature(self):
    self.release("4.0.0")
    self.assertIn("allowed-signers", self.cli("switch", "stable", ok=False)["error"])

  def test_signed_stable_and_specific_release_switch(self):
    key = Path(self.temp.name) / "signer"
    subprocess.run(["ssh-keygen", "-t", "ed25519", "-N", "", "-f", str(key)],
                   check=True, capture_output=True)
    allowed = self.config / "zanken/release-allowed-signers"
    allowed.parent.mkdir(parents=True)
    allowed.write_text("release@example.invalid " + key.with_suffix(".pub").read_text())
    self.git("config", "gpg.format", "ssh")
    self.git("config", "user.signingkey", str(key))
    self.commit("4.0.0")
    self.git("tag", "-s", "zanken-v4.0.0", "-m", "stable")
    self.commit("4.1.0")
    self.git("tag", "-s", "zanken-v4.1.0", "-m", "stable")
    result = self.cli("switch", "stable", "--version", "4.0.0")
    self.assertEqual(result["current"]["verification"], "ssh-signature")
    self.assertEqual(self.cli("mode")["mode"], "stable")
    self.cli("update")
    self.assertEqual(self.cli("version")["version"], "4.1.0")
    self.advance("4.2.0-alpha")
    self.cli("switch", "dev")
    self.cli("switch", "stable", ok=False)
    self.cli("switch", "stable", "--allow-downgrade")
    self.assertEqual(self.cli("mode")["mode"], "stable")
    self.assertEqual(self.cli("version")["version"], "4.1.0")

  def test_installed_executable_can_find_repository_without_git_in_generation(self):
    self.cli("switch", "dev")
    binary = self.data / "bin/zanken-release"
    result = subprocess.run([str(binary), "mode", "--plain"], capture_output=True,
                            text=True, env=self.env)
    self.assertEqual(result.returncode, 0, result.stderr)
    self.assertEqual(result.stdout.strip(), "dev")

  def test_bootstrap_pins_source_and_preserves_existing_checkout(self):
    tools = Path(self.temp.name) / "tools"
    for command in ("sudo", "clear"):
      path = tools / command
      path.write_text("#!/bin/bash\nexit 0\n")
      path.chmod(0o755)
    installer = self.repo / "install.sh"
    installer.write_text('''#!/bin/bash
set -euo pipefail
"$ZANKEN_REPOSITORY/bin/zanken-release" switch "$ZANKEN_RELEASE_MODE" --expect-commit "$ZANKEN_INSTALL_COMMIT"
''')
    self.git("add", ".")
    expected = self.advance()
    self.git("branch", "dev", expected)
    self.git("remote", "add", "origin", str(self.repo))
    self.env.update({"ZANKEN_REPOSITORY": str(self.repo), "ZANKEN_RELEASE_MODE": "dev",
                     "TMPDIR": self.temp.name})
    result = subprocess.run(["bash", str(test_release.ROOT / "boot.sh")], capture_output=True,
                            text=True, env=self.env)
    self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
    self.assertEqual(self.installed()["current"]["commit"], expected)
    self.assertEqual(self.git("rev-parse", "HEAD"), expected)
    self.assertEqual(self.git("status", "--porcelain"), "")
    (self.repo / "personal-work").write_text("keep")
    result = subprocess.run(["bash", str(test_release.ROOT / "boot.sh")], capture_output=True,
                            text=True, env=self.env)
    self.assertNotEqual(result.returncode, 0)
    self.assertEqual((self.repo / "personal-work").read_text(), "keep")

  @unittest.skipUnless(shutil.which("niri"), "real Niri validator is not installed")
  def test_real_niri_accepts_rendered_environment_and_local_override(self):
    fake_niri = Path(self.temp.name) / "tools/niri"
    fake_niri.unlink()
    fake_niri.symlink_to(shutil.which("niri"))
    shutil.copyfile(test_release.ROOT / "default/desktop/niri/config.kdl",
                    self.repo / "default/desktop/niri/config.kdl")
    self.git("add", ".")
    self.advance()
    override = self.config / "zanken/niri.kdl"
    override.parent.mkdir(parents=True)
    override.write_text("// local machine override\n")
    palette = self.config / "zanken/current/theme/colors.toml"
    palette.parent.mkdir(parents=True)
    palette.write_text('color1 = "#aabbcc"\n')
    self.cli("switch", "dev")
    self.assertIn('active-color "#aabbcc"', (self.data / "desktop/niri/config.kdl").read_text())
    self.advance("4.1.0-alpha")
    override.write_text("invalid-node-for-niri\n")
    self.cli("update", ok=False)
    self.assertEqual(self.installed()["current"]["manifest"]["version"], "4.0.0-alpha")


if __name__ == "__main__":
  unittest.main()
