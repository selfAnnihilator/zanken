# Release model

The desktop pipeline supports exact release selection, recoverable generation
activation, installed version/mode reporting, update checks and rollback. First
stable publication and full system acceptance remain pending. See the
[architecture TODO](architecture-todo.md) for remaining work.
The rationale is recorded in [ADR 0001](adr/0001-release-identity.md).

## Identity and channels

`release.json` describes Zanken source: schema version, product, semantic version,
configuration schema, platform and desktop. `version` is the compatibility text
file and must match it. `4.0.0.alpha` has been normalized to `4.0.0-alpha`; this is
still a prerelease, not a newly promoted stable release.

| Channel | Candidate selection | Identity |
| --- | --- | --- |
| stable | Highest numeric annotated `zanken-vMAJOR.MINOR.PATCH` tag | Tag object and exact commit |
| dev | `origin/dev` | Exact commit at resolution time |

Inherited `v*` tags, lightweight tags and prerelease tags do not establish stable
releases. A malformed highest stable tag fails resolution instead of silently
selecting an older version. Its manifest version must match the tag exactly.
Both channels require a valid manifest and a matching `version` file in the
selected commit. A source checkout's branch is never used to infer stability.

The version policy follows [Semantic Versioning 2.0.0](https://semver.org/): public
command behavior and supported configuration form the compatibility surface.
Breaking changes require a major version, compatible features a minor version,
and compatible fixes a patch. `config_schema` is a separate format identifier;
its presence does not prove that a downgrade or a schema transition is safe.

## Commands

```bash
zanken release validate
zanken release status
zanken release resolve stable
zanken release resolve dev --fetch

# These query installed state; a source-only installation reports unmanaged.
zanken version
zanken version channel
zanken release list

# These activate desktop generations (requires installed runtime dependencies).
zanken release switch dev --fetch --adopt
zanken channel set stable --fetch
zanken release switch stable --version 4.0.0 --fetch
zanken update --fetch
zanken release check --fetch
zanken release rollback
zanken release recover
```

Python 3.12+, Git and Niri are required for activation; live switching also needs
Quickshell. Stable verification uses OpenSSH. No third-party Python packages are
needed. `ZANKEN_REPOSITORY` overrides the source repository; otherwise commands
use `ZANKEN_PATH` or their own location. Installed archives remember the repository
separately because their source is not a Git checkout.
Success is JSON on stdout; operational errors are JSON on stderr with exit 1.
Invalid arguments use exit 2. `validate` checks working-tree metadata, and `status`
reports source details, installed/previous releases and pending recovery. Version
and mode also support `--plain`. Before adoption the version is a source version
and mode is `unmanaged`; branch `main` alone is not proof of stability.

Resolution reads committed metadata, so local uncommitted edits never become a
candidate. It returns `kind: release_candidate`, the selected ref, tag/ref object,
commit, manifest and a SHA-256 of canonical manifest JSON (sorted keys, compact
separators). Consumers must retain the commit; resolving a channel again may
select newer input. It neither installs nor records an installed release.

Without `--fetch`, resolution uses locally available refs and works offline; the
answer may be stale and local tags are not authenticated. With `--fetch`, it
contacts `origin` using an explicit refspec for only the requested channel.
Fetch failure stops resolution. Stable fetches do not force replacement of
existing tags, following [Git's tag update rules](https://git-scm.com/docs/git-fetch).
Resolution does not change the checkout, desktop or installed record. Update and
switch use cached refs unless `--fetch` is supplied; the menu supplies this flag.
The hidden bar probe exits 0 for current, 1 for available, and 2 for a failed check.

## Generations and recovery

Each generation has an untouched source tree and a separate rendered desktop.
The effective Niri config includes the local override and is validated before
activation. Quickshell gets a generated IPC identity. During a live switch the
manager reloads Niri and Quickshell and waits for that exact identity. Without a
Wayland session, health explicitly reports `session-check-pending`.

| Location | Purpose |
| --- | --- |
| `$XDG_DATA_HOME/zanken/releases/<id>/` | Source, rendered desktop, generation metadata |
| `$XDG_DATA_HOME/zanken/current-release` | Atomic active-generation pointer |
| `$XDG_STATE_HOME/zanken/releases/installed.json` | Current and previous successful generations |
| `$XDG_STATE_HOME/zanken/releases/pending.json` | Interrupted activation journal |

XDG paths default to the usual directories under the user's home. Existing Niri
and Quickshell entry points require explicit `--adopt`; backups remain beside
them as `.zanken-backup-*`. Local overrides are preserved. A release-managed
desktop rejects legacy `config desktop sync` to avoid separating commands from
configuration. Normal `zanken` invocations follow the active generation; use
`ZANKEN_SOURCE_MODE=1` to inspect source CLI behavior while developing.

Only one mutating operation can run at a time. Failed activation restores prior
entry points and the active pointer. An interrupted activation blocks further
updates until `zanken release recover` finishes. Run this from a TTY if needed.
If reloading the restored desktop also fails, the journal remains for retry.
Retained generations enable rollback without fetching or changing the checkout.
Source hashes catch edited generations before update or rollback.

`--allow-downgrade` is required for non-descendant switches such as dev back to
an older stable commit. Schema changes are refused even with that flag. Releases
that change system provisioning or migration scripts are also refused until a
migration plan exists. This rollback covers the desktop, not pacman or system
configuration changes. Retention/garbage collection is still pending.

## Publisher trust and artifacts

Resolution reports `verification: metadata-only`. Stable activation and export
add SSH tag-signature verification against
`$XDG_CONFIG_HOME/zanken/release-allowed-signers`. Provision that file with an
independently confirmed publisher public key, in OpenSSH allowed-signers format:

```text
publisher@example.org ssh-ed25519 PUBLIC_KEY_HERE
```

The candidate repository cannot install its own trust key. The repository's
`release-allowed-signers` records the owner's confirmed personal publisher public
key (not the work GitHub key). Independently verify its fingerprint before
provisioning trust on another machine:

```text
SHA256:Rry1w/9ct2lalOZgWbzQWs2yBmtpnm43SPO8LN1tTWU
```

Local trust is configured in `/home/abhi/.config/zanken/release-allowed-signers`.
Codex uses a separate XDG config directory; set `XDG_CONFIG_HOME="$HOME/.config"`
when intentionally checking desktop trust from that environment. This does not
change the default XDG isolation. No private key is stored in this project.

Dev remains an explicitly unsigned
experimental channel. Stable output reports `verification: ssh-signature` only
after verification succeeds. This follows [Git's SSH signing support](https://git-scm.com/docs/git-config#Documentation/git-config.txt-gpgsshallowedSignersFile).

```bash
zanken release bundle stable --version 4.0.0 --output /tmp/zanken-4.0.0
```

The new output directory contains `source.tar`, `SHA256SUMS` and `candidate.json`.
The archive is exported from the verified exact commit. Checksums detect archive
corruption; they are not an independent signature for arbitrary downloaded files.
The bootstrap uses this same export path, checks the checksum, runs the selected
source installer, then activates the same expected commit after provisioning.
It preserves existing checkouts and refuses dirty ones. It does not select package
mirrors based on mode. Other system-install stages are still imperative.

Use `ZANKEN_RELEASE_MODE=dev` for experimental bootstrap, or `stable` (default).
`ZANKEN_RELEASE_VERSION` optionally pins a stable version. `ZANKEN_REF` is retired.
Bootstrap needs a repository containing this release implementation and an eligible
committed candidate; uncommitted local changes are not installable releases.

## Promotion still to complete

Follow the [disposable Arch acceptance runbook](release-acceptance.md) for VM
setup and the required evidence matrix.

The first real promotion must test fresh installation, upgrades, rollback and
desktop readiness in an Arch VM. Signing and publishing a `zanken-v*` tag is the
promotion decision: finish acceptance before pushing one. A GitHub draft does
not hide its tag from Git clients.

The manually dispatched `Prepare signed release draft` workflow verifies a signed
tag on main, tests its exported source and docs, and creates a draft with artifacts
and generated notes. Configure `ZANKEN_RELEASE_ALLOWED_SIGNERS` as a repository
variable and protect the `release` environment before using it. Remote execution,
GitHub publisher/environment setup, mandatory VM acceptance and first stable
publication remain open. The local personal publisher trust is configured.
No stable tag or GitHub release was created during local development.

Zanken release identity does not pin Arch or AUR packages. Full-system
reproducibility requires a separate package snapshot and compatibility policy.

## Verification

```bash
python3 -B -m unittest discover -s test -p 'test_*.py' -v
zanken release validate
dbus-run-session -- python3 -B test/check_quickshell_reload.py
```

Tests use temporary Git repositories and local remotes. They cover semantic
versions, inherited/prerelease filtering, numeric tag ordering, malformed tags,
dirty and detached checkouts, missing refs, offline operation, explicit fetching,
and rejection of rewritten tags. Generation tests cover real SSH signatures,
adoption, updates, downgrade guards, rollback, process-kill recovery and a mocked
bootstrap. Niri validates real generated configuration when installed. Quickshell
reload is checked offscreen on a private bus with its reload popup disabled
through [QS_NO_RELOAD_POPUP](https://quickshell.org/docs/v0.2.1/types/Quickshell/Quickshell/).
This confirms same-process reload, but is not full live-desktop or VM acceptance.
