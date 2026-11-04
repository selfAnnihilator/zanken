"""Install the allowlisted greeter without starting it or modifying authentication."""
import configparser
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

CONFIG = '''[General]
DisplayServer=wayland
[Wayland]
CompositorCommand=niri --config /etc/zanken-sddm-niri.kdl
[Theme]
Current=pixel-sakura
[Autologin]
User=
Session=
Relogin=false
'''
FILES = {
  'usr/share/sddm/themes/pixel-sakura': 'default/sddm/pixel-sakura',
  'etc/zanken-sddm-niri.kdl': 'default/sddm/niri.kdl',
  'usr/local/share/wayland-sessions/zanken.desktop': 'default/wayland-sessions/zanken.desktop',
}
CONF = 'etc/sddm.conf.d/zz-zanken.conf'

def run(*args):
  return subprocess.check_output(args, text=True).strip()

def preflight(source, root=Path('/')):
  for name in FILES.values():
    if not (source / name).exists():
      raise ValueError(f'Missing login asset: {name}')
  manager = root / 'etc/systemd/system/display-manager.service'
  if manager.exists() or manager.is_symlink():
    if manager.resolve().name != 'sddm.service':
      raise ValueError('Another display manager is selected. Keep it or explicitly disable it before installing SDDM.')
  # /etc/sddm.conf has precedence over every drop-in. Reject conflicting keys
  # instead of silently claiming the selected screen will actually be used.
  for path in [root / 'etc/sddm.conf', *sorted((root / 'etc/sddm.conf.d').glob('*.conf'))]:
    if path.name != 'sddm.conf' and path.name <= Path(CONF).name:
      continue
    parser = configparser.ConfigParser(interpolation=None, strict=False)
    parser.read(path)
    desired = configparser.ConfigParser(interpolation=None)
    desired.read_string(CONFIG)
    for section in desired.sections():
      for key, value in desired[section].items():
        if parser.has_option(section, key) and parser.get(section, key) != value:
          raise ValueError(f'{path} overrides {section}.{key}; reconcile this setting before installing login.')

def copy(src, dst):
  dst.parent.mkdir(parents=True, exist_ok=True)
  if src.is_dir() and not src.is_symlink():
    shutil.copytree(src, dst, symlinks=True)
  elif src.is_symlink():
    dst.symlink_to(os.readlink(src))
  else:
    shutil.copy2(src, dst)

def remove(path):
  if path.is_symlink() or path.is_file():
    path.unlink()
  elif path.exists():
    shutil.rmtree(path)

def apply(source, root=Path('/'), command=run):
  preflight(source, root)
  for binary in ('niri', 'niri-session', 'sddm-greeter-qt6'):
    if root == Path('/') and not shutil.which(binary):
      raise ValueError(f'Missing login dependency: {binary}')
  command('niri', 'validate', '--config', str(source / 'default/sddm/niri.kdl'))
  state = root / 'var/lib/zanken/login-backups'
  state.mkdir(parents=True, exist_ok=True, mode=0o700)
  backup = Path(tempfile.mkdtemp(prefix='login-', dir=state))
  paths = [*FILES, CONF, 'etc/systemd/system/display-manager.service', 'etc/systemd/system/default.target']
  existing = []
  for name in paths:
    path = root / name
    if path.exists() or path.is_symlink():
      copy(path, backup / name)
      existing.append(name)
  (backup / 'manifest.json').write_text(json.dumps({'paths': paths, 'existing': existing}))
  try:
    for dest, origin in FILES.items():
      remove(root / dest)
      copy(source / origin, root / dest)
    path = root / CONF
    remove(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(CONFIG)
    command('systemctl', 'enable', 'sddm.service')
    command('systemctl', 'set-default', 'graphical.target')
    if root == Path('/'):
      # Without this link logind falls back to a bare tty after reboot.
      manager = root / 'etc/systemd/system/display-manager.service'
      if manager.resolve().name != 'sddm.service':
        raise ValueError('SDDM is not the selected display manager after enabling it.')
      if command('systemctl', 'get-default') != 'graphical.target':
        raise ValueError('The default boot target is not graphical.target.')
  except BaseException:
    restore(backup, root, command)
    raise
  print(f'Password login enabled for the next boot. Backup: {backup}')
  print('Select Zanken (Niri) in the login session menu. The current session was not restarted.')
  return backup

def restore(backup, root=Path('/'), command=run):
  manifest = json.loads((backup / 'manifest.json').read_text())
  for name in manifest['paths']:
    remove(root / name)
    if name in manifest['existing']:
      copy(backup / name, root / name)
  command('systemctl', 'daemon-reload')

if __name__ == '__main__':
  try:
    action, location = sys.argv[1:]
    if action != 'preflight' and os.geteuid() != 0:
      raise ValueError('Run apply/restore with sudo.')
    {'preflight': preflight, 'apply': apply, 'restore': restore}[action](Path(location).resolve())
  except (ValueError, OSError, subprocess.CalledProcessError) as error:
    sys.exit(str(error))
