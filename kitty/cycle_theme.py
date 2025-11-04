# Cycle kitty theme for the focused window (no extra windows)
from pathlib import Path
from kittens.tui.handler import result_handler

THEME_DIR = Path.home() / ".config" / "kitty" / "themes"
INDEX_FILE = THEME_DIR / ".current_theme_index"
CACHE_FILE = Path.home() / ".cache" / "kitty_current_theme"

def main(args):
    # No UI; we do everything in handle_result
    return None

@result_handler(no_ui=True)
def handle_result(args, data, target_window_id, boss):
    themes = sorted(THEME_DIR.glob("*.conf"))
    if not themes:
        return

    # read/update index
    try:
        idx = int(INDEX_FILE.read_text().strip())
    except Exception:
        idx = 0
    nxt = (idx + 1) % len(themes)
    theme_path = str(themes[nxt])

    # resolve target window
    w = boss.window_id_map.get(target_window_id) or boss.active_window
    if w is None:
        return

    # apply only to that window
    boss.call_remote_control(
        w,
        ("set-colors", "--match", f"id:{w.id}", theme_path)
    )

    # persist state
    INDEX_FILE.write_text(str(nxt))
    CACHE_FILE.write_text(f'export KITTY_THEME="{themes[nxt].stem}"\n')
