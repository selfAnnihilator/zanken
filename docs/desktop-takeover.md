# Replace an existing Niri desktop

This is an opt-in **Arch-based desktop configuration takeover**, not a disk or
bootloader installer. It is implemented and covered by sandboxed rollback tests;
real-session acceptance is still required before calling it production-ready.

Log out of the graphical session and use a TTY as your regular sudo-enabled user.
Use a clean, verified release checkout and the normal release bootstrap, adding:

```bash
ZANKEN_RELEASE_MODE=dev bash boot.sh --desktop
```

There is no stable release yet. The dev-channel GitHub desktop install has been
confirmed on a fresh minimal Arch VM; see [installation](installation.md).
For developer testing of a specific unpublished candidate in a disposable
QEMU/KVM guest with an existing custom Niri config:

```bash
bash test/install-existing-niri-vm.sh --check
bash test/install-existing-niri-vm.sh --install
```

This pins the candidate through an isolated local dev origin. The
[fresh-VM runner](fresh-vm-test.md) remains full-install only and must not be run
on an existing desktop.

The takeover asks for confirmation with **No** selected by default. It installs
desktop packages, backs up affected configuration, and replaces Niri, Zanken's
Quickshell entry point, Foot appearance, idle/lock configuration, GTK cursor settings and browser defaults.
Mod+B selects qutebrowser; Mod+Shift+B selects Zen. The bundled wallpaper library
is copied without overwriting same-named personal files. Brushbuddy becomes the
cursor default; Hornet remains available.

If the optional qylock checkout is absent, Lock uses packaged swaylock instead.
An existing qylock installation is still preferred. Idle locking starts after
ten minutes; no suspend timeout is introduced by this configuration.

The portable workflow adds managed Bash/Fish integration, Zellij, tmux and
selected utility defaults with backups. Git identity, browser profiles and unrelated
app configuration are preserved. See [portable installation](installation.md#portable-desktop-and-workflow)
for hardware selection, package dependencies and service ownership. It does not run full OS provisioning: no partition, bootloader,
or network/power-manager replacement. Pixel Sakura password login is installed
with SDDM; a competing display manager must be resolved before installation.
User workflow services are
configured, and missing supported graphics drivers may be installed. Package installation/upgrade still runs
normal package-manager hooks. Existing independently enabled user services (for
example an old bar) may need to be disabled by their owner before the new session.
Custom XDG roots and symlinked configuration parent directories are rejected.
An already managed Zanken release must use its update/rollback commands instead.

Backups live in `~/zanken-desktop-backup.XXXXXX`. On a caught configuration failure
or interrupt, original configuration is restored; the failed candidate is retained.
Package installations and newly added wallpaper/cursor assets are not rolled back.
Power loss or SIGKILL requires manual recovery. From a logged-out TTY:

```bash
bash install/desktop-restore.sh "$HOME/zanken-desktop-backup.XXXXXX"
```

Replace `XXXXXX` with the printed backup suffix. Restoration is confirmed explicitly
and preserves displaced configuration, including across repeated restores.

## Installer display and testing

The installer now has Zanken branding, stage names, bounded log output and separate
authentication/progress screens. Sudo reads directly from the terminal, not the log;
after successful authentication the prompt/retry text is cleared. Logged subprocesses
use noninteractive sudo and fail instead of displaying a hidden password prompt.
There is no automatic retry, reboot, log upload or third-party community QR code.

Preview only (no authentication, packages or desktop changes):

```bash
bash test/installer-ui-demo.sh
```

Acceptance still requires screenshots at small and large terminal sizes and a
disposable existing-Niri VM test: terminal, bar, wallpapers, both browser shortcuts,
cursors, login, locking, and backup restore. Never run the real installer on the
working host just to test its UI.

## Graphical login on the next boot

Desktop installation now installs the workstation's Pixel Sakura theme and its
Qt video dependencies, enables SDDM without starting it in the current session,
and sets `graphical.target`. Select **Zanken (Niri)** in the login session menu.
No username, autologin account, PAM change or keyring state is exported.

An existing installation can run `zanken-setup-login` from the updated source.
This command installs packages separately from the configuration transaction.
Configuration and prior display-manager/default-target links are backed up under
`/var/lib/zanken/login-backups/login-*` and restored if activation fails.
To restore a printed backup explicitly:

```bash
sudo python3 lib/zanken/login.py restore /var/lib/zanken/login-backups/login-EXAMPLE
```

These system backups are separate from user desktop backups and release rollback;
neither rollback removes installed packages. The current session is never killed.
Higher-priority SDDM overrides are rejected rather than silently ignored. See
[SDDM configuration precedence](https://man.archlinux.org/man/sddm.conf.5.en).

## Boot animation

Desktop installation and `zanken-setup-login` also enable the Zanken Plymouth
animation. `lib/zanken/boot.py` adds the `plymouth` mkinitcpio hook, adds
`quiet splash` to the kernel command line of every detected bootloader (Limine,
GRUB, systemd-boot, or `/etc/kernel/cmdline` for unified kernel images), and
rebuilds the initramfs. Changed files are backed up under
`/var/lib/zanken/boot-backups/boot-*` and restored if the rebuild fails:

```bash
sudo python3 lib/zanken/boot.py restore /var/lib/zanken/boot-backups/boot-EXAMPLE
```

If no editable bootloader is found, the hook is still added and the command
prints the arguments to add by hand. Another machine's command line is never copied.
Unified kernel images are only regenerated by `mkinitcpio -P`; if yours are built
by another tool, run that tool after installing.

Run `zanken debug login` to see the display manager, kernel command line and
bootloader state when the login screen or animation does not appear.
