"""Versioned workflow activation, update and rollback using real Git fixtures."""
import os
from pathlib import Path
import shutil
import unittest
from test_generations import GenerationTests
from test_release import ROOT

class WorkflowGenerationTests(GenerationTests):
  def setUp(self):
    super().setUp()
    for name in ('default/workflow', 'config/zellij', 'config/tmux', 'config/lazygit', 'config/fish', 'config/systemd/user'):
      shutil.copytree(ROOT / name, self.repo / name, dirs_exist_ok=True)
    shutil.copy2(ROOT / 'config/starship.toml', self.repo / 'config/starship.toml')
    shutil.copy2(ROOT / 'lib/zanken/workflow.py', self.repo / 'lib/zanken/workflow.py')
    tools = Path(self.temp.name) / 'tools'
    for name, body in [('zellij', 'echo "zellij 0.45.1"'), ('fish', 'exit 0'), ('systemctl', 'exit 0')]:
      path = tools / name
      path.write_text('#!/bin/bash\n'+body+'\n')
      path.chmod(0o755)
    self.env['ZANKEN_INSTALL_WORKFLOW'] = '1'
    self.git('add', '.')
    self.advance()

  def test_workflow_update_and_rollback(self):
    original = self.cli('switch', 'dev')
    path = self.config / 'starship.toml'
    before = path.read_text()
    self.assertTrue(path.is_symlink())
    source = self.repo / 'config/starship.toml'
    source.write_text(before+'\n# next workflow\n')
    self.git('add', '.')
    self.advance('4.1.0-alpha')
    self.cli('update')
    self.assertIn('# next workflow', path.read_text())
    self.cli('rollback')
    self.assertEqual(path.read_text(), before)
    self.assertEqual(self.installed()['current']['generation'], original['current']['generation'])

  def test_failed_activation_restores_workflow_files(self):
    self.config.mkdir(parents=True, exist_ok=True)
    (self.config / 'starship.toml').write_text('user original')
    self.env['WAYLAND_DISPLAY'] = 'isolated-fake'
    self.env['QS_FAIL'] = '1'
    self.cli('switch', 'dev', '--adopt', ok=False)
    self.assertEqual((self.config / 'starship.toml').read_text(), 'user original')
    self.assertFalse((self.config / 'zanken/workflow-enabled').exists())

if __name__ == '__main__': unittest.main()
