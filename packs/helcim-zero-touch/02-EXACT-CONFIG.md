# Exact Configuration Values — every screen, every field

## Okta — Platform SSO app
| Item | Value |
|---|---|
| App | "Platform Single Sign-On for macOS" (OIN catalog; requires Device Access license) |
| Client ID | `0oa1w2y9e0jWfdw701d8` |
| App sign-in policy | App-specific policy "Platform Single Sign-On for macOS" (bound 1:1), catch-all = Allowed with password, re-auth every 12h |
| Assignment | Group `PSSO-Pilot` (pilot) → widen at production |
| Profile Editor attributes | `macOSAccountFullName`, `macOSAccountUsername` mapped from Okta profile |

## SSO extension / URLs
- Extension identifier: `com.okta.mobile.auth-service-extension`
- Okta Verify Team ID: `B7F62B65BN`
- Sign-on Type: **Redirect** · URLs: `https://helcim.okta.com/device-access/api/v1/nonce` + `https://helcim.okta.com/oauth2/v1/token`
- Associated Domain: `authsrv:helcim.okta.com`, App Identifier **team-prefixed** `B7F62B65BN.com.okta.mobile` (plain `com.okta.mobile` fails domain validation), Direct Downloads OFF
- AASA verified: `https://helcim.okta.com/.well-known/apple-app-site-association` lists `B7F62B65BN.com.okta.mobile` under `authsrv`
- Protocol: `PlatformSSO.ProtocolVersion = 2.0`

## Jamf — PSSO-Extension profile (consolidated, Computer Level, Install Automatically)
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

**Scope: static computer group `SSO-Sandboxing`** (wipe/re-enroll = re-add new record!)

## Jamf — SCEP (PSSO-Device Access)
- CA type Manual · URL = Okta Device Access dynamic SCEP URL · Name "Okta Device Access CA"
- Redistribute profile 30 days (Okta CA can't auto-renew)
- Subject `CN=$COMPUTERNAME ODA $UDID` (Jamf appends `$PROFILE_IDENTIFIER`)
- Challenge Type **Dynamic-Microsoft CA**; Challenge URL `https://helcim.okta.com/api/v1/certificateAuthorities/CD4EB6420AB5D4A86B04C3DAC378F3D4276E3819/registrationAuthorities/rac37834dmgUFKlD81d8/challenge` · username `okta-SMFSWE`
- Key 2048 · Use as digital signature ✓ · Allow export ✗ · nothing to upload

## Jamf — PreStage "PSSO-Sandbox"
- General: ADE = Jamf MDM Server · auto-assign OFF · MDM mandatory ON · Allow removal OFF · Require Auth OFF · min macOS 26
- Setup Assistant: **Enable Simplified Setup for Platform SSO ✓** · workflow Attended · SSOe profile = PSSO-Extension · **Touch ID pane NOT skipped** (the forced-fingerprint step)
- Configuration Profiles attached: SCEP + PSSO-Extension + System Extensions
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

## Username stamping (Jamf policy, All Computers, Login + Recurring Check-in, Ongoing)
```bash
#!/bin/bash
u=$(scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ && ! /loginwindow/ { print $3 }')
if [[ -z "$u" || "$u" == "root" || "$u" == "_mbsetupuser" ]]; then
  echo "No real user logged in — skipping, retry next check-in"; exit 0
fi
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
