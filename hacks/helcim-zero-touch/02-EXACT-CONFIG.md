# Exact Configuration Values — every screen, every field

## Okta — Platform SSO app
| Item | Value |
|---|---|
| App | "Platform Single Sign-On for macOS" (OIN catalog; requires Device Access license) |
| Client ID | `0oa1w2y9e0jWfdw701d8` |
| App sign-in policy | App-specific policy "Platform Single Sign-On for macOS" (bound 1:1), catch-all = Allowed with password, re-auth every 12h |
| Assignment | Group `PSSO-Pilot` (assigned 2026-10-20 via API — build-time truth had been individual assigns of sdoe+agibson only; the "group-driven" assumption was false for 3 months) → widen at production. Same-day: group also assigned to **Netskope Client Enrollment - SAML Forward Proxy** (`0oa234kg25yTGkxyN1d8`) |
| Profile Editor attributes | `macOSAccountFullName`, `macOSAccountUsername` mapped from Okta profile |

## SSO extension / URLs
- Extension identifier: `com.okta.mobile.auth-service-extension`
- Okta Verify Team ID: `B7F62B65BN`
- Sign-on Type: **Redirect** · URLs: `https://helcim.okta.com/device-access/api/v1/nonce` + `https://helcim.okta.com/oauth2/v1/token`
- Associated Domain: `authsrv:helcim.okta.com`, App Identifier **team-prefixed** `B7F62B65BN.com.okta.mobile` (plain `com.okta.mobile` fails domain validation), Direct Downloads OFF
- AASA verified: `https://helcim.okta.com/.well-known/apple-app-site-association` lists `B7F62B65BN.com.okta.mobile` under `authsrv`
- Protocol: `PlatformSSO.ProtocolVersion = 2.0`

## Jamf — the THREE-profile layering (FINAL — proven end-to-end 2026-10-21, Marcelo Ramos / L9MF750DC9, zero manual steps)
| Profile | ID | Payloads | Notes |
|---|---|---|---|
| **PSSO-Extension** | 45 | SSOe + Associated Domains + 2 Custom Settings — **nothing else** | Apple's Simplified Setup validator rejects a SysExt payload here (#34). No `$USERNAME` key. |
| **PSSO-Device Access** | 44 | SCEP only | **Allow all apps access = ON, Allow export = OFF** — without all-apps access Okta Verify can't use the key → System-keychain admin prompt (#37) |
| **Okta System Extensions** | 46 | SysExt allowlist `B7F62B65BN` | Validator forbids it inside the SSOe-bound profile |

**Scope of all three = smart group `PSSO-Sandbox Enrolled` (id 58; criteria: Enrollment Method: PreStage enrollment **is** PSSO-Sandbox) + static `SSO-Sandboxing` (54, legacy).** The smart group is what makes zero-touch real: a freshly enrolled record is in scope from its first inventory, so Jamf never issues the "Remove Configuration Profile" commands it otherwise fires at enrollment for out-of-scope PreStage profiles (#38). No post-enrollment group add anymore.

All three attached to the PreStage, which runs **Device first**. In device-first all three install during enrollment, before the PSSO pane — the SCEP cert exists at registration (Friday's and Marcelo's Okta sequence: `pki.cert.issue` → `pki.cert.bind` → `platform_sso.keys.register` → `password_sync.authentication`).

Proven-good Okta log signature (Marcelo, 2026-10-21): 15:23:34 cert.issue → 15:25:10 enrollment.create + cert.bind + lifecycle.activate → 15:25:11 keys.register → 15:25:52 password_sync.authentication SUCCESS → 15:27:09 mfa.factor.activate (FastPass) + password_sync.enrollment.create. **3m35s, no prompts.**

## Jamf — PSSO-Extension profile (Computer Level, Install Automatically) — SSOe + Associated Domains + Custom Settings ONLY
Single Sign-On Extensions payload:
- Use Platform SSO = Include ON, Auth Method = **Password**
- Use Shared Device Keys = Enable + **Include toggle ON** (button alone isn't enough)
- Enable registration during setup = Enable
- Create first user during Setup = Enable
- **New User Account Type = Administrator** (+ Include ON) ← critical: first user must be admin to authorize the System keychain at Setup Assistant
- Account Authorization Type = Administrator
- User Mapping: AccountName `macOSAccountUsername`, FullName `macOSAccountFullName` (Include ON)
- Device identifiers in attestation = Allow (Include ON)
- Quick login for temporary session = Disable
- Registration Token: blank; login/screensaver/FileVault conditions: Attempt (non-blocking)

Application & Custom Settings (two domains; **NO `OktaVerify.UserPrincipalName`/$USERNAME — doesn't resolve at Setup Assistant**):
- `com.okta.mobile.auth-service-extension`: OrgUrl `https://helcim.okta.com`, `OktaVerify.PasswordSyncClientID = 0oa1w2y9e0jWfdw701d8`, `PlatformSSO.ProtocolVersion = 2.0`
- `com.okta.mobile`: OrgUrl + PasswordSyncClientID (no ProtocolVersion)

System Extensions allowlist (separate payload/profile): Allowed Team Identifier `B7F62B65BN`.

**Scope: smart group `PSSO-Sandbox Enrolled` (58) + static `SSO-Sandboxing` (54)** — see layering table; the old "re-add new record after every wipe" rule is retired.

## Jamf — SCEP (PSSO-Device Access, profile 44)
- CA type Manual · URL = `https://helcim.okta.com/pki/CD4EB6420AB5D4A86B04C3DAC378F3D4276E3819/scep/rac37834dmgUFKlD81d8` (pattern `/pki/<CA-id>/scep/<RA-id>`, same ids as the challenge URL) · Name "Okta Device Access CA" · Retries 3 / Retry Delay 10s (was 0/0; raised 2026-10-20 after `MDM-SCEP:15002` at enrollment) · Fingerprint blank, no uploaded cert
- Redistribute profile 30 days (Okta CA can't auto-renew)
- Subject `CN=$COMPUTERNAME ODA $UDID` (Jamf appends `$PROFILE_IDENTIFIER`)
- Challenge Type **Dynamic-Microsoft CA**; Challenge URL `https://helcim.okta.com/api/v1/certificateAuthorities/CD4EB6420AB5D4A86B04C3DAC378F3D4276E3819/registrationAuthorities/rac37834dmgUFKlD81d8/challenge` · username `okta-SMFSWE`
- Key 2048 · Use as digital signature ✓ · **Allow export from keychain ✗ · Allow all apps access ✓** (API: `KeyIsExtractable=false`, `AllowAllAppsAccess=true`) · nothing to upload
- Cert CN is filled from the Jamf record's name at profile-composition time (e.g. a re-enrolled Mac's cert may read `Setup_User-…` until the naming policy renames it) — cosmetic.

## Jamf — PreStage "PSSO-Sandbox" (id 2)
- General: ADE = Jamf MDM Server · auto-assign OFF · MDM mandatory ON · Allow removal OFF · Require Auth OFF · min macOS = **15.8.1** (set 2026-10-20: the dropdown offered no bare "26"; lowest Tahoe option 26.5.2 would exclude 26.5.1 test Macs. Raise to a 26.x once the fleet floor passes it — pending item)
- Setup Assistant: **Enable Simplified Setup for Platform SSO ✓** · workflow = **DEVICE FIRST** (Platform SSO app bundle ID **`com.okta.mobile`**; API: `platformSsoAppBundleId=com.okta.mobile`, `pssoConfigProfileId=-1`) · Enrollment Customization Config = None · **Touch ID pane NOT skipped** (the forced-fingerprint step)
  - **NEVER "Identity first."** Jamf's two workflows differ fundamentally: identity-first installs the SSOe profile *before* enrollment via a 403 handshake and requires Jamf Pro SAML SSO; with Okta it produced "Registration failed" on every device (#36) and `MDM-SCEP:15002` for any SCEP delivered that way. Device-first = Jamf holds the Mac in Setup Assistant until the PSSO app + attached profiles are installed, then registration, then account creation. (The July doc's "Attended" was device-first; 2026-10-20 it was mislabeled identity-first and cost a day.)
- Configuration Profiles attached: **PSSO-Extension (45) + PSSO-Device Access (44) + Okta System Extensions (46)** — API `prestageInstalledProfileIds: ['44','45','46']`, `installProfilesDuringSetup: true`
- Enrollment Packages: **OktaVerify-9.65.2.pkg classic package, Distribution Point = Cloud Distribution Point (Jamf Cloud)** — App Installer version lands too late for Setup Assistant

## ABM routing (before any wipe/ship)
1. ABM → device → Assign Device Management → **Jamf MDM Server** (loaners drift to Kandji)
2. Jamf → Settings → Device Enrollments → Jamf MDM Server → Refresh
3. Default PreStage ("Jamf Pro Enrollment") auto-assign = **OFF** (else it re-grabs the device)
4. PSSO-Sandbox → Scope → serial — wait for **"Assigned"** (not "Pending Sync")

## Okta LDAP server in Jamf ("Okta LDAP") — feeds inventory User & Location
- Host `helcim.ldap.okta.com:636` SSL · Auth Simple · Directory Service type **Custom**
- Bind DN `uid=jamf-ldap@helcim.com,dc=helcim,dc=okta,dc=com` (service account is a Read-only Administrator; member of group "LDAP Service Accounts"; password-only app-policy rule covers its ROPC bind)
- Users search base `ou=users,dc=helcim,dc=okta,dc=com`; groups `ou=groups,...`
- **Uncheck "Use Wildcards When Searching"** (Okta LDAP rejects wildcards)
- User mappings: Object Class `inetOrgPerson` · Username → `uid` (= full email, case-sensitive) · Real Name → `cn` · Email → `mail` (multi-valued risk — `uid` is the safe fallback) · UUID → `uniqueIdentifier` (immutable Okta 00u id, better than uid)
- Settings → Inventory Collection → "Collect user and location information from LDAP" = ON

## Jamf — Re-enrollment settings (Settings → Global → Re-enrollment) — REQUIRED for re-issued laptops
- **Clear policy logs on re-enrollment ✓** — Jamf reuses the computer record across a wipe (stable UDID); without this, "Once per computer" policies (stamp/naming, id 52) never run again on a re-enrolled Mac (#39).
- **Clear User and Location information on re-enrollment ✓** — previous owner's stamp must not survive into the new user's record.
- Legacy "Helcim Computer Naming Convention" policy (id 16) → **disabled**; naming lives in policy 52.

## Username stamping + computer naming (one merged Jamf policy id 52 "Stamp Username + LDAP Lookup", All Computers, Login + Recurring Check-in)
> 2026-10-16: merged the standalone naming policy into the stamp script (single guard, name set BEFORE recon so one inventory submits both; idempotent; DNS-safe). The old standalone naming policy is DISABLED. Name convention: `Full_Name-SERIAL-Chip_String` with the `Apple ` prefix stripped from chip (e.g. `Sue_Doe-C7RQFYWHYG-M5_Pro`); ComputerName keeps underscores, HostName/LocalHostName hyphenated + stripped. Enforcement: misnamed/user-renamed Macs snap back at next check-in.
```bash
#!/bin/bash

# --- Console user guard (shared by naming + stamping) ---
u=$(scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ && ! /loginwindow/ { print $3 }')
if [[ -z "$u" || "$u" == "root" || "$u" == "_mbsetupuser" ]]; then
  echo "No real user logged in — skipping, retry next check-in"; exit 0
fi

# --- Computer naming: FullName-Serial-Chip ---
serial=$(system_profiler SPHardwareDataType | awk '/Serial/ {print $4}')
fullName=$(dscl . -read "/Users/$u" RealName 2>/dev/null | tail -1 | sed -E 's/^RealName:[[:space:]]*//; s/^[[:space:]]+//')
case "$fullName" in "No such key"*) fullName="";; esac   # missing RealName key
[[ -z "$fullName" ]] && fullName="$u"          # fallback if RealName is blank
chipType=$(sysctl -n machdep.cpu.brand_string 2>/dev/null || uname -m)
chipType="${chipType#Apple }"   # "Apple M5 Pro" -> "M5 Pro" — Intel strings untouched

compName="$(echo "$fullName" | sed 's/ /_/g')-${serial}-$(echo "$chipType" | sed 's/ /_/g')"
netName=$(echo "$compName" | sed 's/_/-/g' | tr -cd 'A-Za-z0-9-')   # DNS-safe strip

if [[ "$(scutil --get ComputerName)" != "$compName" ]]; then
  /usr/sbin/scutil --set ComputerName  "$compName"
  /usr/sbin/scutil --set HostName      "$netName"
  /usr/sbin/scutil --set LocalHostName "$netName"
  echo "Renamed to $compName"
else
  echo "Name already correct: $compName"
fi

# --- Username stamp + inventory (carries the fresh name in the same recon) ---
/usr/local/bin/jamf recon -endUsername "${u}@helcim.com"
```

## Netskope values
- Tenant: `helcim.goskope.com` (addon host `addon-helcim.goskope.com` used by legacy mode)
- Team ID `24W52P9M7W` · ext `com.netskope.client.Netskope-Client.NetskopeClientMacAppProxy`
- Legacy profile payloads (SysExt pre-approval, PPPC SystemPolicyAllFiles, Per-App VPN App-Proxy, tenant Root+Intermediate CAs) — mode-agnostic, reused
- Encryption token: Settings → Security Cloud Platform → MDM Distribution → Secure Enrollment
- IdP-mode SAML: Okta OIN app "Netskope User Enrollment" (`exk234kg25xtJ8s0Q1d8`) ↔ Netskope Forward Proxy SAML account "Client Enrollment SAML - Okta" (Access Method = Client Enrollment, HTTP Post)

## Verification commands
- `app-sso platform -s` → config (registered) vs `null`/`-1000` (extension not loaded — launch Okta Verify)
- System Settings → Users & Groups → user → "Platform Single Sign-on: Registered ● / SSO tokens present ●" + "Your computer password is synced with your single sign-on password"
- `systemextensionsctl list` → Netskope `[activated enabled]`
- Live diagnostics: `log stream --predicate 'subsystem == "com.apple.AppSSO"' --info`
- Okta Reports → System Log → user email → failed event `outcome.reason`
