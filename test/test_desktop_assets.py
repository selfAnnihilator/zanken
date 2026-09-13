import os
import pathlib
import subprocess
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]


class DesktopAssetsTests(unittest.TestCase):
  def test_logo_font_installs_from_tracked_asset(self):
    with tempfile.TemporaryDirectory() as directory:
      home = pathlib.Path(directory) / 'home'
      fake_bin = pathlib.Path(directory) / 'bin'
      home.mkdir()
      fake_bin.mkdir()
      fc_cache = fake_bin / 'fc-cache'
      fc_cache.write_text('#!/bin/bash\nexit 0\n')
      fc_cache.chmod(0o755)
      env = dict(os.environ, HOME=str(home), ZANKEN_PATH=str(ROOT),
                 PATH=str(fake_bin) + ':' + os.environ['PATH'])
      result = subprocess.run(
        ['bash', '-e', '-c', f'source "{ROOT / "install/packaging/fonts.sh"}"'],
        env=env, capture_output=True, text=True)
      self.assertEqual(result.returncode, 0, result.stderr)
      installed = home / '.local/share/fonts/omarchy.ttf'
      self.assertTrue(installed.exists())
      self.assertEqual(installed.read_bytes(), (ROOT / 'config/omarchy.ttf').read_bytes())

  def test_install_preserves_user_wallpaper_and_old_cursor(self):
    with tempfile.TemporaryDirectory() as directory:
      home = pathlib.Path(directory)
      old = home / '.local/share/icons/Hornet/cursors'
      old.mkdir(parents=True)
      (old / 'left_ptr').write_text('old cursor')
      wallpapers = home / 'Pictures/wallpaper'
      wallpapers.mkdir(parents=True)
      selected = wallpapers / 'wallhaven-lydzk2_3840x2160.png'
      selected.write_text('user version')
      env = dict(os.environ, HOME=directory, ZANKEN_PATH=str(ROOT))
      for _ in range(2):
        subprocess.run(['bash', '-e', str(ROOT / 'install/config/desktop-assets.sh')],
                       env=env, check=True, capture_output=True)
      self.assertEqual(selected.read_text(), 'user version')
      self.assertEqual((old / 'left_ptr').read_text(), 'old cursor')
      self.assertTrue((home / '.local/share/icons/Brushbuddy/cursors/left_ptr').exists())
      self.assertEqual((home / '.config/zanken/current/background').resolve(), selected)
      for gtk in ('gtk-3.0', 'gtk-4.0'):
        contents = (home / '.config' / gtk / 'settings.ini').read_text()
        self.assertEqual(contents.count('gtk-cursor-theme-name=Brushbuddy'), 1)
        self.assertIn('gtk-cursor-theme-size=40', contents)

  def test_browser_packages_and_defaults(self):
    packages = (ROOT / 'install/zanken-base.packages').read_text().splitlines()
    self.assertIn('zen-browser-bin', packages)
    self.assertIn('qutebrowser', packages)
    config = (ROOT / 'install/config/mimetypes.sh').read_text()
    self.assertIn('default-web-browser zen.desktop', config)
    self.assertIn('zanken-default-quick-browser qutebrowser', config)
