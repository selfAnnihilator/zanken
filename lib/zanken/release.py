"""Release identity and candidate resolution; no installation or host mutation."""

import argparse
import hashlib
import json
import re
import subprocess
import sys
import tempfile
from pathlib import Path


NUMBER = r"(?:0|[1-9][0-9]*)"
VERSION = re.compile(
  rf"{NUMBER}\.{NUMBER}\.{NUMBER}"
  r"(?:-([0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))?"
  r"(?:\+[0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*)?"
)
STABLE_TAG = re.compile(rf"zanken-v({NUMBER})\.({NUMBER})\.({NUMBER})")


class ReleaseError(Exception):
  pass


def version_key(version):
  core, _, prerelease = version.split("+", 1)[0].partition("-")
  identifiers = tuple((0, int(part)) if part.isdigit() else (1, part) for part in prerelease.split("."))
  return (*map(int, core.split(".")), 0 if prerelease else 1, identifiers)


def git(repo, *args):
  try:
    result = subprocess.run(
      ["git", "-C", str(repo), *args], capture_output=True, text=True,
      timeout=60, check=False,
    )
  except (OSError, subprocess.TimeoutExpired) as error:
    raise ReleaseError("Git is unavailable or the operation timed out") from error
  if result.returncode:
    # Remote URLs may embed credentials: never echo raw Git stderr here.
    raise ReleaseError(f"Git {args[0]} failed; check repository, refs and remote access")
  return result.stdout.strip()


def unique_object(pairs):
  result = {}
  for key, value in pairs:
    if key in result:
      raise ReleaseError(f"Duplicate release field: {key}")
    result[key] = value
  return result


def validate(raw):
  try:
    manifest = json.loads(raw, object_pairs_hook=unique_object)
  except (ValueError, TypeError) as error:
    raise ReleaseError("release.json must contain valid JSON") from error
  required = {"schema_version", "product", "version", "config_schema", "platform", "desktop"}
  if not isinstance(manifest, dict) or set(manifest) != required:
    raise ReleaseError("release.json must contain exactly the schema v1 fields")
  if type(manifest["schema_version"]) is not int or manifest["schema_version"] != 1:
    raise ReleaseError("Unsupported release schema_version; expected 1")
  for field, expected in (("product", "zanken"), ("platform", "archlinux"), ("desktop", "niri")):
    if manifest[field] != expected:
      raise ReleaseError(f"Unsupported {field}; expected {expected}")
  version = manifest["version"]
  match = VERSION.fullmatch(version) if isinstance(version, str) else None
  if not match:
    raise ReleaseError("version must be a semantic version")
  if match.group(1):
    for part in match.group(1).split("."):
      if part.isdigit() and len(part) > 1 and part.startswith("0"):
        raise ReleaseError("Numeric prerelease identifiers cannot have leading zeros")
  if type(manifest["config_schema"]) is not int or manifest["config_schema"] < 1:
    raise ReleaseError("config_schema must be a positive integer")
  return manifest


def committed_manifest(repo, commit):
  raw = git(repo, "show", f"{commit}:release.json")
  manifest = validate(raw)
  legacy_version = git(repo, "show", f"{commit}:version")
  if legacy_version != manifest["version"]:
    raise ReleaseError("version file does not match release.json")
  return manifest


def refresh(repo, channel):
  # Explicit fetch only. Default resolution works from local refs offline.
  # No force: Git refuses an existing tag whose identity changed upstream.
  refspec = ("refs/tags/zanken-v*:refs/tags/zanken-v*" if channel == "stable"
             else "refs/heads/dev:refs/remotes/origin/dev")
  git(repo, "fetch", "--no-tags", "origin", refspec)


def resolve(repo, channel, version=None):
  if channel == "stable":
    tags = git(repo, "tag", "--list", "zanken-v*").splitlines()
    candidates = [(tuple(map(int, match.groups())), tag)
                  for tag in tags if (match := STABLE_TAG.fullmatch(tag))]
    if not candidates:
      raise ReleaseError("No Zanken stable release available; fetch release tags or use dev")
    if version:
      candidates = [(number, tag) for number, tag in candidates if tag == f"zanken-v{version}"]
      if not candidates:
        raise ReleaseError("Requested stable release is unavailable")
    _, tag = max(candidates)
    ref = f"refs/tags/{tag}"
    if git(repo, "cat-file", "-t", ref) != "tag":
      raise ReleaseError("Stable requires an annotated release tag")
    ref_object = git(repo, "rev-parse", "--verify", ref)
  else:
    ref = "refs/remotes/origin/dev"
    ref_object = git(repo, "rev-parse", "--verify", ref)
  commit = git(repo, "rev-parse", "--verify", f"{ref_object}^{{commit}}")
  manifest = committed_manifest(repo, commit)
  if channel == "stable" and manifest["version"] != tag.removeprefix("zanken-v"):
    raise ReleaseError("Stable tag and manifest version must match exactly")
  digest = hashlib.sha256(json.dumps(manifest, sort_keys=True, separators=(",", ":")).encode()).hexdigest()
  return {
    "schema_version": 1, "kind": "release_candidate", "channel": channel,
    "ref": ref, "ref_object": ref_object, "commit": commit,
    "manifest": manifest, "manifest_sha256": digest,
    "verification": "metadata-only", "installed": False,
  }


def main():
  from generations import Generations
  parser = argparse.ArgumentParser(description=__doc__)
  parser.add_argument("--repo", type=Path, required=True)
  commands = parser.add_subparsers(dest="command", required=True)
  commands.add_parser("validate", help="validate working-tree release metadata")
  commands.add_parser("status", help="inspect source and installed release state")
  commands.add_parser("list", help="list locally available stable release tags")
  for name in ("version", "mode"):
    query = commands.add_parser(name, help=f"print installed {name} (or unmanaged source)")
    query.add_argument("--plain", action="store_true")
  commands.add_parser("rollback", help="restore the previous desktop generation")
  commands.add_parser("recover", help="recover an interrupted generation activation")
  update = commands.add_parser("update", help="update the installed channel")
  update.add_argument("--fetch", action="store_true")
  check = commands.add_parser("check", help="compare installed release with its channel candidate")
  check.add_argument("--fetch", action="store_true")
  resolution = commands.add_parser("resolve", help="resolve a candidate without installing it")
  resolution.add_argument("channel", choices=("stable", "dev"))
  resolution.add_argument("--fetch", action="store_true", help="refresh only the requested channel from origin")
  resolution.add_argument("--version", help="select a specific stable version")
  switch = commands.add_parser("switch", help="activate a validated desktop generation")
  switch.add_argument("channel", choices=("stable", "dev"))
  switch.add_argument("--version", help="select a specific stable version")
  switch.add_argument("--fetch", action="store_true")
  switch.add_argument("--adopt", action="store_true", help="back up existing desktop entry points")
  switch.add_argument("--allow-downgrade", action="store_true", help="allow non-descendant commits with the same schema")
  switch.add_argument("--expect-commit", help="refuse if selection changed since planning")
  bundle = commands.add_parser("bundle", help="export a verified source archive and checksum")
  bundle.add_argument("channel", choices=("stable", "dev"))
  bundle.add_argument("--version")
  bundle.add_argument("--fetch", action="store_true")
  bundle.add_argument("--output", type=Path, required=True, help="new artifact directory")
  args = parser.parse_args()
  try:
    generations = Generations()
    installed = generations.installed()
    # Installed commands live in an archive without .git; remember the repository
    # separately from the executable generation.
    if not (args.repo / ".git").exists() and installed:
      args.repo = Path(installed["current"]["repository"])
    if args.command in ("version", "mode"):
      value = (installed["current"]["manifest"]["version"] if installed else
               validate((args.repo / "release.json").read_text())["version"]) if args.command == "version" else (
                 installed["current"]["channel"] if installed else "unmanaged")
      if args.plain:
        print(value)
        return 0
      output = {args.command: value, "installed": bool(installed)}
    elif args.command in ("rollback", "recover"):
      with generations.locked():
        output = getattr(generations, args.command)()
    elif args.command == "list":
      output = {"releases": sorted(tag for tag in git(args.repo, "tag", "--list", "zanken-v*").splitlines()
                                   if STABLE_TAG.fullmatch(tag))}
    elif args.command == "bundle":
      args.output = args.output.resolve()
      if args.version and args.channel != "stable":
        raise ReleaseError("--version is only supported for stable releases")
      if args.fetch:
        refresh(args.repo, args.channel)
      candidate = resolve(args.repo, args.channel, args.version)
      generations.trust(args.repo, candidate)
      if args.output.exists():
        raise ReleaseError("Artifact output directory already exists")
      args.output.parent.mkdir(parents=True, exist_ok=True)
      with tempfile.TemporaryDirectory(prefix=".zanken-bundle-", dir=args.output.parent) as directory:
        staging = Path(directory)
        archive = staging / "source.tar"
        git(args.repo, "archive", "--format=tar", f"--output={archive}", candidate["commit"])
        with archive.open("rb") as stream:
          digest = hashlib.file_digest(stream, "sha256").hexdigest()
        (staging / "SHA256SUMS").write_text(f"{digest}  source.tar\n")
        (staging / "candidate.json").write_text(json.dumps(candidate, indent=2) + "\n")
        staging.rename(args.output)
      output = {"directory": str(args.output.resolve()), "candidate": candidate}
    elif args.command in ("switch", "update", "check"):
      with generations.locked():
        generations.ensure_ready()
        installed = generations.installed()
        if args.command != "switch" and not installed:
          raise ReleaseError("No managed release installed; use zanken release switch stable|dev --adopt")
        channel = args.channel if args.command == "switch" else installed["current"]["channel"]
        if getattr(args, "version", None) and channel != "stable":
          raise ReleaseError("--version is only supported for stable releases")
        if args.fetch:
          refresh(args.repo, channel)
        candidate = resolve(args.repo, channel, getattr(args, "version", None))
        if getattr(args, "expect_commit", None) and args.expect_commit != candidate["commit"]:
          raise ReleaseError("Candidate changed after planning; resolve the release again")
        if args.command == "check":
          output = {"available": installed["current"]["commit"] != candidate["commit"], "candidate": candidate}
        else:
          output = generations.switch(args.repo, candidate, getattr(args, "adopt", False),
                                      getattr(args, "allow_downgrade", False))
    elif args.command == "resolve":
      if args.version and args.channel != "stable":
        raise ReleaseError("--version is only supported for stable releases")
      if args.fetch:
        refresh(args.repo, args.channel)
      output = resolve(args.repo, args.channel, args.version)
    elif args.command == "status" and installed and not (args.repo / "release.json").is_file():
      output = {"kind": "release_status", "source_available": False, **generations.inspect()}
    else:
      manifest = validate((args.repo / "release.json").read_text())
      if (args.repo / "version").read_text().strip() != manifest["version"]:
        raise ReleaseError("version file does not match release.json")
      output = {"schema_version": 1, "kind": "source_metadata", "manifest": manifest}
      if args.command == "status":
        output.update({
          "kind": "source_checkout", "commit": git(args.repo, "rev-parse", "HEAD"),
          "branch": git(args.repo, "branch", "--show-current") or None,
          "dirty": bool(git(args.repo, "status", "--porcelain", "--untracked-files=normal")),
          **generations.inspect(),
        })
    print(json.dumps({"ok": True, **output}, indent=2))
    return 0
  except (ReleaseError, OSError, UnicodeError) as error:
    message = str(error) if isinstance(error, ReleaseError) else "Cannot read release metadata"
    print(json.dumps({"ok": False, "error": message}), file=sys.stderr)
    return 1


if __name__ == "__main__":
  sys.modules["release"] = sys.modules[__name__]
  sys.exit(main())
