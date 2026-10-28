#!/bin/bash
# "Games" (an entry in SUPER+D): Steam's games in a launcher of their own.
# Steam writes one .desktop per installed game into ~/.local/share/applications
# (Exec=steam steam://rungameid/<id>). Those get NoDisplay=true, so the main
# launcher shows only "Games". Hyprland runs "games.sh hide" at every login: a
# game installed since then moves in at the next login or when this list opens.
#   games.sh        the list
#   games.sh hide   only hide the games from the main launcher
# Each line starts with a kaomoji from ~/.config/hopparch/game-faces.
dir=~/.local/share/applications

mapfile -t files < <(grep -l -F 'steam://rungameid/' "$dir"/*.desktop 2>/dev/null | sort -f)
for f in "${files[@]}"; do
  grep -qx 'NoDisplay=true' "$f" || sed -i '/^\[Desktop Entry\]$/a NoDisplay=true' "$f"
done
[[ ${1:-} == hide ]] && exit 0

((${#files[@]})) || { notify-send Games "No Steam games installed"; exit 0; }
# a kaomoji in front of each name, and a shorter name if one is set:
# ~/.config/hopparch/game-faces (tab-separated: appid, kaomoji, name), else
# (•_•). fuzzel shows no icons in a --dmenu list, and Steam's own icons are 32x32
faces=~/.config/hopparch/game-faces
lines=""
for f in "${files[@]}"; do
  id=$(grep -m1 -o 'rungameid/[0-9]*' "$f" | cut -d/ -f2)
  IFS=$'\t' read -r _ face short < <(awk -F'\t' -v id="$id" '$1 == id {print; exit}' "$faces" 2>/dev/null)
  name=${short:-$(grep -m1 '^Name=' "$f" | cut -d= -f2-)}
  lines+="${face:-(•_•)}  $name"$'\n'
done

# --index: fuzzel prints the chosen line's number, not its text
# --cache=/dev/null: no old launcher searches in this list
# Noto Sans: kaomoji accents sit on their letters (see kaomoji.sh)
i=$(printf '%s' "$lines" | fuzzel --dmenu --index --cache=/dev/null --font 'Noto Sans:size=13' --prompt 'games> ') || exit 0
# gio starts the .desktop file even though it is hidden from the launcher
gio launch "${files[$i]}"
