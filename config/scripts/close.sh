#!/bin/bash
# SUPER+Q: close the focused window, but never a game. A stray SUPER+Q (or
# dictation typing a "q" while SUPER is still held) would end a match without
# saving. A game = a Steam game window or anything on the "games" workspace;
# those quit from their own menu.
w=$(hyprctl activewindow -j) || exit 0
class=$(jq -r '.class // ""' <<<"$w")
ws=$(jq -r '.workspace.name // ""' <<<"$w")
[[ $class == steam_app_* || $ws == games ]] && exit 0
hyprctl dispatch 'hl.dsp.window.close()' >/dev/null
