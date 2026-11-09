#!/bin/bash
# The destructive branches: ESP mount failure, vault copies, Wi-Fi delete, brightness 0.
# No root, no real NetworkManager, no real backlight.
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
fail() { printf 'FAIL %s\n' "$*" >&2; exit 1; }

fns=$tmp/install-fns.sh
sed '/^preflight$/,$d' "$root/install.sh" > "$fns"

if ( source "$fns"
     lsblk() { echo vfat; }
     mount() { return 1; }
     ESP=/dev/sda1
     classify_esp
   ) >"$tmp/esp-fail.out" 2>&1
then
  fail "a FAT ESP that will not mount was not refused"
fi
grep -q 'nothing was changed' "$tmp/esp-fail.out" || fail "mount failure did not say it would not format"

( source "$fns"
  lsblk() { echo vfat; }
  mount() { echo boot > "$4/EFI"; }
  umount() { rm -f "$1"/*; }
  ESP=/dev/sda1
  classify_esp
  [[ $ESP_STATUS == existing ]]
) || fail "a FAT ESP with files was not kept"

( source "$fns"
  lsblk() { echo btrfs; }
  mount() { echo mounted >"$tmp/mounted"; }
  # shellcheck disable=SC2034 # read by classify_esp
  ESP=/dev/sda1
  classify_esp
  [[ $ESP_STATUS == modify && ! -e $tmp/mounted ]]
) || fail "a non-FAT ESP was mounted"

unshare --user --map-root-user --mount bash -s "$root" "$tmp" << 'EOF'
set -euo pipefail
root=$1
tmp=$2
differ=$tmp/differ
src=$tmp/differ-src
mkdir -p "$differ/.config/gh" "$differ/.claude" "$differ/.steam" "$differ/Vault" "$src/gh"
echo only-home > "$differ/.config/gh/hosts.yml"
echo only-vault > "$src/gh/hosts.yml"
mount --bind "$src" "$differ/Vault"
set +e
HOME=$differ bash "$root/config/scripts/migrate-vault.sh" >"$tmp/differ.out" 2>"$tmp/differ.err"
st=$?
set -e
[[ $st == 1 ]] || { echo "differ exited $st"; exit 1; }
[[ $(cat "$differ/.config/gh/hosts.yml") == only-home ]]
[[ $(cat "$src/gh/hosts.yml") == only-vault ]]
grep -q 'both copies differ' "$tmp/differ.err"

miss=$tmp/miss
msrc=$tmp/miss-src
mkdir -p "$miss/.claude" "$miss/.steam" "$miss/Vault" "$msrc/gh"
echo secret > "$msrc/gh/hosts.yml"
mount --bind "$msrc" "$miss/Vault"
HOME=$miss bash "$root/config/scripts/migrate-vault.sh" >"$tmp/miss.out"
[[ -L $miss/.config/gh/hosts.yml ]]
[[ $(readlink "$miss/.config/gh/hosts.yml") == "$miss/Vault/gh/hosts.yml" ]]
[[ $(cat "$miss/.config/gh/hosts.yml") == secret ]]
EOF

mkdir -p "$tmp/bin" "$tmp/home"
cat > "$tmp/bin/notify-send" << 'SH'
#!/bin/bash
printf '%s\n' "$*" >> "${NOTELOG:?}"
SH
cat > "$tmp/bin/fuzzel" << 'SH'
#!/bin/bash
cat >/dev/null
n=$(cat "${FUZ_COUNT:?}")
echo $((n + 1)) > "$FUZ_COUNT"
if [[ $n == 0 ]]; then printf '%s\n' "${FUZ_CHOICE:?}"
else printf '%s\n' secret
fi
SH
cat > "$tmp/bin/nmcli" << 'SH'
#!/bin/bash
printf '%s\n' "$*" >> "${NMLOG:?}"
case "$*" in
  "radio wifi") echo enabled ;;
  "-t --escape no -f IN-USE,SIGNAL,SECURITY,SSID device wifi list --rescan auto")
    printf '%s\n' " :80:${WIFI_SEC:?}:Cafe" ;;
  "-t -f NAME connection show")
    [[ ${WIFI_EXIST:-0} == 1 ]] && echo Cafe ;;
  "-t --escape no -f SECURITY,SSID device wifi list --rescan no")
    printf '%s\n' "${WIFI_SEC:?}:Cafe" ;;
  "device wifi connect Cafe") exit 1 ;;
  connection\ add\ *) exit 0 ;;
  connection\ up\ *) exit 1 ;;
  connection\ delete\ *) exit 0 ;;
  *) echo "bad nmcli: $*" >> "$NMLOG"; exit 1 ;;
esac
SH
chmod +x "$tmp/bin/"*
run_wifi() {
  : > "$tmp/nm.log"
  : > "$tmp/notes"
  echo 0 > "$tmp/fuz.count"
  NOTELOG=$tmp/notes NMLOG=$tmp/nm.log FUZ_COUNT=$tmp/fuz.count \
    FUZ_CHOICE='   80%  lock  Cafe' WIFI_SEC=$1 WIFI_EXIST=$2 \
    PATH="$tmp/bin:$PATH" HOME=$tmp/home \
    bash "$root/config/scripts/settings.sh" wifi
}
run_wifi WPA2 1
grep -q 'connection delete' "$tmp/nm.log" && fail "a saved Wi-Fi profile was deleted"
grep -q 'connection add' "$tmp/nm.log" && fail "a saved Wi-Fi profile was created again"
run_wifi WPA3 0
grep -q 'wifi-sec.key-mgmt sae' "$tmp/nm.log" || fail "WPA3-only was not sae"
run_wifi "WPA2 802.1X" 0
grep -q 'connection add' "$tmp/nm.log" && fail "802.1X created a password profile"
grep -q 'needs a username' "$tmp/notes" || fail "802.1X did not say it needs a username"

unshare --user --map-root-user --mount bash -s "$root" "$tmp" << 'EOF'
set -euo pipefail
root=$1
tmp=$2
home=$tmp/bright
mkdir -p "$home/.config/scripts" "$tmp/bbin"
cp "$root/config/scripts/brightness.sh" "$root/config/scripts/settings.sh" "$home/.config/scripts/"
cat > "$tmp/bbin/notify-send" << 'SH'
#!/bin/bash
exit 0
SH
cat > "$tmp/bbin/fuzzel" << 'SH'
#!/bin/bash
cat >> "${FUZLOG:?}"
SH
chmod +x "$tmp/bbin/"*
mount -t tmpfs t /sys/class/backlight
one() {
  rm -rf /sys/class/backlight/*
  mkdir -p "/sys/class/backlight/$1"
  echo "$2" > "/sys/class/backlight/$1/actual_brightness"
  : > "$tmp/fuz"
  PATH="$tmp/bbin:$PATH" HOME=$home FUZLOG=$tmp/fuz \
    bash "$home/.config/scripts/settings.sh" brightness
}
one amdgpu_bl0 0
grep -q '100%' "$tmp/fuz" || { echo 'working panel at 0 offered no levels'; exit 1; }
one nvidia_wmi_ec_backlight 0
grep -q 'not wired' "$tmp/fuz" || { echo 'EC device at 0 did not warn'; exit 1; }
if grep -q '100%' "$tmp/fuz"; then
  echo 'EC device at 0 still offered levels'
  exit 1
fi
EOF

# App volume: fake PipeWire. Two Firefox streams are one line and both get the
# level; another program's stream is left alone; nothing playing only says so.
vol=$tmp/vol
mkdir -p "$vol/bin"
cat > "$vol/bin/pw-dump" << 'SH'
#!/bin/bash
cat "${VOLDIR:?}/dump.json"
SH
cat > "$vol/bin/wpctl" << 'SH'
#!/bin/bash
[[ $1 == get-volume ]] && { echo 'Volume: 0.80'; exit 0; }
echo "$*" >> "${VOLDIR:?}/wpctl.log"
SH
cat > "$vol/bin/fuzzel" << 'SH'
#!/bin/bash
# one answer per list, from the front of the queue; an empty one is Escape
cat > /dev/null
a=$(sed -n 1p "${VOLDIR:?}/answers")
sed -i 1d "$VOLDIR/answers"
[[ -n $a ]] && echo "$a"
exit 0
SH
cat > "$vol/bin/notify-send" << 'SH'
#!/bin/bash
echo "$*" >> "${VOLDIR:?}/notes"
SH
chmod +x "$vol/bin/"*
volrun() { : > "$vol/wpctl.log"; : > "$vol/notes"; printf '%s\n' "$@" > "$vol/answers"; PATH="$vol/bin:$PATH" VOLDIR=$vol bash "$root/config/scripts/settings.sh" volume; }
cat > "$vol/dump.json" << 'JSON'
[{"id":1,"type":"PipeWire:Interface:Core"},
 {"id":10,"info":{"props":{"media.class":"Audio/Sink"}}},
 {"id":41,"info":{"props":{"media.class":"Stream/Output/Audio","application.name":"Firefox"}}},
 {"id":42,"info":{"props":{"media.class":"Stream/Output/Audio","application.name":"Firefox"}}},
 {"id":50,"info":{"props":{"media.class":"Stream/Output/Audio","application.name":"Some Game"}}},
 {"id":60,"info":{"props":{"media.class":"Stream/Input/Audio","application.name":"Firefox"}}}]
JSON
volrun 0 50% ''
grep -qx 'set-volume 41 50%' "$vol/wpctl.log" || fail "App volume missed a stream of the program"
grep -qx 'set-volume 42 50%' "$vol/wpctl.log" || fail "App volume missed the second stream"
grep -qE ' (50|60|10) ' "$vol/wpctl.log" && fail "App volume touched another stream"
volrun 1 30% ''
[[ $(grep set-volume "$vol/wpctl.log") == 'set-volume 50 30%' ]] || fail "App volume set the wrong program"
volrun 0 35 ''
grep -qx 'set-volume 42 35%' "$vol/wpctl.log" || fail "App volume ignored a typed level"
volrun 0 999 ''
grep -qx 'set-volume 41 150%' "$vol/wpctl.log" || fail "App volume went past 150%"
volrun 0 Mute ''
grep -qx 'set-mute 42 1' "$vol/wpctl.log" || fail "App volume did not mute every stream"
volrun 0 abc ''
[[ ! -s $vol/wpctl.log ]] || fail "App volume acted on text that is not a level"
grep -q "isn't a number" "$vol/notes" || fail "App volume took bad text in silence"
echo '[{"id":1,"type":"PipeWire:Interface:Core"}]' > "$vol/dump.json"
volrun
grep -q 'nothing is playing' "$vol/notes" || fail "App volume with no streams did not say so"
[[ ! -s $vol/wpctl.log ]] || fail "App volume with no streams changed something"

# ecoflow.sh: fake curl records its arguments and stdin and answers from a file.
# Keys must never reach a command line, the signature must match EcoFlow's.
eco=$tmp/eco
mkdir -p "$eco/bin"
cat > "$eco/bin/curl" << 'SH'
#!/bin/bash
printf '%s\n' "$@" > "${ECOLOG:?}.argv"
cat > "$ECOLOG.stdin"
[[ -e $ECOLOG.down ]] && exit 7
cat "$ECOLOG.reply"
SH
chmod +x "$eco/bin/curl"
ecorun() { PATH="$eco/bin:$PATH" ECOLOG=$eco/log ECOFLOW_KEYS=$eco/keys bash "$root/config/scripts/ecoflow.sh" "$@"; }

rm -f "$eco/keys"
[[ -z $(ecorun) ]] || fail "ecoflow: no keys file still printed something"
[[ ! -e $eco/log.argv ]] || fail "ecoflow: no keys file still called curl"

printf 'access=AK1\nsecret=bad secret\nsn=SN1\n' > "$eco/keys"
ecorun | grep -q 'malformed' || fail "ecoflow: a malformed secret was not refused"
[[ ! -e $eco/log.argv ]] || fail "ecoflow: a malformed key file still called curl"

printf 'access=AKtest123\nsecret=SKsecret456\nsn=R6SNtest789\n' > "$eco/keys"
cat > "$eco/log.reply" << 'JSON'
{"code":"0","message":"Success","data":{"cmsBattSoc":87.4,"powInSumW":0,"powOutSumW":45.6,"cmsDsgRemTime":372,"cmsChgRemTime":5999}}
JSON
out=$(ecorun)
[[ $(jq -r .text <<<"$out") == "EF 87%" ]] || fail "ecoflow: wrong text: $out"
[[ $(jq -r .tooltip <<<"$out") == "In 0 W  ·  Out 46 W  ·  6h 12m left" ]] || fail "ecoflow: wrong tooltip: $out"
for s in AKtest123 SKsecret456 R6SNtest789; do
  grep -q "$s" "$eco/log.argv" && fail "ecoflow: $s is on curl's command line"
done
grep -q SKsecret456 "$eco/log.stdin" && fail "ecoflow: the secret was sent to curl"
grep -q 'url = "https://api-e.ecoflow.com/iot-open/sign/device/quota/all?sn=R6SNtest789"' "$eco/log.stdin" ||
  fail "ecoflow: wrong URL"
hdr() { sed -n "s/^header = \"$1: \(.*\)\"$/\1/p" "$eco/log.stdin"; }
want=$(printf 'sn=R6SNtest789&accessKey=AKtest123&nonce=%s&timestamp=%s' "$(hdr nonce)" "$(hdr timestamp)" |
  openssl dgst -sha256 -hmac SKsecret456 -r | cut -d' ' -f1)
[[ $(hdr sign) == "$want" ]] || fail "ecoflow: signature does not match EcoFlow's scheme"

echo '{"code":"0","data":{"cmsBattSoc":15,"powInSumW":300,"powOutSumW":20,"cmsChgRemTime":95}}' > "$eco/log.reply"
out=$(ecorun)
[[ $(jq -r .class <<<"$out") == charging && $(jq -r .tooltip <<<"$out") == *"full in 1h 35m"* ]] ||
  fail "ecoflow: charging not shown: $out"
echo '{"code":"0","data":{"cmsBattSoc":15,"powInSumW":0,"powOutSumW":20}}' > "$eco/log.reply"
[[ $(ecorun | jq -r .class) == low ]] || fail "ecoflow: 15% discharging is not low"

echo '{"code":"8521","message":"signature is wrong"}' > "$eco/log.reply"
ecorun | grep -q 'signature is wrong' || fail "ecoflow: an API error was not shown"
echo '{"code":"0","data":{"someOtherName":1}}' > "$eco/log.reply"
[[ -z $(ecorun) ]] || fail "ecoflow: unknown field names still printed something"
[[ $(ecorun fields) == someOtherName ]] || fail "ecoflow: fields did not list the names"
echo 'not json' > "$eco/log.reply"
ecorun | grep -q unreadable || fail "ecoflow: a broken reply was not caught"
touch "$eco/log.down"
ecorun | grep -q 'did not answer' || fail "ecoflow: no internet was not shown"

# a reinstall over a finished hopparch: its own boot files (linux-lts too) on the
# same root are an earlier attempt, cleaned and formatted, not "another Linux"
own_esp() {
  mkdir -p "$1/grub" "$1/EFI/GRUB"
  touch "$1"/{vmlinuz-linux,vmlinuz-linux-lts,initramfs-linux.img,initramfs-linux-lts.img,amd-ucode.img} "$1/EFI/GRUB/grubx64.efi"
  echo "search --fs-uuid abcd-1234" > "$1/grub/grub.cfg"
}
( source "$fns"
  lsblk() { case "$*" in *UUID*) echo abcd-1234 ;; *) echo vfat ;; esac; }
  mount() { own_esp "$4"; }
  umount() { rm -rf "${1:?}"/*; }
  ESP=/dev/sda1 ROOT=/dev/sda2
  classify_esp
  [[ $ESP_STATUS == modify && " ${ESP_CLEAN[*]} " == *" vmlinuz-linux-lts "* ]]
) || fail "a reinstall over hopparch (with linux-lts) was not recognised"

if ( source "$fns"
     lsblk() { case "$*" in *UUID*) echo abcd-1234 ;; *) echo vfat ;; esac; }
     mount() { own_esp "$4"; touch "$4/vmlinuz-linux-zen"; }
     umount() { rm -rf "${1:?}"/*; }
     # shellcheck disable=SC2034 # read by classify_esp
     ESP=/dev/sda1 ROOT=/dev/sda2
     classify_esp
   ) >"$tmp/esp-other.out" 2>&1 </dev/null
then
  fail "an EFI partition with another Linux's kernel was not refused"
fi
grep -q "another Linux's boot files" "$tmp/esp-other.out" || fail "the foreign kernel was not named as the reason"

# settings: user.lua wins key by key; a typo, a bad colour or a number out of
# range is skipped with a warning and never stops the caller
set_dir=$tmp/settings
mkdir -p "$set_dir"
cp "$root/config/hopparch/settings.lua" "$root/config/hopparch/load.lua" "$set_dir/"
cat > "$set_dir/user.lua" << 'LUA'
return {
  gaps_in = 3,
  gaps_out = 999,
  border_sise = 5,
  palette = { bg = "2e3440", focus = "#88c0d0", texxt = "ffffff" },
  schemes = {},
}
LUA
cat > "$tmp/show-settings.lua" << 'LUA'
local d = arg[1] .. "/"
local S, w = dofile(d .. "load.lua")(d, d .. arg[2])
print(S.gaps_in[1], tostring(S.gaps_in.user), S.gaps_out[1], S.border_size[1], S.palette.bg[1], S.palette.focus[1], #w)
for _, x in ipairs(w) do io.stderr:write(x, "\n") end
LUA
settings() { luajit "$tmp/show-settings.lua" "$set_dir" "$1" 2>"$tmp/settings.err"; }
[[ $(settings user.lua) == $'3\ttrue\t8\t2\t2e3440\te8e4dc\t5' ]] || fail "settings: user.lua merged wrong: $(settings user.lua)"
for w in gaps_out border_sise palette.focus palette.texxt schemes; do
  grep -q "user.lua: $w: " "$tmp/settings.err" || fail "settings: no warning for $w"
done
echo 'return {' > "$set_dir/broken.lua"
[[ $(settings broken.lua) == $'4\tnil\t8\t2\t000000\te8e4dc\t1' ]] || fail "settings: a broken user.lua did not fall back to the defaults"
[[ $(settings missing.lua) == $'4\tnil\t8\t2\t000000\te8e4dc\t0' ]] || fail "settings: a missing user.lua is not plain defaults"

echo OK
