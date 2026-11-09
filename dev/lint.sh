#!/bin/bash
# Static checks, no root: shellcheck on every shell script, and every Lua file
# must parse. Runs in CI next to check.sh. Needs shellcheck and luajit.
set -euo pipefail
cd "$(dirname "$0")/.."

# every tracked file that starts with a bash/sh shebang
mapfile -t scripts < <(git ls-files | while read -r f; do
  [[ -f $f ]] && head -c 32 "$f" | grep -qE '^#!.*\b(ba)?sh\b' && echo "$f"; done)
# SC1090: check.sh sources a file it builds at run time
shellcheck -S warning -e SC1090 "${scripts[@]}"

bad=0
while read -r f; do
  # -bl lists the bytecode: the file is compiled, never run
  luajit -bl "$f" >/dev/null || bad=1
done < <(git ls-files '*.lua')
((bad == 0)) || { echo "FAIL a Lua file does not parse" >&2; exit 1; }

echo "OK ${#scripts[@]} shell scripts, $(git ls-files '*.lua' | wc -l) Lua files"
