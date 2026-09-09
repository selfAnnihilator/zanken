# ADR 0001: Separate release identity from checkout and activation

Date: 2026-09-09. Status: accepted; extended for desktop generation activation.

## Context

Zanken is becoming a reproducible Niri configuration system. Branch names alone
do not identify installed content. The inherited Git tags must not accidentally
become Zanken stable releases, and the live updater only recovers the desktop
tree, not commands, packages or migrations.

## Decision

Use one release module behind `zanken release`, with strict `release.json` schema
validation, stable/dev candidate resolution and source inspection. Use Python's
standard library for structured data and Git subprocess calls, with a Bash entry
point preserving command conventions. No daemon is necessary for resolution.

Stable candidates use annotated `zanken-vMAJOR.MINOR.PATCH` tags whose committed
metadata matches the tag. Select the greatest numeric version and fail on invalid
metadata. Dev uses `origin/dev`. Return full commit and ref-object identities so
activation consumes fixed input. Source state remains distinct from installed state.

Keep candidate resolution separate from activation. Write the installed record only
when matching commands and configuration have been activated and health-checked.
Source updates and candidate downloads are not proof of successful installation.
Signature verification and release promotion checks remain prerequisites for
publishing the first stable release.

## Consequences

Metadata resolution can be tested offline with real temporary repositories.
Bootstrap and update now use this module for desktop generation activation;
system provisioning remains imperative and outside desktop rollback.
Release tags are project-specific; no inherited tag is implicitly promoted.
Local resolution reports metadata-only verification; stable activation and export
require SSH tag verification with an independently provisioned allowed-signers file.
The module does not pin Arch/AUR packages or execute schema/system migrations.
Changed provisioning and schemas fail closed until migration planning is available.

See the [release model](../releases.md) for the command contract and the
[architecture TODO](../architecture-todo.md) for remaining milestones.
