"""Behavior tests at the release CLI using disposable local Git repositories."""

import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
CLI = ROOT / "bin/zanken-release"


class ReleaseTests(unittest.TestCase):
  def setUp(self):
    self.temp = tempfile.TemporaryDirectory(prefix="zanken-release-test-")
    self.addCleanup(self.temp.cleanup)
    self.repo = Path(self.temp.name) / "source with spaces"
    self.repo.mkdir()
    self.env = {**os.environ, "GIT_CONFIG_GLOBAL": os.devnull,
                "GIT_CONFIG_NOSYSTEM": "1", "GIT_TERMINAL_PROMPT": "0",
                "XDG_CONFIG_HOME": str(Path(self.temp.name) / "config"),
                "XDG_DATA_HOME": str(Path(self.temp.name) / "data"),
                "XDG_STATE_HOME": str(Path(self.temp.name) / "state")}
    self.env.pop("WAYLAND_DISPLAY", None)
    self.git("init", "-b", "main")
    self.git("config", "user.name", "Release Test")
    self.git("config", "user.email", "release@example.invalid")
    self.manifest = {"schema_version": 1, "product": "zanken", "version": "4.0.0-alpha",
                     "config_schema": 1, "platform": "archlinux", "desktop": "niri"}
    self.commit()

  def git(self, *args):
    return subprocess.check_output(["git", "-C", str(self.repo), *args],
                                   env=self.env, text=True, stderr=subprocess.PIPE).strip()

  def write_manifest(self):
    (self.repo / "release.json").write_text(json.dumps(self.manifest))
    (self.repo / "version").write_text(self.manifest["version"] + "\n")

  def commit(self, version=None):
    if version:
      self.manifest["version"] = version
    self.write_manifest()
    self.git("add", "release.json", "version")
    self.git("commit", "--allow-empty", "-m", "fixture")
    return self.git("rev-parse", "HEAD")

  def release(self, version):
    commit = self.commit(version)
    self.git("tag", "-a", f"zanken-v{version}", "-m", version)
    return commit

  def cli(self, *args, ok=True, repo=None):
    result = subprocess.run([str(CLI), *args], capture_output=True, text=True,
                            env={**self.env, "ZANKEN_PATH": str(repo or self.repo)})
    self.assertEqual(result.returncode, 0 if ok else 1, result.stdout + result.stderr)
    output = json.loads(result.stdout if ok else result.stderr)
    self.assertEqual(output["ok"], ok)
    return output

  def test_validate_and_source_status(self):
    self.cli("validate")
    status = self.cli("status")
    self.assertFalse(status["dirty"])
    self.assertIsNone(status["installed_release"])
    (self.repo / "local-note").write_text("experiment")
    self.assertTrue(self.cli("status")["dirty"])

  def test_stable_ignores_inherited_and_prerelease_tags(self):
    self.git("tag", "v99.0.0")
    self.git("tag", "zanken-v100.0.0-rc.1")
    self.assertIn("No Zanken stable", self.cli("resolve", "stable", ok=False)["error"])

  def test_stable_uses_numeric_order_and_committed_metadata(self):
    self.release("4.9.0")
    expected = self.release("4.10.0")
    self.manifest["version"] = "99.0.0-alpha"
    self.write_manifest()
    before = self.git("status", "--porcelain")
    candidate = self.cli("resolve", "stable")
    self.assertEqual(candidate["commit"], expected)
    self.assertEqual(candidate["manifest"]["version"], "4.10.0")
    self.assertEqual(candidate["verification"], "metadata-only")
    self.assertFalse(candidate["installed"])
    self.assertEqual(len(candidate["manifest_sha256"]), 64)
    self.assertEqual(self.git("status", "--porcelain"), before)

  def test_stable_rejects_lightweight_tag(self):
    self.commit("4.0.0")
    self.git("tag", "zanken-v4.0.0")
    self.assertIn("annotated", self.cli("resolve", "stable", ok=False)["error"])

  def test_invalid_highest_release_fails_without_falling_back(self):
    self.release("4.0.0")
    self.git("tag", "-a", "zanken-v5.0.0", "-m", "mismatched")
    self.assertIn("match exactly", self.cli("resolve", "stable", ok=False)["error"])

  def test_dev_uses_remote_commit_even_on_detached_checkout(self):
    expected = self.git("rev-parse", "HEAD")
    self.git("update-ref", "refs/remotes/origin/dev", expected)
    self.commit("4.1.0-alpha")
    self.git("checkout", "--detach")
    candidate = self.cli("resolve", "dev")
    self.assertEqual(candidate["commit"], expected)
    self.assertEqual(candidate["channel"], "dev")
    self.assertIsNone(self.cli("status")["branch"])

  def test_missing_dev_does_not_fall_back_to_local_head(self):
    self.cli("resolve", "dev", ok=False)

  def test_rejects_invalid_metadata(self):
    for key, value in [("schema_version", 2), ("schema_version", True),
                       ("product", "omarchy"), ("config_schema", 0),
                       ("config_schema", True), ("version", "4.0.0.alpha"),
                       ("version", "4.0.0-alpha.01"), ("version", "04.0.0"),
                       ("platform", "other"), ("extra", "unknown")]:
      with self.subTest(key=key, value=value):
        invalid = {**self.manifest, key: value}
        (self.repo / "release.json").write_text(json.dumps(invalid))
        self.cli("validate", ok=False)

  def test_duplicate_json_fields_rejected(self):
    raw = json.dumps(self.manifest).replace('"schema_version": 1',
                                          '"schema_version": 1, "schema_version": 1')
    (self.repo / "release.json").write_text(raw)
    self.assertIn("Duplicate", self.cli("validate", ok=False)["error"])

  def test_legacy_version_mismatch_rejected(self):
    (self.repo / "version").write_text("old-version")
    self.cli("validate", ok=False)

  def test_valid_semver_prerelease_and_build_metadata(self):
    self.manifest["version"] = "4.0.0-alpha.1+build.001"
    self.write_manifest()
    self.cli("validate")

  def test_fetch_resolves_new_releases_without_checkout_change(self):
    clone = Path(self.temp.name) / "consumer"
    self.git("clone", "--no-tags", str(self.repo), str(clone))
    expected = self.release("4.0.0")
    self.git("branch", "dev")
    stable = self.cli("resolve", "stable", "--fetch", repo=clone)
    dev = self.cli("resolve", "dev", "--fetch", repo=clone)
    self.assertEqual(stable["commit"], expected)
    self.assertEqual(dev["commit"], expected)
    self.assertEqual(self.cli("status", repo=clone)["manifest"]["version"], "4.0.0-alpha")
    # Offline resolution still succeeds even after origin is unavailable.
    subprocess.check_call(["git", "-C", str(clone), "remote", "set-url", "origin",
                           str(Path(self.temp.name) / "missing")], env=self.env)
    self.assertEqual(self.cli("resolve", "stable", repo=clone), stable)
    self.cli("resolve", "stable", "--fetch", repo=clone, ok=False)

  def test_fetch_rejects_moved_tag(self):
    self.release("4.0.0")
    clone = Path(self.temp.name) / "consumer"
    self.git("clone", str(self.repo), str(clone))
    original = self.cli("resolve", "stable", repo=clone)
    self.commit()
    self.git("tag", "-f", "-a", "zanken-v4.0.0", "-m", "rewritten")
    self.cli("resolve", "stable", "--fetch", repo=clone, ok=False)
    self.assertEqual(self.cli("resolve", "stable", repo=clone), original)


if __name__ == "__main__":
  unittest.main()
