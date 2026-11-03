#!/bin/bash
# hopparch sync -- the repo is the only place config is edited; this brings it
# to this device. No sudo: pulls the repo (fast-forward only), copies config/
# (+ the profile's) into ~/.config, reloads Hyprland if its config changed.
#   any time:     ~/.config/scripts/sync.sh
#   automatic:    hopparch-sync.timer, at login and every hour
#   setup.sh:     runs it with --no-pull for the config part
# A file you edited in ~/.config is kept as <file>.bak-<date> and replaced:
# move the change into the repo, or it is lost at the next sync.
# Changes outside ~/.config (packages, system/) still need: sudo ./setup.sh
set -euo pipefail

REPO=$HOME/hopparch
PULL=1
PROFILE_FILE="$HOME/.config/hopparch/profile"
PROFILE=""
for a in "$@"; do
  case $a in
    --no-pull) PULL=0 ;;
    --repo=*) REPO=${a#--repo=} ;;
    --profile=*) PROFILE=${a#--profile=} ;;
    *) echo "usage: sync.sh [--no-pull] [--repo=DIR] [--profile=full|minimal]" >&2; exit 2 ;;
  esac
done
PROFILE=${PROFILE:-$(cat "$PROFILE_FILE" 2>/dev/null || echo full)}
[[ $PROFILE == full || $PROFILE == minimal ]] || { echo "profile must be full or minimal, not '$PROFILE'" >&2; exit 1; }
# copies of what was installed last time, to tell your edits from ours
STATE="$HOME/.local/state/hopparch/installed"
# files in ~/.config that are yours to edit: the repo only seeds them
USER_FILES="hopparch/lock-text hopparch/game-faces"

notes=()
note() { echo "$*"; notes+=("$*"); }

cd "$REPO"
if ((PULL)); then
  before=$(git rev-parse HEAD)
  if ! git pull -q --ff-only 2>/dev/null; then
    note "could not pull $REPO (offline, or local commits not on GitHub): synced the local copy"
  fi
  after=$(git rev-parse HEAD)
  # packages and system files can't be done without root: say so, don't try
  if [[ $before != "$after" ]] && ! git diff --quiet "$before" "$after" -- system setup.sh; then
    note "hopparch changed outside ~/.config: run  cd $REPO; and sudo ./setup.sh"
  fi
fi

tree=$(mktemp -d)
trap 'rm -rf "$tree"' EXIT
cp -a config/. "$tree"/
if [[ -d profiles/$PROFILE/config ]]; then cp -a "profiles/$PROFILE/config/." "$tree"/; fi

changed=()
while IFS= read -r -d '' src; do
  rel=${src#"$tree"/}
  dst="$HOME/.config/$rel"
  mkdir -p "$(dirname "$dst")" "$(dirname "$STATE/$rel")"
  # yours once it exists: written only when missing, never updated or removed
  if [[ " $USER_FILES " == *" $rel "* ]]; then
    [[ -e $dst ]] || install -m 644 "$src" "$dst"
    rm -f "$STATE/$rel"
    continue
  fi
  # already up to date: don't touch it (apps watching it would reload)
  if ! cmp -s "$src" "$dst" 2>/dev/null; then
    # differs from what we installed last time = your edit, keep a copy
    if [[ -f $dst ]] && ! cmp -s "$dst" "$STATE/$rel" 2>/dev/null; then
      bak="$dst.bak-$(date +%F-%H%M%S)"
      cp -p "$dst" "$bak"
      note "kept your edit as $bak: move it into the repo"
    fi
    mode=644
    [[ -x $src ]] && mode=755
    # write next to it, then rename over it: the file is never missing, even
    # for a split second (Hyprland reloads the moment its config changes)
    install -m "$mode" "$src" "$dst.hopparch-new"
    mv -f "$dst.hopparch-new" "$dst"
    changed+=("$rel")
  fi
  # remember what we installed, to recognise your edits next time
  install -m 644 "$src" "$STATE/$rel"
done < <(find "$tree" -type f -print0)
echo "$PROFILE" > "$PROFILE_FILE"

# files installed earlier that are gone from the repo: remove them too,
# unless you edited them -- no leftovers piling up in ~/.config
if [[ -d $STATE ]]; then
  while IFS= read -r -d '' old; do
    rel=${old#"$STATE"/}
    [[ -e $tree/$rel ]] && continue
    dst="$HOME/.config/$rel"
    if [[ ! -e $dst ]] || cmp -s "$old" "$dst"; then
      rm -f "$dst"
      echo "removed (no longer in hopparch): $dst"
    else
      note "no longer in hopparch, kept because you edited it: $dst"
    fi
    rm -f "$old"
  done < <(find "$STATE" -type f -print0)
fi

# the timer that runs this, on for good (a wants link, like systemctl enable)
wants="$HOME/.config/systemd/user/timers.target.wants"
mkdir -p "$wants"
ln -sfn ../hopparch-sync.timer "$wants/hopparch-sync.timer"

((${#changed[@]})) && printf 'updated: %s\n' "${changed[@]}"

# Hyprland watches only hyprland.lua, not the files it loads (profile.lua...)
if printf '%s\n' "${changed[@]}" | grep -q '^hypr/'; then
  sig=${HYPRLAND_INSTANCE_SIGNATURE:-}
  # a systemd service may carry a stale signature: take the running instance
  if [[ -z $sig || ! -d ${XDG_RUNTIME_DIR:-/run/user/$UID}/hypr/$sig ]]; then
    sig=$(ls -t "${XDG_RUNTIME_DIR:-/run/user/$UID}/hypr" 2>/dev/null | head -1)
  fi
  [[ -n $sig ]] && HYPRLAND_INSTANCE_SIGNATURE=$sig hyprctl reload >/dev/null 2>&1 || true
fi

if ((${#notes[@]})) && command -v notify-send >/dev/null && [[ -n ${DBUS_SESSION_BUS_ADDRESS:-} ]]; then
  notify-send "hopparch sync" "$(printf '%s\n' "${notes[@]}")" || true
fi
exit 0
