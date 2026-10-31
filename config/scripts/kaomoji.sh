#!/bin/bash
# Ctrl+Super+. Pick a kaomoji. It is copied, and typed where the cursor is.
# The last entry, "+ add a kaomoji", asks for a new one (paste it with Ctrl+V)
# and keeps it in ~/.config/hopparch/kaomoji, one per line, after the built-in ones.
# Noto Sans is proportional, so the stacked marks sit on the letters.
# A monospace font draws those marks in their own cells, which looks broken.
set -u
mine=${XDG_CONFIG_HOME:-$HOME/.config}/hopparch/kaomoji
add='+ add a kaomoji'
menu=(fuzzel --dmenu --cache=/dev/null --font 'Noto Sans:size=18' --width 36)

builtin=$(cat <<'EOF'
(◕‿◕)
(^▽^)
(♥ω♥)
(˘ ³˘)♥
(˶ᵔ ᵕ ᵔ˶)♡
(⁄ ⁄•⁄ω⁄•⁄ ⁄)
(◞‸◟)
¯\_(´-`)_/¯
(T_T)
(╯°□°)╯┻━┻
(ﾉಠ益ಠ)ﾉ彡┻━┻
(⊙_⊙)
ಠ_ಠ
(ง •̀_•́)ง
ᕦ( ͡° ͜ʖ ͡°)ᕤ
(☞ ͡° ͜ʖ ͡°)☞
( ˘ᵕ˘ )
(´｡• ᵕ •｡`)
(´｡• ω •｡`) ♡
٩(◕‿◕)۶
(≧▽≦)
(^▽^)/
(￣▽￣)
(￣ー￣)b
(・ω・)b
(・ω・)ノ
(｡•̀ᴗ-)✧
(๑•̀ㅂ•́)و✧
✧٩(ˊωˋ*)و✧
٩(ˊᗜˋ*)و
(๑˃ᴗ˂)ﻭ
( •̀ᴗ•́ )و
(ﾉ◕ヮ◕)ﾉ*:・ﾟ✧
(ﾉ´ヮ`)ﾉ*: ･ﾟ
(ﾉ≧∀≦)ﾉ
(｀・ω・´)ゞ
(￣ー￣)ゞ
ᕦ(ò_óˇ)ᕤ
ᕙ(⇀‸↼‶)ᕗ
ᕕ( ᐛ )ᕗ
٩(๑•̀o•́๑)و
୧(๑•̀ᗝ•́)૭
(ง'̀-'́)ง
(ง ͠° ͟ل͜ ͡°)ง
┗(•̀へ •́ ╮ )
(っ•̀ω•́)っ✎⁾⁾
(۶ૈ ᵒ̌ Дᵒ̌)۶ૈ=͟͟͞͞ ⌨
(╯°□°)╯︵ ┻━┻
┬─┬ノ( º _ ºノ)
┬─┬ノ(ಠ_ಠノ)
o/\o
¯\_(ツ)_/¯
(・_・;)
(・_・ヾ
(￣▽￣;)
(っ˘ω˘ς)
(˘ω˘)zzZ
˚✧₊⁎( ˘ω˘ )⁎⁺˳✧༚
(っ˘̩╭╮˘̩)っ
EOF
)

choice=$(
  { printf '%s\n' "$builtin"; [[ -r $mine ]] && cat -- "$mine"; printf '%s\n' "$add"; } |
    "${menu[@]}" --prompt 'kaomoji> ' --lines 15 || true
)
[[ -n ${choice:-} ]] || exit 0

if [[ $choice == "$add" ]]; then
  new=$("${menu[@]}" --prompt-only 'new kaomoji> ' --placeholder 'paste with Ctrl+V' || true)
  # First line only, without the spaces around it.
  new=$(sed -n '1{s/^[[:space:]]*//; s/[[:space:]]*$//; p}' <<<"${new:-}")
  [[ -n $new && $new != "$add" ]] || exit 0
  # Already in the list: nothing to add.
  { printf '%s\n' "$builtin"; cat -- "$mine" 2>/dev/null; } | grep -qxF -- "$new" && exit 0
  mkdir -p -- "${mine%/*}"
  printf '%s\n' "$new" >> "$mine"
  exit 0
fi

printf '%s' "$choice" | wl-copy
# The picker is still the focused window if we type immediately.
sleep 0.1
# No -d: wtype 0.4 rejects "-d 0" ("Invalid sleep time"), and 0 is its default anyway.
command -v wtype >/dev/null && wtype -- "$choice" || true
