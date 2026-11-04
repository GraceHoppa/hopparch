#!/bin/bash
# Draw ~/.config/hopparch/wallpaper when that file exists: a copy of the
# picture, not a link, so the config folder holds it. No file, or no hyprpaper:
# leave the black background. The picture is not part of hopparch.
set -u
path=$HOME/.config/hopparch/wallpaper
[[ -f $path ]] || exit 0
command -v hyprpaper >/dev/null || exit 0
mkdir -p "$HOME/.config/hypr"
# hyprpaper 0.8: a wallpaper block. Empty monitor = every screen.
# cover scales the picture to fill the screen.
cat >"$HOME/.config/hypr/hyprpaper.conf" <<EOF
wallpaper {
    monitor =
    path = $path
    fit_mode = cover
}
EOF
if pgrep -x hyprpaper >/dev/null; then
  pkill -x hyprpaper || true
  sleep 0.2
fi
hyprpaper >/dev/null 2>&1 &
exit 0
