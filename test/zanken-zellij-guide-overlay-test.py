"""Check reclaimed guide rows, native search input and hierarchical close."""

import argparse
from pathlib import Path
import time

from zellij_pty import Workspace


def run(evidence):
  with Workspace(evidence, answer_queries=True, emulate=True) as w:
    terminal = w.terminals()[0]
    bar = w.plugin('zjstatus')
    w.check('bottom footer reserves a spacer above its tab row', bar['pane_y'] == 55 and bar['pane_rows'] == 2)
    w.check('bold tab number and local clock are visible', ' 1 ' in w.text('zjstatus') and '󰎦' not in w.text('zjstatus') and ':' in w.text('zjstatus') and '' not in w.text('zjstatus') and '↖' not in w.text('zjstatus'))
    shape = lambda: [(p['id'], p['pane_y'], p['pane_rows'], p['pane_columns']) for p in w.terminals()]
    original = shape()
    w.check('hidden guide reserves no rows', terminal['pane_y'] == 0 and terminal['pane_rows'] == 55 and w.plugin('status-bar')['is_suppressed'])
    w.key('Alt+g')
    w.wait(lambda: bool(w.guide().strip()))
    guide = w.plugin('status-bar')
    w.check('guide is a top one-row overlay', guide['is_floating'] and guide['pane_y'] == 0 and guide['pane_rows'] == 1 and guide['pane_columns'] == 265)
    w.check('reference hints keep contextual controls and dotted separators', all(k in w.guide() for k in ('PANE', 'TAB', 'RESIZE', 'MOVE', 'SESSION', '⋮')))
    w.wait(lambda: all(w.screen.buffer[0][col].bg == '242436' for col in range(265)))
    w.check('strip hints have no powerline arrows', '' not in w.guide() and '' not in w.guide())
    w.check('guide does not resize or steal terminal focus', shape() == original and f"terminal_{terminal['id']}" in w.action('list-clients'))
    w.check('unlocked mode has no tip line', 'Tip:' not in w.guide() and 'QuickNav:' not in w.guide())
    w.wait(lambda: all(w.screen.buffer[56][col].bg == '242436' for col in range(265)))
    w.check('bottom strip fills the docked row', not bar['is_floating'])
    for mode, expected in [('pane', ('New', 'Fullscreen')), ('tab', ('New', 'Rename')),
      ('resize', ('Increase', 'Decrease')), ('move', ('Location',)),
      ('scroll', ('search', 'Scroll')), ('session', ('Detach', 'Session')),
      ('tmux', ('Close', 'Detach', 'Kill'))]:
      w.action('switch-mode', mode)
      w.wait(lambda: all(word.lower() in w.guide().lower() for word in expected))
      w.check(mode + ' replaces the menu with contextual actions', 'PANE' not in w.guide() and 'Tip:' not in w.guide())
    w.action('switch-mode', 'normal')
    w.wait(lambda: 'PANE' in w.guide())

    w.key('Escape')
    w.wait(lambda: w.plugin('status-bar')['is_suppressed'])
    w.check('closing guide leaves full terminal height', shape() == original)
    w.action('new-tab', '--name', 'overlay-second')
    w.key('Alt+g')
    w.wait(lambda: bool(w.guide().strip()))
    w.check('overlay follows the active tab', w.plugin('status-bar')['tab_id'] == w.tab()['tab_id'])
    w.key('Escape')
    w.action('go-to-tab', '1')
    w.key('Alt+g')
    w.wait(lambda: w.plugin('status-bar')['tab_id'] == w.tab()['tab_id'])
    w.key('Escape')
    w.type("printf 'needle_742\\n'")
    w.key('Return')
    w.enter('s')
    w.key('s')
    w.type('needle_742')
    row = w.terminals()[0]['pane_y']
    try:
      w.wait(lambda: 'needle_742' in w.screen.display[row])
    except AssertionError:
      (w.evidence / 'search-screen.txt').write_text('\n'.join(w.screen.display))
      (w.evidence / 'search-guide.txt').write_text(w.guide())
      (w.evidence / 'search-panes.json').write_text(w.action('list-panes', '--all', '--json'))
      raise
    w.check('native search title shows typed query')
    w.key('BackSpace')
    w.wait(lambda: 'needle_74' in w.screen.display[row] and 'needle_742' not in w.screen.display[row])
    w.key('Return')
    w.check('accepted search keeps the query visible', 'needle_74' in w.screen.display[row])
    w.key('Escape')
    w.wait(lambda: w.terminals()[0]['pane_content_y'] == w.terminals()[0]['pane_y'])
    w.check('leaving search restores borderless panes')
    w.action('save-session')
    w.cli('kill-session', w.session)
    w.wait(lambda: w.proc.poll() is not None)
    w.start(resurrect=True)
    w.key('Alt+g')
    w.wait(lambda: bool(w.guide().strip()))
    w.check('guide is restored after session resurrection')
    w.key('Escape')
    w.action('new-pane', '--direction', 'right')
    w.wait(lambda: len(w.terminals()) == 2)
    focused = next(p['id'] for p in w.terminals() if p['is_focused'])
    time.sleep(.8)  # Separate deliberate closes from held-key repeat.
    w.key('Ctrl+Alt+x')
    w.wait(lambda: len(w.terminals()) == 1, 15)
    w.check('Ctrl+Alt+x closes only the active split pane', w.terminals()[0]['id'] != focused and len(w.tabs()) == 2)
    w.action('new-pane', '--floating')
    w.wait(lambda: len(w.terminals()) == 2)
    time.sleep(.8)  # Separate deliberate closes from held-key repeat.
    w.key('Ctrl+Alt+x')
    w.wait(lambda: len(w.terminals()) == 1, 15)
    w.check('Ctrl+Alt+x closes only the active floating pane', not w.terminals()[0]['is_floating'])
    time.sleep(.8)  # Separate deliberate closes from held-key repeat.
    w.key('Ctrl+Alt+x')
    w.wait(lambda: len(w.tabs()) == 1, 15)
    w.check('Ctrl+Alt+x closes a single-pane tab')
    time.sleep(.8)  # Separate deliberate closes from held-key repeat.
    w.key('Ctrl+Alt+x')
    w.wait(lambda: w.proc.poll() is not None and not list((w.root / 'runtime').glob('zanken-close-tab.*')), 15)
    w.check('Ctrl+Alt+x on the final pane clears saved state', not list((w.root / 'cache').glob(f'**/session_info/{w.session}/session-layout.kdl')))
    w.start(launcher=True)
    w.check('reopening after final close starts fresh', len(w.tabs()) == 1 and len(w.terminals()) == 1 and w.plugin('status-bar')['is_suppressed'])


def live_replacement(evidence):
  """A live update must load a background owner, not a tab-bound pane."""
  with Workspace(evidence, answer_queries=True, emulate=True) as w:
    original = [(p['id'], p['pane_y'], p['pane_rows']) for p in w.terminals()]
    w.action('close-pane', '--pane-id', w.pid('status-bar'))
    w.cli('-s', w.session, 'pipe',
      '--plugin', 'file:' + str(w.root / 'config/zellij/plugins/status-bar.wasm'),
      '--plugin-configuration', 'hide_when_locked=true,overlay=true,search_titles=true',
      '--name', 'zanken-guide-init', 'ready')
    w.wait(lambda: any(str(p.get('plugin_url', '')).endswith('/status-bar.wasm') for p in w.panes()))

    def initialized():
      w.action('send-keys', '--pane-id', w.pid('status-bar'), 'y')
      p = w.plugin('status-bar')
      return p['is_suppressed'] and not p['is_selectable'] and 'Zellij key guide' in p['title']

    w.wait(initialized)
    for _ in range(3):
      w.key('Alt+g')
      w.wait(lambda: any('PANE' in row and 'RESIZE' in row for row in w.screen.display))
      w.check('live replacement shows screen hints after hiding', not w.plugin('status-bar')['is_suppressed'])
      w.key('Escape')
      w.wait(lambda: w.plugin('status-bar')['is_suppressed'])
    w.key('Ctrl+Space')
    w.key('d')
    w.wait(lambda: w.proc.poll() is not None)
    w.start(resurrect=True)
    w.key('Alt+g')
    w.wait(lambda: any('PANE' in row and 'RESIZE' in row for row in w.screen.display))
    w.check('live replacement survives client reattachment', not w.plugin('status-bar')['is_suppressed'])
    w.check('live replacement preserves application panes and geometry', original ==
      [(p['id'], p['pane_y'], p['pane_rows']) for p in w.terminals()])


def legacy_templates(evidence):
  w = Workspace(evidence, answer_queries=True)
  layout = w.root / 'layouts/zanken.kdl'
  layout.write_text(layout.read_text().replace('    children\n',
    '    children\n    pane size=2 borderless=true { plugin location="status-bar"; }\n'))
  with w:
    guides = lambda: [p for p in w.panes() if p['is_plugin'] and
      (p.get('plugin_url') == 'status-bar' or str(p.get('plugin_url', '')).endswith('/status-bar.wasm'))]
    w.wait(lambda: len(guides()) == 1)
    w.check('legacy footer does not reserve rows', w.terminals()[0]['pane_y'] == 0 and w.terminals()[0]['pane_rows'] == 55)
    w.action('new-tab')
    w.wait(lambda: w.terminals()[0]['pane_y'] == 0 and w.terminals()[0]['pane_rows'] == 55)
    w.check('cached-template new tab also has no gap', len(guides()) == 1)


if __name__ == '__main__':
  parser = argparse.ArgumentParser(description=__doc__)
  parser.add_argument('--evidence', type=Path, default=Path('/tmp/zanken-zellij-gap/checks'))
  args = parser.parse_args()
  run(args.evidence)
  legacy_templates(args.evidence / 'legacy')
  live_replacement(args.evidence / 'live-replacement')
