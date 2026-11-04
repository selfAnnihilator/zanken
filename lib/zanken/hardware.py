"""Read-only desktop hardware planning and explicit package provisioning.

PCI inventory comes from sysfs, never localized lspci marketing names.
No bootloader, network service or power-manager replacement is performed.
"""
import argparse
import json
import os
from pathlib import Path
import platform
import re
import subprocess
import sys
import urllib.parse
import urllib.request

ROOT = Path(__file__).resolve().parents[2]

def command(*args, required=False):
  result = subprocess.run(args, text=True, capture_output=True, env={**os.environ, 'LC_ALL': 'C'})
  if required and result.returncode:
    raise ValueError(f"{' '.join(args)} failed: {result.stderr.strip()}")
  return result

def inventory(sysfs=Path('/sys/bus/pci/devices')):
  devices = []
  for path in sorted(sysfs.iterdir()):
    if int((path / 'class').read_text().strip(), 16) >> 16 != 3:
      continue
    record = {key: (path / key).read_text().strip().removeprefix('0x').lower()
              for key in ('vendor', 'device', 'subsystem_vendor', 'subsystem_device')}
    record['driver'] = (path / 'driver').resolve().name if (path / 'driver').exists() else ''
    devices.append(record)
  return devices

def families(devices, table):
  result = set()
  for gpu in devices:
    vendor = gpu['vendor']
    if vendor == '10de':
      key = ':'.join(gpu[k] for k in ('device', 'subsystem_vendor', 'subsystem_device'))
      family = table.get(key, table.get(gpu['device']))
      if not family:
        raise ValueError(f"Unknown NVIDIA PCI device {key}; update the supported-device table before installation")
      result.add(family)
    elif vendor not in ('8086', '1002', '1af4', '15ad', '1234', '1b36'):
      raise ValueError(f"Unsupported graphics vendor {vendor}; configure graphics before installation")
  if len(result) > 1:
    raise ValueError('Mixed NVIDIA driver generations require manual configuration')
  return result

def kernels():
  result = []
  for pkgbase in sorted(Path('/usr/lib/modules').glob('*/pkgbase')):
    package = pkgbase.read_text().strip()
    owner = command('pacman', '-Qoq', str(pkgbase), required=True).stdout.strip()
    if not re.fullmatch(r'[a-zA-Z0-9@+_.-]+', package) or owner != package:
      raise ValueError(f'Cannot resolve kernel package metadata for {pkgbase.parent.name}')
    result.append({'release': pkgbase.parent.name, 'package': package})
  if not result:
    raise ValueError('No packaged kernels found; install a supported distribution kernel first')
  return result

def active(service):
  return command('systemctl', 'is-active', '--quiet', service).returncode == 0

def available(package, allow_aur=False):
  if command('pacman', '-T', package).returncode == 0:
    return 'installed'
  if command('pacman', '-Si', package).returncode == 0:
    return 'repository'
  # Only named legacy NVIDIA packages may fall back to the AUR here.
  if not allow_aur and package not in ('nvidia-580xx-dkms', 'nvidia-580xx-utils'):
    raise ValueError(f'Required package unavailable in enabled repositories: {package}')
  url = 'https://aur.archlinux.org/rpc/v5/info?' + urllib.parse.urlencode({'arg[]': package})
  with urllib.request.urlopen(url, timeout=20) as response:
    data = json.load(response)
  if not any(p['Name'] == package for p in data.get('results', [])):
    raise ValueError(f'Required AUR package unavailable: {package}')
  return 'aur'

def plan():
  if platform.machine() != 'x86_64' or not Path('/etc/arch-release').exists():
    raise ValueError('Desktop installation requires x86_64 Arch or an Arch-based distribution')
  devices = inventory()
  if not devices:
    raise ValueError('No PCI graphics device detected; desktop compatibility cannot be established')
  table = json.loads((ROOT / 'install/hardware/nvidia-pci.json').read_text())['devices']
  branches = families(devices, table)
  packages = []
  for vendor, package in [('8086', 'vulkan-intel'), ('1002', 'vulkan-radeon')]:
    if any(d['vendor'] == vendor for d in devices):
      packages += ['mesa', package]
  if any(d['vendor'] in ('1af4', '15ad', '1234', '1b36') for d in devices):
    packages += ['mesa']
  installed = command('pacman', '-Q', required=True).stdout
  kernel_list = kernels()
  nvidia_action = 'none'
  if branches:
    branch = next(iter(branches))
    # Verify existing modules for every installed kernel, including CachyOS.
    versions = [command('modinfo', '-k', k['release'], '-F', 'version', 'nvidia').stdout.strip()
                for k in kernel_list]
    providers = [line.split()[0] for line in installed.splitlines()
                 if 'nvidia' in line.split()[0] and ('utils' in line.split()[0] or 'dkms' in line.split()[0])]
    all_installed = command('pacman', '-Qq', required=True).stdout.splitlines()
    has_driver = any(re.search(r'(?:^nvidia(?:-open|-\d+xx)?(?:-dkms)?$|^linux.*-nvidia)', name)
                     for name in all_installed)
    if any(versions) or providers or has_driver:
      if not all(versions) or len(set(versions)) != 1:
        raise ValueError('Existing NVIDIA installation lacks matching modules for every kernel; repair it before desktop installation')
      major = int(versions[0].split('.')[0])
      if (branch == '580' and major != 580) or (branch == 'open' and major < 580):
        raise ValueError('Existing NVIDIA driver branch is incompatible or unvalidated')
      utils = [line.split()[1].split('-', 1)[0].split(':')[-1] for line in installed.splitlines()
               if re.fullmatch(r'nvidia(?:-\d+xx)?-utils', line.split()[0])]
      if utils != [versions[0]]:
        raise ValueError('NVIDIA userspace and kernel module versions do not match; repair the distribution driver stack')
      if any(d['driver'] not in ('nvidia', '') for d in devices if d['vendor'] == '10de'):
        raise ValueError('Installed NVIDIA packages conflict with the active GPU driver; resolve and reboot first')
      nvidia_action = 'preserve'
    elif all(d['driver'] == 'nouveau' for d in devices if d['vendor'] == '10de'):
      packages.append('mesa')
      nvidia_action = 'preserve-nouveau'
    else:
      if any(d['driver'] for d in devices if d['vendor'] == '10de'):
        raise ValueError('An existing NVIDIA alternative driver is active; preserve it and configure its userspace before installing Zanken')
      # DKMS + mkinitcpio is the supported automatic installation path.
      if command('pacman', '-Q', 'mkinitcpio').returncode or not list(Path('/etc/mkinitcpio.d').glob('*.preset')):
        raise ValueError('Automatic NVIDIA setup requires existing mkinitcpio presets; configure the distribution driver first')
      if command('pacman', '-Q', 'dracut').returncode == 0:
        raise ValueError('Multiple initramfs implementations detected; configure NVIDIA through the distribution first')
      for kernel in kernel_list:
        headers = kernel['package'] + '-headers'
        # Require package metadata to contain this exact kernel build directory.
        listing = command('pacman', '-Ql', headers)
        if listing.returncode:
          listing = command('pacman', '-Fl', headers)
        file_match = not listing.returncode and f"usr/lib/modules/{kernel['release']}/build/" in listing.stdout
        if not file_match:
          # File databases are often absent on fresh Arch. An exact package
          # version match is also valid for the distribution's paired packages.
          kernel_version = command('pacman', '-Q', kernel['package'], required=True).stdout.split()
          metadata = command('pacman', '-Si', headers)
          header_version = re.search(r'^Version\s*:\s*(\S+)', metadata.stdout, re.MULTILINE)
          header_name = re.search(r'^Name\s*:\s*(\S+)', metadata.stdout, re.MULTILINE)
          if (metadata.returncode or len(kernel_version) != 2 or not header_version or not header_name
              or header_name[1] != headers or header_version[1] != kernel_version[1]):
            raise ValueError(f"Cannot verify matching {headers}; synchronize package/file databases and install matching kernel headers")
        packages.append(headers)
      packages += ['dkms', 'nvidia-open-dkms', 'nvidia-utils'] if branch == 'open' else ['dkms', 'nvidia-580xx-dkms', 'nvidia-580xx-utils']
      nvidia_action = 'install'
  wifi = any(Path('/sys/class/net').glob('*/wireless'))
  network = 'NetworkManager' if active('NetworkManager') else ('iwd' if active('iwd') else 'none')
  if wifi and network == 'none':
    raise ValueError('Wi-Fi hardware requires an existing NetworkManager or iwd service; configure networking first')
  if network == 'iwd':
    packages.append('impala')
  if network == 'NetworkManager':
    packages.append('networkmanager')
  selected = {p: available(p) for p in sorted(set(packages))}
  return {'architecture': platform.machine(), 'distribution': platform.freedesktop_os_release().get('ID'),
          'gpus': devices, 'kernels': kernel_list, 'nvidia': nvidia_action,
          'network': network, 'packages': selected}

def apply(report):
  # Re-probe immediately before mutation: never execute an arbitrary saved report.
  current = plan()
  if current != report:
    raise ValueError('Hardware/package state changed since preflight; rerun installation')
  missing = [name for name, state in report['packages'].items() if state != 'installed']
  if missing:
    subprocess.run(['zanken-pkg-add', *missing], check=True)
  if report['nvidia'] == 'install':
    for kernel in report['kernels']:
      subprocess.run(['sudo', 'dkms', 'autoinstall', '-k', kernel['release']], check=True)
      command('modinfo', '-k', kernel['release'], 'nvidia', required=True)
    subprocess.run(['sudo', 'mkinitcpio', '-P'], check=True)
    print('NVIDIA installed. Reboot before starting the desktop; current modules were not reloaded.')

if __name__ == '__main__':
  parser = argparse.ArgumentParser()
  parser.add_argument('action', choices=['plan', 'apply'])
  parser.add_argument('report', type=Path)
  args = parser.parse_args()
  try:
    if args.action == 'plan':
      report = plan()
      args.report.write_text(json.dumps(report, indent=2) + '\n')
      print(json.dumps(report, indent=2))
    else:
      apply(json.loads(args.report.read_text()))
  except (ValueError, OSError, subprocess.CalledProcessError) as error:
    sys.exit(f'Hardware preflight: {error}')
