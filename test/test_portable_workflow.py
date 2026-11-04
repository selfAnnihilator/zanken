"""Portable workflow tests: private homes, mocked commands, no host mutation."""
import importlib.util
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]

def load(name):
  spec = importlib.util.spec_from_file_location(name, ROOT / f'lib/zanken/{name}.py')
  module = importlib.util.module_from_spec(spec)
  spec.loader.exec_module(module)
  return module

hardware = load('hardware')
workflow = load('workflow')

class HardwareTests(unittest.TestCase):
  def gpu(self, vendor='10de', device='1f08', driver=''):
    return dict(vendor=vendor, device=device, subsystem_vendor='0000', subsystem_device='0000', driver=driver)

  def test_vendor_and_nvidia_matrix(self):
    table = json.loads((ROOT / 'install/hardware/nvidia-pci.json').read_text())['devices']
    for gpus, expected in [([self.gpu()], {'open'}), ([self.gpu(device='1b80')], {'580'}),
       ([self.gpu('8086'), self.gpu()], {'open'}), ([self.gpu('1002'), self.gpu()], {'open'}),
       ([self.gpu('8086')], set()), ([self.gpu('1002')], set()), ([self.gpu('1af4')], set())]:
      self.assertEqual(hardware.families(gpus, table), expected)
    for gpus in [[self.gpu(device='ffff')], [self.gpu(), self.gpu(device='1b80')]]:
      with self.assertRaises(ValueError): hardware.families(gpus, table)

  def run_plan(self, gpus, modules=None, installed='', headers=True):
    from contextlib import ExitStack
    with tempfile.TemporaryDirectory() as directory, ExitStack() as stack:
      root = Path(directory)
      (root / 'etc/mkinitcpio.d').mkdir(parents=True)
      (root / 'etc/arch-release').touch()
      (root / 'etc/mkinitcpio.d/linux.preset').touch()
      (root / 'sys/class/net').mkdir(parents=True)
      stack.enter_context(patch.object(hardware, 'Path', side_effect=lambda p: root / str(p).lstrip('/')))
      stack.enter_context(patch.object(hardware, 'inventory', return_value=gpus))
      stack.enter_context(patch.object(hardware, 'kernels', return_value=[
        {'release': 'arch-kernel', 'package': 'linux'},
        {'release': 'cachy-kernel', 'package': 'linux-cachyos'}]))
      stack.enter_context(patch.object(hardware.platform, 'machine', return_value='x86_64'))
      stack.enter_context(patch.object(hardware.platform, 'freedesktop_os_release', return_value={'ID':'cachyos'}))
      stack.enter_context(patch.object(hardware, 'active', return_value=False))
      stack.enter_context(patch.object(hardware, 'available', return_value='repository'))
      def command(*args, **kwargs):
        output, code = '', 0
        if args == ('pacman', '-Q'): output = installed
        elif args == ('pacman', '-Qq'): output = '\n'.join(line.split()[0] for line in installed.splitlines())
        elif args[:1] == ('modinfo',): output = (modules or {}).get(args[2], '')
        elif args == ('pacman', '-Q', 'dracut'): code = 1
        elif args[:2] in [('pacman', '-Ql'), ('pacman', '-Fl')]:
          if headers:
            release = 'cachy-kernel' if args[2] == 'linux-cachyos-headers' else 'arch-kernel'
            output = f'{args[2]} usr/lib/modules/{release}/build/Makefile'
          else: code = 1
        return subprocess.CompletedProcess(args, code, output, '')
      stack.enter_context(patch.object(hardware, 'command', side_effect=command))
      return hardware.plan()

  def test_missing_nvidia_resolves_all_distribution_kernel_headers(self):
    report = self.run_plan([self.gpu()])
    self.assertEqual(report['nvidia'], 'install')
    self.assertTrue({'linux-headers','linux-cachyos-headers','nvidia-open-dkms'} <= report['packages'].keys())
    legacy = self.run_plan([self.gpu(device='1b80')])
    self.assertIn('nvidia-580xx-dkms', legacy['packages'])

  def test_preserves_distribution_driver_and_hybrid_dependencies(self):
    report = self.run_plan([self.gpu(driver='nvidia'), self.gpu('1002')],
      modules={'arch-kernel':'590.48.01','cachy-kernel':'590.48.01'},
      installed='linux-cachyos-nvidia-open 590.48.01-1\nnvidia-utils 590.48.01-1\n')
    self.assertEqual(report['nvidia'], 'preserve')
    self.assertEqual(set(report['packages']), {'mesa','vulkan-radeon'})

  def test_incomplete_headers_or_existing_driver_fail(self):
    with self.assertRaisesRegex(ValueError, 'headers'):
      self.run_plan([self.gpu()], headers=False)
    with self.assertRaisesRegex(ValueError, 'every kernel'):
      self.run_plan([self.gpu(driver='nvidia')], modules={'arch-kernel':'590.48.01'}, installed='nvidia-utils 590.48.01-1\n')
    with self.assertRaisesRegex(ValueError, 'versions do not match'):
      self.run_plan([self.gpu(driver='nvidia')], modules={'arch-kernel':'590.48.01','cachy-kernel':'590.48.01'}, installed='nvidia-utils 580.95.05-1\n')

  def test_preserves_nouveau(self):
    report = self.run_plan([self.gpu(driver='nouveau')])
    self.assertEqual(report['nvidia'], 'preserve-nouveau')
    self.assertEqual(set(report['packages']), {'mesa'})

  def test_audio_function_is_not_graphics(self):
    with tempfile.TemporaryDirectory() as directory:
      base = Path(directory)
      for name, cls in [('gpu', '0x030200'), ('audio', '0x040300')]:
        dev = base / name
        dev.mkdir()
        (dev / 'class').write_text(cls)
        for key, value in self.gpu().items():
          if key != 'driver': (dev / key).write_text('0x'+value)
      self.assertEqual(len(hardware.inventory(base)), 1)

  def test_apply_rejects_changed_state_without_package_mutation(self):
    with patch.object(hardware, 'plan', return_value={'changed': True}), patch.object(hardware.subprocess, 'run') as run:
      with self.assertRaises(ValueError): hardware.apply({})
      run.assert_not_called()

  def test_dkms_failure_stops_before_initramfs(self):
    report = {'packages': {'nvidia-open-dkms': 'repository'}, 'nvidia': 'install',
              'kernels': [{'release': 'test-kernel'}]}
    calls = []
    def run(args, **kwargs):
      calls.append(args)
      if 'dkms' in args: raise subprocess.CalledProcessError(1, args)
    with patch.object(hardware, 'plan', return_value=report), patch.object(hardware.subprocess, 'run', side_effect=run):
      with self.assertRaises(subprocess.CalledProcessError): hardware.apply(report)
    self.assertFalse(any('mkinitcpio' in c for c in calls))

class WorkflowTests(unittest.TestCase):
  def test_wifi_launcher_follows_existing_network_service(self):
    with tempfile.TemporaryDirectory() as directory:
      tools = Path(directory)
      for name, body in {
        'systemctl': '[[ ${*: -1} == "$NETWORK_SERVICE" ]]',
        'zanken-launch-or-focus-tui': 'printf "%s" "$1"',
        'zanken-notification-send': 'printf unavailable'
      }.items():
        path = tools / name
        path.write_text('#!/bin/bash\n'+body+'\n')
        path.chmod(0o755)
      for service, output, code in [('NetworkManager','nmtui',0),('iwd','impala',0),('none','unavailable',1)]:
        env = {**os.environ, 'PATH':str(tools)+':'+os.environ['PATH'], 'NETWORK_SERVICE':service}
        result = subprocess.run(['bash',str(ROOT / 'bin/zanken-launch-wifi')],env=env,capture_output=True,text=True)
        self.assertEqual((result.stdout,result.returncode),(output,code))


  def test_allowlist_stages_plugins_without_personal_state(self):
    with tempfile.TemporaryDirectory() as directory, patch.object(workflow.subprocess, 'check_output', return_value='zellij 0.45.1\n'), patch.object(workflow.subprocess, 'run'):
      target = Path(directory) / 'workflow'
      workflow.stage(ROOT, target)
      self.assertTrue((target / 'zellij/plugins/zjstatus.wasm').is_file())
      self.assertTrue((target / 'fish/conf.d/zanken-zellij.fish').is_file())
      for file in target.rglob('*'):
        if file.is_file() and file.suffix != '.wasm':
          self.assertNotIn('/home/abhi', file.read_text())
      self.assertFalse((target / 'git').exists())
      self.assertFalse((target / 'zellij-session-history').exists())
      unit = (target / 'systemd/user/zanken-zellij-snapshot.service').read_text()
      self.assertIn('current-release/source/', unit)
      self.assertNotIn('%h/zanken/', unit)

  def test_unvalidated_zellij_version_fails(self):
    with patch.object(workflow.subprocess, 'check_output', return_value='zellij 9.0.0\n'):
      with self.assertRaisesRegex(ValueError, 'require validated'): workflow.validate(ROOT)

  def test_corrupt_plugin_fails_before_activation(self):
    with tempfile.TemporaryDirectory() as directory:
      root = Path(directory)
      shutil.copytree(ROOT / 'config/zellij', root / 'config/zellij')
      (root / 'config/zellij/plugins/share.wasm').write_bytes(b'broken')
      with self.assertRaisesRegex(ValueError, 'checksum mismatch'): workflow.validate(root)

  def test_shell_integration_is_idempotent_and_keeps_settings(self):
    with tempfile.TemporaryDirectory() as directory:
      root = Path(directory)
      tools = root / 'tools'
      tools.mkdir()
      stub = tools / 'systemctl'
      stub.write_text('#!/bin/bash\n[[ $1 == "--user" ]]\n')
      stub.chmod(0o755)
      (root / '.bashrc').write_text('export MY_SETTING=kept\n')
      env = {**os.environ, 'HOME': str(root), 'PATH': str(tools)+':'+os.environ['PATH']}
      for _ in range(2):
        subprocess.run(['bash', '-e', str(ROOT / 'install/config/workflow.sh')], env=env, check=True)
      contents = (root / '.bashrc').read_text()
      self.assertIn('export MY_SETTING=kept', contents)
      self.assertEqual(contents.count('source "$HOME/.config/zanken/workflow.bash"'), 1)

if __name__ == '__main__': unittest.main()
