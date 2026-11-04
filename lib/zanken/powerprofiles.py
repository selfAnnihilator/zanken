"""Follow firmware power-key changes without imposing an AC/battery policy.

Some Lenovo firmware changes platform_profile without updating the power
daemon. Poll the hardware value, and only contact the daemon when it changes.
The daemon remains responsible for CPU policy, persistence and desktop signals.
"""

import argparse
from pathlib import Path
import signal
import subprocess
import sys
import time


PROFILES = {
  'low-power': 'power-saver',
  'balanced': 'balanced',
  'performance': 'performance',
}


class ProfileSynchronizer:
  def __init__(self, platform_profile):
    self.platform_profile = platform_profile
    self.previous = None

  def step(self):
    hardware = self.platform_profile.read_text().strip()
    if hardware == self.previous:
      return

    desired = PROFILES.get(hardware)
    # Custom and vendor-specific profiles must not be replaced with a guess.
    if desired:
      current = subprocess.run(
        ['powerprofilesctl', 'get'], check=True, capture_output=True,
        text=True, timeout=3).stdout.strip()
      if current != desired:
        # Fn+Q may have been pressed again while querying the daemon.
        if self.platform_profile.read_text().strip() != hardware:
          return
        subprocess.run(['powerprofilesctl', 'set', desired], check=True,
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                       timeout=3)
        print(f'Firmware power mode synchronized: {desired}', flush=True)

    # Do not acknowledge failed requests: retry after the daemon recovers.
    self.previous = hardware


def main():
  parser = argparse.ArgumentParser(description=__doc__)
  parser.add_argument('--platform-profile', type=Path,
                      default=Path('/sys/firmware/acpi/platform_profile'))
  parser.add_argument('--interval', type=float, default=1)
  args = parser.parse_args()
  if args.interval <= 0:
    parser.error('--interval must be positive')

  def stop(_signum, _frame):
    raise SystemExit(0)

  signal.signal(signal.SIGTERM, stop)
  signal.signal(signal.SIGINT, stop)
  synchronizer = ProfileSynchronizer(args.platform_profile)
  while True:
    try:
      synchronizer.step()
    except (OSError, subprocess.SubprocessError):
      print('Power service or firmware unavailable; retrying in 5 seconds.',
            file=sys.stderr, flush=True)
      time.sleep(5)
      continue
    time.sleep(args.interval)


if __name__ == '__main__':
  main()
