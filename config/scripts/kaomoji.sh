#!/bin/bash
# Ctrl+Super+. Pick a kaomoji. It is copied, and typed where the cursor is.
# The menu: your own ones first (~/.config/hopparch/kaomoji, one per line), then
# the everyday set, then folders (▸) with more, then "+ add a kaomoji", which asks
# for a new one (paste it with Ctrl+V) and adds it to your own list.
# Noto Sans is proportional, so the stacked marks sit on the letters.
# A monospace font draws those marks in their own cells, which looks broken.
set -u
mine=${XDG_CONFIG_HOME:-$HOME/.config}/hopparch/kaomoji
add='+ add a kaomoji'
back='◂ back'
menu=(fuzzel --dmenu --cache=/dev/null --font 'Noto Sans:size=18' --width 36 --lines 15)

everyday=$(cat <<'EOF'
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
(⊙_⊙)
ಠ_ಠ
(ง •̀_•́)ง
ᕦ( ͡° ͜ʖ ͡°)ᕤ
(☞ ͡° ͜ʖ ͡°)☞
EOF
)

# Folders, in menu order.
folders=(happy hype tables sleepy awkward)
declare -A folder
folder[happy]=$(cat <<'EOF'
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
(ﾉ◕ヮ◕)ﾉ*:・ﾟ✧
(ﾉ´ヮ`)ﾉ*: ･ﾟ
(ﾉ≧∀≦)ﾉ
o/\o
EOF
)
folder[hype]=$(cat <<'EOF'
ᕦ(ò_óˇ)ᕤ
ᕙ(⇀‸↼‶)ᕗ
ᕕ( ᐛ )ᕗ
(ง'̀-'́)ง
(ง ͠° ͟ل͜ ͡°)ง
(๑•̀ㅂ•́)و✧
✧٩(ˊωˋ*)و✧
٩(ˊᗜˋ*)و
(๑˃ᴗ˂)ﻭ
( •̀ᴗ•́ )و
٩(๑•̀o•́๑)و
୧(๑•̀ᗝ•́)૭
┗(•̀へ •́ ╮ )
(っ•̀ω•́)っ✎⁾⁾
(۶ૈ ᵒ̌ Дᵒ̌)۶ૈ=͟͟͞͞ ⌨
(｀・ω・´)ゞ
(￣ー￣)ゞ
EOF
)
folder[tables]=$(cat <<'EOF'
(╯°□°)╯︵ ┻━┻
(ﾉಠ益ಠ)ﾉ彡┻━┻
┬─┬ノ( º _ ºノ)
┬─┬ノ(ಠ_ಠノ)
EOF
)
folder[sleepy]=$(cat <<'EOF'
(っ˘ω˘ς)
(˘ω˘)zzZ
˚✧₊⁎( ˘ω˘ )⁎⁺˳✧༚
EOF
)
folder[awkward]=$(cat <<'EOF'
(・_・;)
(・_・ヾ
(￣▽￣;)
¯\_(ツ)_/¯
(っ˘̩╭╮˘̩)っ
EOF
)

choice=$(
  { [[ -r $mine ]] && cat -- "$mine"
    printf '%s\n' "$everyday"
    printf '▸ %s\n' "${folders[@]}"
    printf '%s\n' "$add"
  } | "${menu[@]}" --prompt 'kaomoji> ' || true
)
[[ -n ${choice:-} ]] || exit 0

# A folder opens its own list; "◂ back" starts over at the top.
if [[ $choice == '▸ '* ]]; then
  name=${choice#'▸ '}
  [[ -n ${folder[$name]:-} ]] || exit 0
  choice=$(printf '%s\n' "$back" "${folder[$name]}" | "${menu[@]}" --prompt "$name> " || true)
  [[ -n ${choice:-} ]] || exit 0
  [[ $choice == "$back" ]] && exec "$0"
fi

if [[ $choice == "$add" ]]; then
  new=$("${menu[@]}" --prompt-only 'new kaomoji> ' --placeholder 'paste with Ctrl+V' || true)
  # First line only, without the spaces around it.
  new=$(sed -n '1{s/^[[:space:]]*//; s/[[:space:]]*$//; p}' <<<"${new:-}")
  [[ -n $new && $new != "$add" && $new != '▸ '* ]] || exit 0
  # Already in your list: nothing to add. (It may also sit in a folder; yours come first.)
  grep -qxF -- "$new" "$mine" 2>/dev/null && exit 0
  mkdir -p -- "${mine%/*}"
  printf '%s\n' "$new" >> "$mine"
  exit 0
fi

printf '%s' "$choice" | wl-copy
# The picker is still the focused window if we type immediately.
sleep 0.1
# No -d: wtype 0.4 rejects "-d 0" ("Invalid sleep time"), and 0 is its default anyway.
command -v wtype >/dev/null && wtype -- "$choice" || true
