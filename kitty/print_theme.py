from pathlib import Path
from kittens.tui.handler import result_handler

THEME_DIR   = Path.home() / ".config" / "kitty" / "themes"
INDEX_FILE  = THEME_DIR / ".current_theme_index"
NAME_FILE   = Path.home() / ".cache" / "kitty_theme"

def main(args):
    return args

def get_theme_name():
    if NAME_FILE.exists():
        return NAME_FILE.read_text().strip()
    try:
        idx = int(INDEX_FILE.read_text().strip())
    except Exception:
        return None
    themes = sorted(THEME_DIR.glob("*.conf"))
    if not themes:
        return None
    return themes[idx].stem

@result_handler(no_ui=True)
def handle_result(args, data, target_window_id, boss):
    theme_name = get_theme_name()
    if not theme_name:
        return
    theme_path = THEME_DIR / f"{theme_name}.conf"

    if "-new_window" in args:
        before_ids = {w.id for w in boss.active_tab.windows}
        boss.call_remote_control(
            boss.active_window,
            ("launch", "--type=window", "--copy-colors")
        )

        # Find the newly created pane (window inside tab)
        new_win = None
        for w in boss.active_tab.windows:
            if w.id not in before_ids:
                new_win = w
                break

        # Apply theme explicitly to new pane
        if new_win and theme_path.exists():
            boss.call_remote_control(
                new_win,
                ("set-colors", "--match", f"id:{new_win.id}", str(theme_path))
            )
        return

    # Otherwise just print current theme
    w = boss.window_id_map.get(target_window_id) or boss.active_window
    if not w:
        return
    boss.call_remote_control(
        w,
        ("send-text", "--match", f"id:{w.id}", f"# Current theme: {theme_name}\r")
    )
