from typing import Any, List

from kittens.tui.handler import result_handler
try:
    # For kitty v0.42+
    from kitty.typing_compat import BossType
except ModuleNotFoundError:
    # Fallback for older versions of kitty.
    from kitty.typing import BossType


def main(args: List[str]) -> None:
    pass


@result_handler(no_ui=True)
def handle_result(args: List[str], data: Any, target_window_id: int, boss: BossType) -> None:
    tm = boss.active_tab_manager_with_dispatch
    if tm is None:
        return
    tabs = tuple(tm.tabs_to_be_shown_in_tab_bar)
    at = tm.active_tab
    if not tabs or at is None or at not in tabs:
        return
    idx = tabs.index(at)
    delta = -1 if len(args) > 1 and args[1] == 'prev' else 1
    new_idx = (idx + delta) % len(tabs)
    tm.set_active_tab(tabs[new_idx])
