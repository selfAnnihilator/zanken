# Disposable Arch release acceptance

This is the acceptance runbook, not evidence that acceptance has passed.
On 2026-09-09 the ISO download passed Quickget's checksum verification and the
guest booted into installed minimal Arch. Btrfs, Limine presence, sudo and network
checks passed. The actual Quickemu VM now uses 4 GiB RAM and a 40 GiB disk, with
39 GiB Btrfs root and about 37 GiB free. A clean-Arch disk/UEFI baseline is retained.
Zanken installation and the acceptance matrix below remain pending. The separate
custom launcher still needs its checksum receipt; it is not the active VM config.

## GitHub testing branch

`codex/release-vm-test` contains the release work separately from unrelated local
desktop edits. Clone it to a new directory and record `git rev-parse HEAD` before
testing. This branch is not a stable release or the canonical `dev` channel.
Do not invoke `boot.sh` blindly: its stable default requires a published signed
tag, and dev fetches `origin/dev`, not the currently checked-out testing branch.
VM installation must use an explicitly prepared local test origin for the exact
candidate. No stable tag should be created as a workaround.
Never sign or push a stable tag until the matrix below passes for its exact
candidate commit. GitHub environment approval does not gate Git tag visibility.

## Host setup

Quickget downloads the official Arch image and checks its published checksum.
Run from the ignored project `.release-vm` directory:

```bash
quickget archlinux latest
```

The prepared September 2026 launcher pins `archlinux-2026.09.01-x86_64.iso`.
Keep `.release-vm/ISO.SHA256` as the matching checksum receipt from the official
Arch release metadata; do not derive expected checksums from a downloaded image.
Changing the ISO requires updating both the launcher pin and the receipt.

```bash
bash test/start-release-vm.sh --iso
# After installing Arch and shutting down:
bash test/start-release-vm.sh --disk
```

The launcher uses QEMU/KVM directly with the Quickget image: 2 vCPUs, 3 GiB RAM,
a separate sparse 40 GiB qcow2, UEFI without Secure Boot, and localhost-only
SSH forwarding on port 22220. No host folders, clipboard, microphone, physical
disks or USB devices are passed through. This avoids the installed Quickemu's
wildcard-address SSH forwarding default. Never run two instances against the same
disk. The launcher locks it. Shut down the guest before copying a baseline disk.

Install vanilla Arch **inside the guest**, using only its 40 GiB virtual disk.
The current installer requires Btrfs root, Limine, a non-root sudo user, and no
preinstalled GNOME/KDE; do not bypass these guards to mark a test as passed.
Keep an offline clean-Arch baseline before installing Zanken. No host partitioning
or system package changes are needed. Transfer only the candidate source and
public trust file, never personal SSH private keys or the host home directory.

## Candidate and evidence

Use an exact committed candidate in an isolated test repository. Before public
promotion, stable fixtures use an ephemeral **guest-only** signing key and local
test tags; they must never be pushed to the project remote. Test-key signatures
exercise the mechanism but do not authenticate the eventual publisher artifact.
Record candidate SHA, ISO checksum, package versions, commands, exit codes,
installed state and screenshots. A changed candidate invalidates prior acceptance.

| Scenario | Required result | Status |
| --- | --- | --- |
| Fresh Arch bootstrap | Reboot into usable Niri/Quickshell; exact installed identity | Pending |
| Stable to newer stable | Correct version; overrides preserved; health verified | Pending |
| Stable to dev to stable | Explicit modes; downgrade approval where needed | Pending |
| Rollback | Previous source and desktop active after reboot | Pending |
| Failed config or reload | Prior desktop restored; useful error | Pending |
| Killed activation and recovery | Journal detected; recovery restores coherent state | Pending |
| Offline and concurrent update | No accidental fetch; concurrent writer rejected | Pending |
| Wrong signer or source drift | Rejected without changing active desktop | Pending |

Passing the Python fixtures or booting the ISO alone does not complete this matrix.

## GitHub gate

`ZANKEN_RELEASE_ALLOWED_SIGNERS` contains the confirmed personal public signer.
The `release` environment allows `main` only and requires approval from
`selfAnnihilator`. Self-review is allowed so the sole publisher can approve their
own manually dispatched run. No private signing key is uploaded. The workflow
environment currently retains GitHub's administrator-bypass default; review
approval is not an unbypassable control against repository administrators. The workflow
must be committed and pushed before it can be exercised remotely; this runbook
does not authorize publishing a stable tag.

References: [Quickget](https://github.com/quickemu-project/quickemu/blob/master/docs/quickget.1.md),
[GitHub environments](https://docs.github.com/en/rest/deployments/environments).
