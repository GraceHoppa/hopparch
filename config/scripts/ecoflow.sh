#!/bin/bash
# EcoFlow power station on the top bar, from EcoFlow's developer API (cloud).
#   ecoflow.sh          waybar JSON: "EF 87%", tooltip with watts and time left
#   ecoflow.sh fields   the quota names this device reports (no values), to
#                       check a model that shows nothing
# Read only: this script never sends a command to the device.
#
# Keys live in the vault, ~/Vault/ecoflow/keys (chmod 600), one per line:
#   access=<access key>
#   secret=<secret key>
#   sn=<device serial>
#   host=api-e.ecoflow.com      (optional; api.ecoflow.com outside Europe)
# The file is parsed, never sourced. Vault locked or no file = nothing printed,
# and waybar hides the module.
# The secret is never on a command line (ps shows those): it reaches the HMAC
# through the environment, and curl reads the headers and URL from stdin.
# ECOFLOW_KEYS is only for tests.
set -euo pipefail

keys=${ECOFLOW_KEYS:-$HOME/Vault/ecoflow/keys}
[[ -r $keys ]] || exit 0

access="" secret="" sn="" host=api-e.ecoflow.com
while IFS='=' read -r k v; do
  case $k in
    access) access=$v ;; secret) secret=$v ;; sn) sn=$v ;; host) host=$v ;;
  esac
done < "$keys"
# plain characters only: these go into a curl config and a URL
ok='^[A-Za-z0-9_-]+$'
[[ $access =~ $ok && $secret =~ $ok && $sn =~ $ok && $host =~ ^[a-z0-9.-]+\.ecoflow\.com$ ]] || {
  echo '{"text": "EF ?", "tooltip": "~/Vault/ecoflow/keys: a field is missing or malformed"}'
  exit 0
}

# EcoFlow's signature: the query sorted by name, then accessKey, nonce and
# timestamp, HMAC-SHA256 with the secret key, hex.
nonce=$(( RANDOM % 900000 + 100000 ))
ts=$(date +%s%3N)
query="sn=$sn"
sign=$(printf '%s&accessKey=%s&nonce=%s&timestamp=%s' "$query" "$access" "$nonce" "$ts" |
  EF_SECRET=$secret python3 -I -c 'import hashlib, hmac, os, sys
print(hmac.new(os.environ["EF_SECRET"].encode(), sys.stdin.buffer.read(), hashlib.sha256).hexdigest())')

reply=$(printf 'url = "https://%s/iot-open/sign/device/quota/all?%s"\nheader = "accessKey: %s"\nheader = "nonce: %s"\nheader = "timestamp: %s"\nheader = "sign: %s"\n' \
  "$host" "$query" "$access" "$nonce" "$ts" "$sign" |
  curl -sS --max-time 10 --proto =https -K - 2>/dev/null) || {
  echo '{"text": "EF ?", "tooltip": "EcoFlow cloud did not answer (no internet?)"}'
  exit 0
}

if [[ ${1:-} == fields ]]; then
  jq -r '.data // {} | keys[]' <<<"$reply"
  exit 0
fi

# Recent stations' names (cms = the whole station, bms = one pack).
# A model that uses other names prints nothing; "ecoflow.sh fields" lists its own.
jq -c '
  def num(a; b): (.[a] // .[b] // null);
  def hm(m): if m == null or m <= 0 or m >= 5999 then null
             else "\(m / 60 | floor)h \(m % 60)m" end;
  if (.code | tostring) != "0" then
    {text: "EF ?", tooltip: ("EcoFlow: " + (.message // "error" | tostring))}
  else .data as $d
    | ($d | num("cmsBattSoc"; "bmsBattSoc")) as $soc
    | if $soc == null then empty else
      ($d | num("powInSumW"; "inputWatts") // 0 | round) as $in
      | ($d | num("powOutSumW"; "outputWatts") // 0 | round) as $out
      | (if $in > $out then hm($d.cmsChgRemTime) | if . then "full in " + . else null end
         else hm($d.cmsDsgRemTime) | if . then . + " left" else null end end) as $t
      | {text: "EF \($soc | round)%",
         tooltip: ([ "In \($in) W", "Out \($out) W", $t ] | map(select(.)) | join("  ·  ")),
         class: (if $in > $out then "charging" elif $soc <= 20 then "low" else "discharging" end)}
    end
  end' <<<"$reply" 2>/dev/null || echo '{"text": "EF ?", "tooltip": "EcoFlow: unreadable reply"}'
