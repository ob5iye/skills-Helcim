#!/bin/bash
# psso-setpass.sh — set an Okta user's PSSO handover password (native-sheet-safe: must-change OFF).
#
# The native PSSO sheet rejects expired/temporary passwords, so the handover
# password must come from THIS call every time. See 04-SOP step 2 / error #3.
#
# Usage:
#   psso-setpass.sh <login@helcim.com> [Password]   set password (generates a
#                                                   policy-compliant one if omitted)
#   psso-setpass.sh --set-token                     one-time: store the org SSWS
#                                                   token in macOS Keychain
#
# Token is stored/read from Keychain service "okta-psso-onboarding".
# If the token is later network-zone restricted, run this from an allowed zone.

set -euo pipefail
KEYCHAIN_SERVICE="okta-psso-onboarding"
ORG="https://helcim.okta.com"

if [[ "${1:-}" == "--set-token" ]]; then
  read -rsp "Paste Okta SSWS token (hidden): " t; echo
  security add-generic-password -U -a okta -s "$KEYCHAIN_SERVICE" -w "$t"
  echo "Token stored in Keychain as '$KEYCHAIN_SERVICE'."
  exit 0
fi

user="${1:-}"
[[ -z "$user" ]] && { echo "usage: $0 <login@helcim.com> [password] | --set-token"; exit 1; }

if ! token=$(security find-generic-password -s "$KEYCHAIN_SERVICE" -w 2>/dev/null); then
  echo "No token in Keychain — run once: $0 --set-token"; exit 1
fi

pass="${2:-}"
if [[ -z "$pass" ]]; then
  pass=$(python3 - "$user" <<'PY'
import secrets, string, sys
local = sys.argv[1].split('@')[0].lower()
alpha = string.ascii_letters + string.digits + "*!@#%+-"
while True:
    p = ''.join(secrets.choice(alpha) for _ in range(14))
    # Helcim policy: upper+lower+number, 12+ chars, no username substring
    if (any(c.isupper() for c in p) and any(c.islower() for c in p)
            and any(c.isdigit() for c in p) and local not in p.lower()):
        print(p); break
PY
)
  echo "generated password: $pass"
fi

case "$pass" in *\"*|*\\*) echo "password cannot contain quotes or backslashes"; exit 1;; esac

payload=$(printf '{"credentials":{"password":{"value":"%s"}}}' "$pass")
resp=$(curl -sS -X POST "$ORG/api/v1/users/$user" \
  -H "Authorization: SSWS $token" -H "Content-Type: application/json" -d "$payload")

if [[ "$resp" == *'"status":"ACTIVE"'* ]]; then
  ts=$(echo "$resp" | grep -o '"passwordChanged":"[^"]*"' | cut -d'"' -f4)
  echo "OK: password set for $user (passwordChanged=$ts)"
else
  echo "FAILED:"; echo "$resp" | head -c 400; echo
  exit 1
fi
