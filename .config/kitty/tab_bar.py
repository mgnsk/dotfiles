import os
import socket
import time

from kitty.fast_data_types import add_timer, get_boss
from kitty.tab_bar import DrawData, ExtraData, Screen, TabBarData, as_rgb, draw_title
from kitty.rgb import color_as_int

STATUS_INTERVAL = 15.0

_active_tab_id = None
_timer_started = False


def _tick(timer_id: int) -> None:
    for tm in get_boss().os_window_map.values():
        tm.mark_tab_bar_dirty()


def _ensure_timer_started() -> None:
    global _timer_started
    if not _timer_started:
        _timer_started = True
        add_timer(_tick, STATUS_INTERVAL, True)


def _abbreviate_home(path: str) -> str:
    home = os.path.expanduser('~')
    if path == home:
        return '~'
    if path.startswith(home + '/'):
        return '~' + path[len(home):]
    return path


def _right_status() -> str:
    tab = get_boss().tab_for_id(_active_tab_id) if _active_tab_id is not None else None
    cwd = _abbreviate_home((tab.get_cwd_of_active_window() if tab else '') or '')
    user = os.environ.get('USER') or os.environ.get('LOGNAME') or ''
    host = socket.gethostname().split('.')[0]
    now = time.localtime()
    return f'"{user}@{host}:{cwd}"  {time.strftime("%H:%M", now)}  {time.strftime("%d-%b-%y", now)}'


def draw_tab(
    draw_data: DrawData, screen: Screen, tab: TabBarData, before: int, max_tab_length: int,
    index: int, is_last: bool, extra_data: ExtraData,
) -> int:
    global _active_tab_id
    _ensure_timer_started()
    if tab.is_active:
        _active_tab_id = tab.tab_id

    # Flat, background-free style: every tab uses the same colors and font
    # weight, so the "*" the title template already appends is the only
    # thing marking the active tab.
    screen.cursor.bg = as_rgb(color_as_int(draw_data.default_bg))
    screen.cursor.fg = as_rgb(color_as_int(draw_data.inactive_fg))
    screen.cursor.bold = False
    screen.cursor.italic = False

    if screen.cursor.x == 0:
        screen.draw(' ')

    draw_title(draw_data, screen, tab, index, max_tab_length)
    screen.draw('  ')
    end = screen.cursor.x

    if is_last:
        status = _right_status()
        avail = screen.columns - screen.cursor.x
        if avail > 1 and len(status) > avail - 1:
            status = status[len(status) - (avail - 1):]
        if avail > 1 and status:
            screen.cursor.x = screen.columns - len(status)
            screen.cursor.bg = as_rgb(color_as_int(draw_data.default_bg))
            screen.cursor.fg = as_rgb(color_as_int(draw_data.inactive_fg))
            screen.cursor.bold = False
            screen.cursor.italic = False
            screen.draw(status)

    return end
