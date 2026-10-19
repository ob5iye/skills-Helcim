#!/bin/bash
# psso-setpass.sh — set an Okta user's PSSO handover password (native-sheet-safe: must-change OFF).
#
# The native PSSO sheet rejects expired/temporary passwords, so the handover
# password must come from THIS call every time. See 04-SOP step 2 / error #3.
#
# v2 (2026-10-19): after setting, VERIFIES by actually authenticating the user
# via /authn. If the account carries a leftover PASSWORD_EXPIRED state (observed
# on mquick — a fresh POST set can report status lagging), it clears it through
# the authn change_password dance. The password this script prints is the proven-
# working one at exit.
#
# Usage:
#   psso-setpass.sh <login@helcim.com> [Password]   set password (generates a
#                                                   policy-compliant one if omitted)
#   psso-setpass.sh --set-token                     one-time: store the org SSWS
#                                                   token in macOS Keychain
#
# Token is stored/read from Keychain service "okta-psso-onboarding".
# If the token is later network-zone restricted, run this from an allowed zone.

set -uo pipefail
KEYCHAIN_SERVICE="okta-psso-onboarding"
ORG="https://helcim.okta.com"

jget() { grep -o "\"$2\":\"[^\"]*\"" <<< "$1" | head -1 | cut -d'"' -f4 || true; }

genpass() {
  python3 - "$1" <<'PY'
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
}

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
[[ -z "$pass" ]] && pass=$(genpass "$user")
case "$pass" in *\"*|*\\*) echo "password cannot contain quotes or backslashes"; exit 1;; esac

# 1. Admin-set the password (must-change never set by this endpoint)
resp=$(curl -sS -X POST "$ORG/api/v1/users/$user" \
  -H "Authorization: SSWS $token" -H "Content-Type: application/json" \
  -d "$(printf '{"credentials":{"password":{"value":"%s"}}}' "$pass")")

if [[ "$resp" == *'"errorCode"'* ]]; then
  echo "FAILED:"; echo "$resp" | head -c 400; echo
  exit 1
fi

# 2. Prove the password works — primary-auth as the user
authn=$(curl -sS -X POST "$ORG/api/v1/authn" -H 'Content-Type: application/json' \
  -d "{\"username\":\"$user\",\"password\":\"$pass\"}")
st=$(jget "$authn" status)

if [[ "$st" == "SUCCESS" ]]; then
  ts=$(jget "$resp" passwordChanged)
  echo "OK: password set for $user (passwordChanged=$ts) — verified by live authn"
  echo "handover password: $pass"
  exit 0
fi

# 3. Stale expired state: clear it via the authn change_password flow
if [[ "$st" == "PASSWORD_EXPIRED" ]]; then
  echo "note: account had PASSWORD_EXPIRED — clearing it" >&2
  stateToken=$(jget "$authn" stateToken)
  final=$(genpass "$user")
  chg=$(curl -sS -X POST "$ORG/api/v1/authn/credentials/change_password" \
    -H 'Content-Type: application/json' \
    -d "{\"stateToken\":\"$stateToken\",\"oldPassword\":\"$pass\",\"newPassword\":\"$final\"}")
  if [[ "$(jget "$chg" status)" == "SUCCESS" ]]; then
    echo "OK: password set for $user (expired state cleared) — verified by live authn"
    echo "handover password: $final"
    exit 0
  fi
  echo "FAILED clearing expired state:"; echo "$chg" | head -c 400; echo
  exit 1
fi

echo "FAILED: unexpected authn status '$st'"; echo "$authn" | head -c 400; echo
exit 1
