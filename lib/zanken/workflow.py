"""Build the explicit portable workflow allowlist; never read personal state."""
import hashlib
import json
import re
import shutil
import subprocess
import sys
from pathlib import Path

FILES = {
  'zellij': 'config/zellij',
  'tmux/tmux.conf': 'config/tmux/tmux.conf',
  'starship.toml': 'config/starship.toml',
  'lazygit/config.yml': 'config/lazygit/config.yml',
  'fish/conf.d/zanken-workflow.fish': 'default/workflow/fish.fish',
  'fish/conf.d/zanken-zellij.fish': 'config/fish/conf.d/zanken-zellij.fish',
  'zanken/workflow.bash': 'default/workflow/bash.sh',
  'systemd/user/zanken-zellij-snapshot.service': 'config/systemd/user/zanken-zellij-snapshot.service',
  'systemd/user/zanken-zellij-snapshot.timer': 'config/systemd/user/zanken-zellij-snapshot.timer',
  'systemd/user/zanken-powerprofiles-sync.service': 'config/systemd/user/zanken-powerprofiles-sync.service',
}

def validate(source):
  plugins = source / 'config/zellij/plugins'
  sums = {}
  for line in (plugins / 'SHA256SUMS').read_text().splitlines():
    digest, name = line.split()
    if not re.fullmatch(r'[a-z-]+\.wasm', name):
      raise ValueError('Invalid plugin manifest filename')
    sums[name] = digest
  if set(sums) != {p.name for p in plugins.glob('*.wasm')}:
    raise ValueError('Plugin checksum manifest is incomplete')
  for name, digest in sums.items():
    if hashlib.sha256((plugins / name).read_bytes()).hexdigest() != digest:
      raise ValueError(f'Plugin checksum mismatch: {name}')
  version = subprocess.check_output(['zellij', '--version'], text=True).strip()
  if version != 'zellij 0.45.1':
    raise ValueError(f'{version}: bundled plugins require validated Zellij 0.45.1; rebuild and test plugins before upgrading')
  subprocess.run(['fish', '--no-config', '-n', str(source / 'default/workflow/fish.fish')], check=True)

def preflight(source):
  from hardware import available, command
  packages = set()
  for manifest in ('zanken-desktop.packages', 'zanken-workflow.packages'):
    packages.update(line.strip() for line in (source / 'install' / manifest).read_text().splitlines()
                    if line.strip() and not line.lstrip().startswith('#'))
  for package in sorted(packages):
    available(package, allow_aur=True)
  # The refresh stage can upgrade an existing Zellij; validate its candidate too.
  metadata = command('pacman', '-Si', 'zellij', required=True).stdout
  match = re.search(r'^Version\s*:\s*(\S+)', metadata, re.MULTILINE)
  if not match or match[1].split('-', 1)[0].split(':')[-1] != '0.45.1':
    raise ValueError('Repository Zellij is not validated with the bundled 0.45.1 plugins; update and test the workflow bundle first')
  print('Desktop and workflow packages are available; Zellij plugin version is compatible.')

def stage(source, target):
  validate(source)
  target.mkdir(parents=True)
  for dest, origin in FILES.items():
    src, dst = source / origin, target / dest
    dst.parent.mkdir(parents=True, exist_ok=True)
    if src.is_dir():
      shutil.copytree(src, dst)
    else:
      shutil.copy2(src, dst)
  # Fastfetch's source branding path is host-specific; use built-in OS branding.
  (target / 'fastfetch').mkdir()
  (target / 'fastfetch/config.jsonc').write_text(json.dumps({'logo': {'type': 'auto'}, 'modules': ['os', 'kernel', 'wm', 'terminal', 'cpu', 'gpu', 'memory', 'disk']}))
  (target / 'xdg-terminals.list').write_text('foot.desktop\n')
  (target / 'targets.json').write_text(json.dumps([*FILES, 'fastfetch/config.jsonc', 'xdg-terminals.list']))

if __name__ == '__main__':
  try:
    if sys.argv[1] == 'preflight':
      preflight(Path(sys.argv[2]))
    elif sys.argv[1] == 'validate':
      validate(Path(sys.argv[2]))
    else:
      stage(Path(sys.argv[2]), Path(sys.argv[3]))
  except (ValueError, OSError, subprocess.CalledProcessError) as error:
    sys.exit(str(error))
