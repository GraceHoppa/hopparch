#!/bin/bash
# SUPER+D: the apps, and searching finds the ones inside Games and Stashed apps too.
# Fuzzel's own app list can't search a NoDisplay entry, so this builds the list and
# uses its dmenu mode. Fuzzel can't hide a line until you type, so those apps sit
# below the normal ones: out of the way, but there if you scroll down.
#   launcher.sh        the launcher
#   launcher.sh list   only print the list
shopt -s nullglob

entries() {
  local dir dirs files=()
  IFS=: read -ra dirs <<<"${XDG_DATA_HOME:-$HOME/.local/share}:${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
  for dir in "${dirs[@]}"; do files+=("$dir"/applications/*.desktop); done
  ((${#files[@]})) || return 0

  # Prints: rank, name, file, words to search, icon (0 = normal, 1 = game, 2 = stashed)
  # A file in an earlier directory overrides the same name in a later one.
  gawk -v stash="$HOME/.config/hopparch/stashed.list" '
    BEGIN {
      FS = "="; OFS = "\t"
      while ((getline line < stash) > 0) if (line !~ /^[[:space:]]*(#|$)/) stashed[line] = 1
    }
    BEGINFILE {
      id = FILENAME; sub(/.*\//, "", id); sub(/\.desktop$/, "", id)
      # nextfile here still runs ENDFILE, hence the skip flag
      skip = (id in seen)
      if (skip) nextfile
      delete v; section = ""
    }
    /^\[/ { section = $0; next }
    section == "[Desktop Entry]" && /^[A-Za-z]+=/ && !($1 in v) {
      key = $1; sub(/^[^=]*=/, ""); v[key] = $0
    }
    ENDFILE {
      # A stashed app is hidden by an override file: its real entry is in a later directory.
      if (!skip && !(id in stashed && v["Hidden"] == "true")) {
        seen[id] = 1
        rank = -1
        if (v["Type"] != "Application" || v["Name"] == "" || v["Hidden"] == "true") rank = -1
        else if (v["TryExec"] != "" && system("command -v \"" v["TryExec"] "\" >/dev/null 2>&1")) rank = -1
        else if (v["Exec"] ~ /steam:\/\/rungameid\//) rank = 1
        else if (id in stashed) rank = 2
        else if (v["NoDisplay"] != "true") rank = 0
        if (rank >= 0) print rank, v["Name"], FILENAME, v["Name"] " " v["GenericName"] " " id, v["Icon"]
      }
    }
  ' "${files[@]}" | sort -t $'\t' -k1,1n -k2,2f
}

mapfile -t rows < <(entries)
declare -A files
for row in "${rows[@]}"; do
  IFS=$'\t' read -r _ _ path _ <<<"$row"
  id=${path##*/}
  files[${id%.desktop}]=$path
done

# Columns: name, id, words to search. "\0icon\x1f<name>" = the line's icon. The line
# holds the id and not the path: a path's letters would match almost any search.
list() {
  local name path words icon id
  for row in "${rows[@]}"; do
    IFS=$'\t' read -r _ name path words icon <<<"$row"
    id=${path##*/}
    printf '%s\t%s\t%s\0icon\x1f%s\n' "$name" "${id%.desktop}" "$words" "$icon"
  done
}

[[ ${1:-} == list ]] && { list; exit 0; }

# The name shows, the id comes back. match-mode=exact: fuzzel's default fzf mode also
# lists whatever matches a part of what you typed. Its own cache keeps the most used
# apps on top (fuzzel's normal cache holds .desktop ids, not these lines).
id=$(list | fuzzel --dmenu --only-match --match-mode=exact --with-nth=1 --match-nth=3 --accept-nth=2 \
  --cache="${XDG_CACHE_HOME:-$HOME/.cache}/fuzzel-launcher") || exit 0
[[ -n $id && -n ${files[$id]:-} ]] || exit 0
# gio starts the .desktop file even when it is hidden from the launcher
exec gio launch "${files[$id]}"
