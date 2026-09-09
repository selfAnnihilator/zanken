"""Recoverable user desktop generations. Does not install system packages."""

from contextlib import contextmanager
from datetime import datetime, timezone
import fcntl
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tarfile
import tempfile
import time
import uuid

from release import ReleaseError, git, validate, version_key


def read_json(path):
  try:
    return json.loads(path.read_text())
  except (ValueError, OSError) as error:
    raise ReleaseError(f"Cannot read state file: {path.name}") from error


def atomic_json(path, value):
  path.parent.mkdir(parents=True, exist_ok=True)
  fd, temporary = tempfile.mkstemp(prefix=".record-", dir=path.parent)
  try:
    with os.fdopen(fd, "w") as stream:
      json.dump(value, stream, indent=2)
      stream.write("\n")
      stream.flush()
      os.fsync(stream.fileno())
    os.replace(temporary, path)
    sync_dir(path.parent)
  finally:
    if os.path.exists(temporary):
      os.unlink(temporary)


def sync_dir(path):
  fd = os.open(path, os.O_RDONLY | os.O_DIRECTORY)
  try:
    os.fsync(fd)
  finally:
    os.close(fd)


def exists(path):
  return path.exists() or path.is_symlink()


def tree_hash(root):
  digest = hashlib.sha256()
  for path in sorted(root.rglob("*")):
    digest.update(str(path.relative_to(root)).encode() + b"\0")
    if path.is_symlink():
      digest.update(b"link\0" + os.readlink(path).encode())
    elif path.is_file():
      digest.update(str(path.stat().st_mode & 0o777).encode() + b"\0")
      with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
          digest.update(chunk)
    digest.update(b"\0")
  return digest.hexdigest()


def sync_tree(root):
  directories = []
  for path in root.rglob("*"):
    if path.is_symlink():
      continue
    if path.is_file():
      with path.open("rb") as stream:
        os.fsync(stream.fileno())
    elif path.is_dir():
      directories.append(path)
  for path in reversed(directories):
    sync_dir(path)
  sync_dir(root)


def run(argv, *, env=None):
  try:
    result = subprocess.run(argv, env=env, capture_output=True, text=True, timeout=30)
  except (OSError, subprocess.TimeoutExpired) as error:
    raise ReleaseError(f"{argv[0]} unavailable or timed out") from error
  if result.returncode:
    raise ReleaseError(f"{argv[0]} failed (exit {result.returncode}); activation refused")
  return result.stdout.strip()


class Generations:
  def __init__(self):
    self.config = Path(os.environ.get("XDG_CONFIG_HOME", str(Path.home() / ".config")))
    self.data = Path(os.environ.get("XDG_DATA_HOME", str(Path.home() / ".local/share"))) / "zanken"
    self.state = Path(os.environ.get("XDG_STATE_HOME", str(Path.home() / ".local/state"))) / "zanken/releases"
    if not all(path.is_absolute() for path in (self.config, self.data, self.state)):
      raise ReleaseError("XDG directories must be absolute")
    self.record = self.state / "installed.json"
    self.journal = self.state / "pending.json"
    self.current = self.data / "current-release"

  @contextmanager
  def locked(self):
    self.state.mkdir(parents=True, exist_ok=True)
    with (self.state / "lock").open("a") as stream:
      try:
        fcntl.flock(stream, fcntl.LOCK_EX | fcntl.LOCK_NB)
      except BlockingIOError as error:
        raise ReleaseError("Another release operation is in progress") from error
      yield

  def installed(self):
    if not self.record.exists():
      return None
    value = read_json(self.record)
    if (not isinstance(value, dict) or type(value.get("schema_version")) is not int
        or value["schema_version"] != 1 or not {"current", "previous", "transaction"} <= value.keys()):
      raise ReleaseError("Unsupported installed release record")
    for field in ("current", "previous"):
      item = value[field]
      if item is None and field == "previous":
        continue
      required = {"generation", "repository", "manifest", "channel", "commit", "source_sha256"}
      if not isinstance(item, dict) or not required <= item.keys():
        raise ReleaseError("Invalid generation in installed release record")
      self.generation(item["generation"])
      validate(json.dumps(item["manifest"]))
      if (item["channel"] not in ("stable", "dev") or not isinstance(item["repository"], str)
          or not Path(item["repository"]).is_absolute()
          or not isinstance(item["commit"], str) or not re.fullmatch(r"[0-9a-f]{40}|[0-9a-f]{64}", item["commit"])
          or not isinstance(item["source_sha256"], str) or not re.fullmatch(r"[0-9a-f]{64}", item["source_sha256"])):
        raise ReleaseError("Invalid identity in installed release record")
    return value

  def generation(self, name):
    if not isinstance(name, str) or len(name) != 32 or any(c not in "0123456789abcdef" for c in name):
      raise ReleaseError("Invalid generation identifier")
    return self.data / "releases" / name

  def inspect(self):
    value = self.installed()
    return {"installed_release": value, "recovery_required": self.journal.exists(),
            "active_generation": str(self.current.resolve()) if self.current.is_symlink() else None}

  def ensure_ready(self):
    if self.journal.exists():
      raise ReleaseError("Interrupted activation: run zanken release recover first")
    installed = self.installed()
    if installed and (not self.current.is_symlink() or
                      self.current.resolve() != self.generation(installed["current"]["generation"])):
      raise ReleaseError("Active pointer differs from installed state; manual recovery required")
    if installed and self.actions(installed["current"], False):
      raise ReleaseError("Managed desktop entry points are missing; inspect before updating")

  def trust(self, repo, candidate):
    if candidate["channel"] != "stable":
      return
    allowed = self.config / "zanken/release-allowed-signers"
    if not allowed.is_file():
      raise ReleaseError("Stable activation requires ~/.config/zanken/release-allowed-signers")
    # Pin verification to the tag object selected by the resolver, never re-resolve
    # its mutable name. Trust is supplied by the user, not by the candidate tree.
    try:
      git(repo, "-c", "gpg.format=ssh", "-c", "gpg.ssh.program=ssh-keygen",
          "-c", f"gpg.ssh.allowedSignersFile={allowed}", "verify-tag", candidate["ref_object"])
    except ReleaseError as error:
      raise ReleaseError("Stable tag is not signed by a trusted SSH publisher") from error
    candidate["verification"] = "ssh-signature"

  def stage(self, repo, candidate):
    self.trust(repo, candidate)
    name = uuid.uuid4().hex
    target = self.generation(name)
    target.mkdir(parents=True)
    source = target / "source"
    source.mkdir()
    archive = target / "source.tar"
    try:
      git(repo, "archive", "--format=tar", f"--output={archive}", candidate["commit"])
      with archive.open("rb") as stream:
        archive_hash = hashlib.file_digest(stream, "sha256").hexdigest()
      with tarfile.open(archive) as bundle:
        # Python's data filter rejects absolute/escaping links, devices and paths.
        bundle.extractall(source, filter="data")
      archive.unlink()
      for required in ("bin/zanken", "bin/zanken-release", "lib/zanken/release.py",
                       "default/desktop/niri/config.kdl", "default/desktop/quickshell/shell.qml"):
        if not (source / required).is_file():
          raise ReleaseError(f"Incomplete release: missing {required}")
      if validate((source / "release.json").read_text()) != candidate["manifest"]:
        raise ReleaseError("Archived release metadata differs from candidate")
      desktop = target / "desktop"
      shutil.copytree(source / "default/desktop", desktop, symlinks=False)
      shell = desktop / "quickshell/shell.qml"
      token = "ZANKEN_SOURCE_GENERATION"
      if token not in shell.read_text():
        raise ReleaseError("Release lacks the Quickshell generation health contract")
      shell.write_text(shell.read_text().replace(token, name))
      # Commands launched by the compositor resolve through the stable pointer.
      config = desktop / "niri/config.kdl"
      installed_source = self.current / "source"
      environment = ("\nenvironment {\n"
                     f"    ZANKEN_PATH {json.dumps(str(installed_source), ensure_ascii=False)}\n"
                     f"    OMARCHY_PATH {json.dumps(str(installed_source), ensure_ascii=False)}\n"
                     f"    PATH {json.dumps(str(installed_source / 'bin') + ':' + os.environ.get('PATH', ''), ensure_ascii=False)}\n"
                     "}\n")
      rendered = config.read_text()
      palette = self.config / "zanken/current/theme/colors.toml"
      if palette.is_file():
        accent = re.search(r'^color1 = "(#[0-9a-fA-F]{6})"', palette.read_text(), re.MULTILINE)
        if accent:
          rendered = re.sub(r'^(\s*active-color\s+)"#[0-9a-fA-F]+"',
                            lambda match: match.group(1) + '"' + accent.group(1) + '"', rendered, flags=re.MULTILINE)
      config.write_text(rendered + environment)
      effective = target / "effective.kdl"
      effective.write_text(self.entry(desktop))
      run(["niri", "validate", "--config", str(effective)])
      value = {**candidate, "generation": name, "repository": str(Path(repo).resolve()),
               "scope": "desktop", "kind": "installed_release",
               "source_sha256": tree_hash(source),
               "archive_sha256": archive_hash, "installed": True,
               "created_at": datetime.now(timezone.utc).isoformat()}
      atomic_json(target / "generation.json", value)
      sync_tree(target)
      sync_dir(target.parent)
      return value
    except BaseException as error:
      # This UUID directory is exclusively created by this invocation.
      shutil.rmtree(target)
      if isinstance(error, tarfile.TarError):
        raise ReleaseError("Release archive contains unsafe or invalid entries") from error
      raise

  def entry(self, desktop):
    return ("// Managed by Zanken releases. Local settings: ~/.config/zanken/niri.kdl\n"
            f"include {json.dumps(str(desktop / 'niri/config.kdl'), ensure_ascii=False)}\n"
            f"include optional=true {json.dumps(str(self.config / 'zanken/niri.kdl'), ensure_ascii=False)}\n")

  def health(self, generation):
    if not os.environ.get("WAYLAND_DISPLAY"):
      return "config-validated; session-check-pending"
    run(["niri", "msg", "action", "load-config-file"])
    run(["qs", "-c", "zanken", "ipc", "call", "zanken", "reload"])
    # Old QML may remain running when a reload fails. Only the expected identity
    # demonstrates that the new tree has actually loaded.
    deadline = time.monotonic() + 8
    while time.monotonic() < deadline:
      try:
        result = run(["qs", "-c", "zanken", "ipc", "call", "zanken", "releaseIdentity"])
        if result.strip('"') == generation:
          return "session-verified"
      except ReleaseError:
        pass
      time.sleep(0.2)
    raise ReleaseError("Quickshell did not load the selected generation")

  def actions(self, value, adopt):
    backup_id = uuid.uuid4().hex
    paths = [
      (self.current, str(self.generation(value["generation"])), "link"),
      (self.data / "desktop", str(self.current / "desktop"), "link"),
      (self.data / "bin", str(self.current / "source/bin"), "link"),
      (self.config / "quickshell/zanken", str(self.data / "desktop/quickshell"), "link"),
      (self.config / "niri/config.kdl", self.entry(self.data / "desktop"), "file"),
    ]
    actions = []
    for index, (path, content, kind) in enumerate(paths):
      same = ((path.is_symlink() and os.readlink(path) == content) if kind == "link"
              else (path.is_file() and not path.is_symlink() and path.read_text() == content))
      if same:
        continue
      if exists(path) and path != self.current and not adopt:
        raise ReleaseError(f"Existing configuration needs explicit --adopt: {path}")
      if exists(path) and path == self.current and not path.is_symlink():
        raise ReleaseError("current-release must be a managed symlink")
      actions.append({"path": str(path), "content": content, "kind": kind,
                      "existed": exists(path), "backup": str(path.parent / f".zanken-backup-{backup_id}-{index}")})
    return actions

  def apply(self, value, adopt=False):
    old = self.installed()
    actions = self.actions(value, adopt)
    journal = {"schema_version": 1, "transaction": uuid.uuid4().hex,
               "actions": actions, "old": old}
    atomic_json(self.journal, journal)
    try:
      for action in actions:
        path = Path(action["path"])
        path.parent.mkdir(parents=True, exist_ok=True)
        if action["existed"]:
          if path.is_symlink():
            Path(action["backup"]).symlink_to(os.readlink(path))
          elif path.is_file():
            backup_temp = Path(action["backup"] + ".tmp")
            shutil.copy2(path, backup_temp)
            with backup_temp.open("rb") as stream:
              os.fsync(stream.fileno())
            os.replace(backup_temp, action["backup"])
          else:
            os.replace(path, action["backup"])
          sync_dir(path.parent)
        temporary = path.parent / f".zanken-new-{journal['transaction']}"
        if action["kind"] == "link":
          temporary.symlink_to(action["content"])
        else:
          temporary.write_text(action["content"])
          with temporary.open("rb") as stream:
            os.fsync(stream.fileno())
        os.replace(temporary, path)
        if path.parent.exists():
          sync_dir(path.parent)
      health = self.health(value["generation"])
      result = {"schema_version": 1, "transaction": journal["transaction"],
                "current": value, "previous": old["current"] if old else None,
                "health": health}
      atomic_json(self.record, result)
      self.journal.unlink()
      sync_dir(self.state)
      return result
    except BaseException:
      self.recover()
      raise

  def recover(self):
    if not self.journal.exists():
      return {"recovered": False}
    journal = read_json(self.journal)
    record = self.installed()
    if record and record.get("transaction") == journal["transaction"]:
      self.journal.unlink()
      return {"recovered": True, "committed": True}
    for action in reversed(journal["actions"]):
      path, backup = Path(action["path"]), Path(action["backup"])
      if exists(backup) or not action["existed"]:
        if exists(path):
          if path.is_dir() and not path.is_symlink():
            raise ReleaseError("Recovery found an unexpected directory; preserve it and inspect pending.json")
          if not exists(backup):
            path.unlink()
        if exists(backup):
          os.replace(backup, path)
        if path.parent.exists():
          sync_dir(path.parent)
    if os.environ.get("WAYLAND_DISPLAY"):
      run(["niri", "msg", "action", "load-config-file"])
      run(["qs", "-c", "zanken", "ipc", "call", "zanken", "reload"])
    self.journal.unlink()
    sync_dir(self.state)
    return {"recovered": True, "committed": False}

  def switch(self, repo, candidate, adopt=False, allow_downgrade=False):
    self.ensure_ready()
    if candidate["manifest"]["config_schema"] != 1:
      raise ReleaseError("Activation only supports configuration schema 1; a migration plan is required")
    old = self.installed()
    if old:
      current = old["current"]
      if tree_hash(self.generation(current["generation"]) / "source") != current["source_sha256"]:
        raise ReleaseError("Installed source has changed; inspect or roll back before updating")
      if current["manifest"]["config_schema"] != candidate["manifest"]["config_schema"]:
        raise ReleaseError("Configuration schema changes require a migration plan")
      if current["commit"] == candidate["commit"] and current["channel"] == candidate["channel"]:
        return old
      changed_system = git(repo, "diff", "--name-only", current["commit"], candidate["commit"],
                           "--", "migrations", "install", "default/systemd", "config/systemd")
      if changed_system:
        raise ReleaseError("Release changes system provisioning; a migration plan is required before desktop activation")
      # Until reversible migrations exist, any non-descendant is explicit.
      if not allow_downgrade:
        if version_key(candidate["manifest"]["version"]) < version_key(current["manifest"]["version"]):
          raise ReleaseError("Older version requires --allow-downgrade")
        try:
          git(repo, "merge-base", "--is-ancestor", current["commit"], candidate["commit"])
        except ReleaseError as error:
          raise ReleaseError("Non-descendant release requires --allow-downgrade") from error
    value = self.stage(repo, candidate)
    return self.apply(value, adopt)

  def rollback(self):
    self.ensure_ready()
    record = self.installed()
    if not record or not record["previous"]:
      raise ReleaseError("No previous generation available")
    previous = record["previous"]
    target = self.generation(previous["generation"])
    if read_json(target / "generation.json") != previous:
      raise ReleaseError("Previous generation metadata differs from installed record")
    if tree_hash(target / "source") != previous["source_sha256"]:
      raise ReleaseError("Previous generation source has changed; refusing rollback")
    if previous["manifest"]["config_schema"] != record["current"]["manifest"]["config_schema"]:
      raise ReleaseError("Cannot roll back across configuration schemas")
    (target / "effective.kdl").write_text(self.entry(target / "desktop"))
    run(["niri", "validate", "--config", str(target / "effective.kdl")])
    return self.apply(previous)
