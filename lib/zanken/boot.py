"""Enable the Plymouth boot animation on the detected bootloader, with backup and rollback."""
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile

ARGS = ('quiet', 'splash')
LIMINE_DEFAULT = 'etc/default/limine'
LIMINE_CONFIGS = (
  'boot/limine.conf', 'boot/limine/limine.conf', 'boot/EFI/limine/limine.conf',
  'boot/EFI/arch-limine/limine.conf', 'boot/EFI/BOOT/limine.conf',
)
GRUB_DEFAULT = 'etc/default/grub'
UKI_CMDLINE = 'etc/kernel/cmdline'
ENTRIES = 'boot/loader/entries'
MKINITCPIO = 'etc/mkinitcpio.conf'
MKINITCPIO_DIR = 'etc/mkinitcpio.conf.d'
HOOKS = re.compile(r'^(\s*HOOKS=\()([^)]*)(\).*)$', re.M)

def run(*args):
  return subprocess.check_output(args, text=True).strip()

def missing_args(text):
  words = set(text.split())
  return [arg for arg in ARGS if arg not in words]

def hooks_file(root):
  """The file whose HOOKS array wins: the last drop-in defining it, else mkinitcpio.conf."""
  drop_ins = sorted((root / MKINITCPIO_DIR).glob('*.conf'))
  for path in reversed(drop_ins):
    if HOOKS.search(path.read_text()):
      return path
  path = root / MKINITCPIO
  if path.exists() and HOOKS.search(path.read_text()):
    return path
  return None

def with_plymouth(hooks):
  words = hooks.split()
  if 'plymouth' in words:
    return hooks
  for anchor in ('systemd', 'udev', 'base'):
    if anchor in words:
      words.insert(words.index(anchor) + 1, 'plymouth')
      return ' '.join(words)
  raise ValueError('mkinitcpio HOOKS has no base, udev or systemd hook to anchor plymouth after.')

def detect(root=Path('/')):
  """Return (kind, [paths]) for every bootloader whose kernel command line we can edit."""
  found = []
  if (root / LIMINE_DEFAULT).exists():
    found.append(('limine-default', [root / LIMINE_DEFAULT]))
  else:
    configs = [root / name for name in LIMINE_CONFIGS if (root / name).exists()]
    if configs:
      found.append(('limine-config', configs))
  if (root / GRUB_DEFAULT).exists():
    found.append(('grub', [root / GRUB_DEFAULT]))
  entries = sorted((root / ENTRIES).glob('*.conf')) if (root / ENTRIES).is_dir() else []
  if entries:
    found.append(('systemd-boot', entries))
  if (root / UKI_CMDLINE).exists():
    found.append(('uki', [root / UKI_CMDLINE]))
  return found

def edit_limine_default(path):
  text = path.read_text()
  missing = missing_args(' '.join(re.findall(r'KERNEL_CMDLINE\[[^\]]*\]\+?=\s*"([^"]*)"', text)))
  if not missing:
    return False
  line = 'KERNEL_CMDLINE[default]+=" ' + ' '.join(missing) + '"\n'
  path.write_text(text + ('' if text.endswith('\n') or not text else '\n') + line)
  return True

def edit_prefixed(path, pattern, quoted):
  """Append missing args to every line matching pattern; quoted lines keep their closing quote."""
  changed = False
  lines = []
  for line in path.read_text().splitlines(keepends=True):
    match = re.match(pattern, line.rstrip('\n'))
    if match:
      value = match.group(2)
      missing = missing_args(value)
      if missing:
        value = (value + ' ' + ' '.join(missing)).strip()
        line = match.group(1) + value + match.group(3) + '\n'
        changed = True
    lines.append(line)
  if changed:
    path.write_text(''.join(lines))
  return changed

def edit_cmdline(kind, paths):
  changed = False
  for path in paths:
    if kind == 'limine-default':
      changed |= edit_limine_default(path)
    elif kind == 'limine-config':
      changed |= edit_prefixed(path, r'^(\s*cmdline:\s*)(.*?)()$', False)
    elif kind == 'grub':
      changed |= edit_prefixed(path, r'^(\s*GRUB_CMDLINE_LINUX_DEFAULT=")([^"]*)(".*)$', True)
    elif kind == 'systemd-boot':
      changed |= edit_prefixed(path, r'^(\s*options\s+)(.*?)()$', False)
    elif kind == 'uki':
      text = path.read_text().strip()
      missing = missing_args(text)
      if missing:
        path.write_text((text + ' ' + ' '.join(missing)).strip() + '\n')
        changed = True
  return changed

def preflight(source=None, root=Path('/')):
  if hooks_file(root) is None:
    raise ValueError('No mkinitcpio HOOKS array found; cannot add the plymouth hook.')
  with_plymouth(HOOKS.search(hooks_file(root).read_text()).group(2))

def regenerate(kinds, root, command):
  command('mkinitcpio', '-P')
  if 'grub' in kinds:
    for target in ('boot/grub/grub.cfg', 'boot/grub2/grub.cfg'):
      if (root / target).exists():
        command('grub-mkconfig', '-o', str(root / target))
        break
  if any(kind.startswith('limine') for kind in kinds) and shutil.which('limine-update'):
    command('limine-update')

def copy(src, dst):
  dst.parent.mkdir(parents=True, exist_ok=True)
  shutil.copy2(src, dst, follow_symlinks=False)

def apply(source=None, root=Path('/'), command=run):
  preflight(source, root)
  if root == Path('/') and not shutil.which('plymouth-set-default-theme'):
    raise ValueError('Missing plymouth package.')
  bootloaders = detect(root)
  targets = [hooks_file(root)] + [path for _, paths in bootloaders for path in paths]
  state = root / 'var/lib/zanken/boot-backups'
  state.mkdir(parents=True, exist_ok=True, mode=0o700)
  backup = Path(tempfile.mkdtemp(prefix='boot-', dir=state))
  names = [str(path.relative_to(root)) for path in targets]
  for name in names:
    copy(root / name, backup / name)
  (backup / 'manifest.json').write_text(json.dumps({'paths': names}))
  try:
    if hooks_file(root) is not None:
      path = hooks_file(root)
      text = path.read_text()
      path.write_text(HOOKS.sub(lambda m: m.group(1) + with_plymouth(m.group(2)) + m.group(3), text, count=1))
    for kind, paths in bootloaders:
      edit_cmdline(kind, paths)
    regenerate([kind for kind, _ in bootloaders], root, command)
  except BaseException:
    restore(backup, root, command)
    raise
  if bootloaders:
    print('Boot animation enabled for the next boot (' + ', '.join(kind for kind, _ in bootloaders) + f'). Backup: {backup}')
  else:
    print('Plymouth hook added, but no editable bootloader was found.')
    print(f'Add "{" ".join(ARGS)}" to your kernel command line manually. Backup: {backup}')
  return backup

def restore(backup, root=Path('/'), command=run):
  manifest = json.loads((backup / 'manifest.json').read_text())
  for name in manifest['paths']:
    copy(backup / name, root / name)
  command('mkinitcpio', '-P')

if __name__ == '__main__':
  try:
    action, location = sys.argv[1:]
    if action != 'preflight' and os.geteuid() != 0:
      raise ValueError('Run apply/restore with sudo.')
    {'preflight': preflight, 'apply': apply, 'restore': restore}[action](Path(location).resolve())
  except (ValueError, OSError, subprocess.CalledProcessError) as error:
    sys.exit(str(error))
