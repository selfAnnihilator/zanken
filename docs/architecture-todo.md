# Architecture implementation TODO

Started: 2026-09-09. This is the working implementation ledger. Check a task only
after its behavior is implemented and verified; release publishing and live
desktop changes are separate milestones.

## 1. Release model — in progress

- [x] Define versioned release metadata and validate its format.
- [x] Resolve stable from annotated `zanken-vMAJOR.MINOR.PATCH` tags, excluding
  inherited tags and prereleases; reject mismatched metadata.
- [x] Resolve dev from `origin/dev` to an exact commit, independent of checkout.
- [x] Return machine-readable candidate identity and distinguish it from source
  checkout and installed state. Never label a branch name as proof of stability.
- [x] Add offline behavioral tests with real temporary Git repositories.
- [x] Configure release model CI on pull requests and main/dev pushes (remote run
  pending publication; equivalent checks pass locally).
- [x] Document release policy, compatibility scope, and adoption procedure.
- [x] Export exact source archives and checksums; require trusted SSH signatures
  for stable activation and artifact export.
- [x] Add a manually dispatched draft-release workflow with signature, metadata,
  behavior and documentation checks, and generated release notes.
- [x] Select the owner's personal SSH publisher key and configure local trust;
  record its public key and fingerprint for independently verified replication.
- [x] Configure the personal public signer variable and a main-only release
  environment requiring owner review in GitHub (2026-09-09).
- [ ] Exercise a remote workflow run and complete VM acceptance before stable tagging.
- [ ] Finish interrupted Quickget ISO download, verify its official checksum,
  and boot the isolated VM using `test/start-release-vm.sh`.
- [ ] Automate final promotion acceptance and standalone artifact authentication.
- [ ] Publish the first Zanken stable release only after those checks pass.
- [x] Wire bootstrap, update checks, channel selection, and version reporting to
  the resolver and activation flow; remove legacy rc/edge behavior deliberately.
- [x] Record installed/previous generations only after successful activation;
  distinguish offline config validation from verified live-session health.
- [x] Separate development checkouts from releases; hash source to detect edits.
- [x] Protect against moved tags, downgrades, incompatible state schemas, dirty
  checkouts, concurrent updates, interruption, and offline operation.

## 2. Configuration reconciliation

- [ ] Define desired state, observed state, plan, generation, and activation record.
- [ ] Use one engine for install, update, repair, and explicit rollback.
- [x] Stage a desktop generation including matching commands and configuration.
- [x] Render and validate the effective Niri config including local overrides.
- [x] Verify the expected Quickshell generation through IPC after live reload.
- [x] Activate with an atomic pointer change; preserve the previous generation.
- [x] Add locking, durable progress and interrupted-operation recovery.
- [ ] Add retention and garbage collection of inactive generations and backups.
- [ ] Version migration state; define idempotence, ordering, failure and downgrade
  rules. Never count a skipped migration as successful installation.
- [ ] Separate reversible file activation from package/system mutations; define
  recovery for each and avoid claiming package rollback from a desktop backup.
- [x] Preserve existing bootstrap checkouts and stop blanket config overwrites.
- [ ] Define ownership, backups, adoption, overrides, and safe uninstall behavior.
- [x] Test desktop adoption, repeated apply, upgrade, rollback, failed validation
  and reload, process kill/recovery, concurrency and stable → dev → stable.
- [ ] Test complete system provisioning and power-loss/failure at every I/O step.

## 3. Desktop task runtime

- [ ] Inventory tasks and state owners; select one bounded task as the pilot.
- [ ] Define request/result/error/event contracts and protocol versioning.
- [ ] Give CLI and Quickshell the same task semantics and status visibility.
- [ ] Delegate process lifetime, restart, and logs to systemd where appropriate.
- [ ] Define cancellation, timeouts, serialization, retries, and job persistence.
- [ ] Use narrowly scoped privilege helpers and explicit authorization.
- [ ] Remove duplicated polling/parsing from QML incrementally.
- [ ] Define session startup ownership and remove competing launch paths.
- [ ] Preserve Quickshell soft reload and MPRIS continuity.
- [ ] Keep desktop recovery available if the task runtime is unavailable.
- [ ] Test task failures, restart/reconnect, duplicate requests, and CLI/UI parity.

## 4. Reproducible profiles

- [ ] Define a minimal Niri profile and optional application/capability profiles.
- [ ] Separate portable preferences, machine settings, generated files and secrets.
- [ ] Define merge precedence and schema migrations for supported settings.
- [ ] Centralize hardware detection and profile selection with fixture tests.
- [ ] Export/import profiles without personal paths, credentials, or caches.
- [ ] Record dependency expectations; decide whether reproducibility covers the
  Zanken desktop only or a full package snapshot. Arch/AUR drift is still external.
- [ ] Consolidate legacy Omarchy/Hyprland paths with explicit migration coverage.

## 5. Verification and operations

- [ ] Replace source-string assertions with behavior tests where failures matter.
- [ ] Run CLI, security, isolated Niri and Quickshell tests in suitable environments.
- [ ] Add a fresh Arch VM install/upgrade/recovery matrix before stable promotion.
- [ ] Define supported hardware, dependency versions and release support policy.
- [ ] Add diagnostics showing desired/installed release, health and drift.
- [ ] Document TTY recovery, rollback, backups and failed-update support procedure.
- [ ] Measure startup, idle overhead and task latency before/after centralization.
- [ ] Keep command metadata, public docs, ADRs and wiki outcomes synchronized.

## Delivery notes

The desktop pipeline now supports candidate resolution, generation activation,
mode/version queries, switching, updates, rollback and interrupted-operation
recovery. It does not roll back packages or system migrations. Changes to system
provisioning between releases are refused until a migration plan exists.

2026-09-09: added `release.json`, the `zanken release` command, a standard-library
Python implementation and 13 behavioral tests. Metadata and command checks,
the release suite, and strict documentation build pass locally. Version spelling
is now `4.0.0-alpha`. No release was published or activated on the live desktop.

2026-09-09, activation milestone: bootstrap now runs a verified pinned source
archive and defers desktop activation until provisioning completes. Tests use
temporary repositories, fake package provisioning, real SSH signatures, a real
Niri validator when installed, and private offscreen Quickshell reload checks.
Fresh Arch VM acceptance, publisher configuration and first stable publication
remain open; the full stable distribution pipeline is not declared complete.
The real Quickshell offscreen check initially failed because its reload popup
needs a display backend; `QS_NO_RELOAD_POPUP=1` isolates this test limitation.
The original pointer design then passed with the same process. CLI, Niri smoke,
security regression tests and strict documentation build also pass locally.
