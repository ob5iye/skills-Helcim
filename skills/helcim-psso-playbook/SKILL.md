---
name: helcim-psso-playbook
description: Helcim's Okta Platform SSO / Desktop Password Sync deployment on macOS via Jamf Pro — exact config values, the zero-touch (ABM/ADE/PreStage) chain, and troubleshooting. Use for any Helcim PSSO, Okta Device Access, SCEP, Jamf PreStage/Simplified Setup, or Okta Verify extension work. Companion to the OKTA project folder runbook + PSSOFULLHANDOFF.md.
---

# Helcim Okta Platform SSO (Desktop Password Sync) on macOS via Jamf — Playbook

Deploy Okta Platform SSO password sync so Macs log in with Okta and the local password syncs with Okta. Tested on loaner **C7RQFYWHYG** with test user **Sue Doe `sdoe@helcim.com`** (YubiKey).

**Current resume point (updated 2026-07-13 — see `PSSOFULLHANDOFF.md` §7):**
- ✅ **Post-login path PROVEN WORKING** — local *admin* account → open Okta Verify → Register → "Registration Complete" + password synchronized. Shippable today on new and existing Macs.
- ⏳ **Zero-touch (Simplified Setup) IN TEST** — applied the key fix **New User Account Type → Administrator** and re-wiped; stopped **at the Setup Assistant prompt**, need to confirm the now-admin first user can authorize the **System keychain** step. Next action: identify which prompt is showing and clear it (§7); if it still walls at the keychain, fall back to the post-login model and open a Jamf + Okta ticket.

## Environment ground rules
- **`help.okta.com` and `learn.jamf.com` are network-blocked** on Helcim's network. Use web-search summaries + third-party writeups (IAMSE, Kandji, Addigy), NOT the official docs directly.
- Jamf Pro (cloud, "Jamf MDM Server", 11.29+), macOS 26 fleet, Okta Verify 9.65, YubiKeys (FIDO2). Two MDMs: Jamf + Kandji — **default ABM Mac assignment must be Jamf**.
- Abdi wants concise, step-by-step guidance; works hands-on per screen.

## Exact values
| Item | Value |
|---|---|
| SSO extension identifier | `com.okta.mobile.auth-service-extension` |
| Okta Verify Team ID | `B7F62B65BN` |
| Okta org | `https://helcim.okta.com` |
| PSSO Sign-on Type | **Redirect** (password sync). Credential+Realm = device-trust ext (different) |
| PSSO Redirect URLs | `https://helcim.okta.com/device-access/api/v1/nonce` + `https://helcim.okta.com/oauth2/v1/token` |
| Associated domain | `authsrv:helcim.okta.com` — **App Identifier `B7F62B65BN.com.okta.mobile` (team-prefixed, NOT plain `com.okta.mobile`)** |
| Password-sync Client ID | `0oa1w2y9e0jWfdw701d8` (from "Platform Single Sign-On for macOS" Okta app) |
| Custom-settings domains | `com.okta.mobile` + `com.okta.mobile.auth-service-extension` (ProtocolVersion `2.0`) |
| Min macOS / Okta Verify | 26 / 9.52+ |

## The two Jamf config profiles
**SCEP profile:** Jamf **SCEP payload** (NOT Certificate/Upload — SCEP uploads nothing). CA type Manual; URL + Challenge URL + username/password from Okta → Device Access dynamic SCEP; challenge **Dynamic – Microsoft CA**; Subject `CN=$COMPUTERNAME ODA $UDID`; key 2048; Use as digital signature ON; Allow export OFF; Redistribute 30 days (Okta CA can't renew).

**PSSO-Extension profile** (Single Sign-On Extensions payload):
- Type **Redirect**, ext id + team id above, the two **URLs**, **Use Platform SSO = ON**, Auth Method **Password**.
- **Use Shared Device Keys = Enable** (REQUIRED for Simplified Setup — macOS rejects the profile otherwise: "UseSharedDeviceKeys must be 'true'"). The **Include** toggle on the right must also be ON, not just the Enable button.
- Enable registration during setup = ON, Create first user during Setup = ON.
- **New User Account Type = Administrator** + **Account Authorization Type = Administrator** ← key zero-touch fix: the first user must be admin to authorize the System keychain at Setup Assistant (a Standard first user has no admin → keychain auth fails).
- **User Mapping** (AccountName `macOSAccountUsername`, FullName `macOSAccountFullName`) — turn the **Include** toggle ON so it applies.
- **Device identifiers in attestation = Allow** (Okta needs UDID/serial to register the device).
- **Quick login for temporary session = Disable** (don't wipe the home dir).
- **Associated Domains** payload: App Identifier **`B7F62B65BN.com.okta.mobile`** (team-prefixed), domain `authsrv:helcim.okta.com`, Enable Direct Downloads OFF.
- **Application & Custom Settings**: two preference domains via the plists in the OKTA folder (`$USERNAME` / `OktaVerify.UserPrincipalName` REMOVED — doesn't resolve at Setup Assistant).
- Separate **System Extensions allowlist** profile: Allowed Team ID `B7F62B65BN` (so the extension auto-approves).

## Zero-touch chain (order matters)
1. **ABM:** device must be assigned to **Jamf MDM Server** (loaners often land on Kandji). ABM → device → Assign Device Management → Jamf. Then Jamf → Settings → Device Enrollments → Jamf MDM Server → Refresh.
2. **PreStage assignment:** Jamf's **default PreStage auto-assign re-grabs devices** — turn the default's "auto-assign new devices" OFF, release the device, then assign the serial to **PSSO-Sandbox**. Wait until status = **Assigned** (not "Pending Sync") before wiping.
3. **PSSO-Sandbox PreStage:** Simplified Setup ON, workflow **Attended**, SSOe profile = PSSO-Extension; attach SCEP + PSSO-Extension + System Extensions; **Okta Verify as a classic Enrollment Package with Distribution Point = Cloud Distribution Point (Jamf Cloud)** — the App Installer version is too late for Setup Assistant.
4. **Wipe** → Remote Management → Okta sign-in → user + YubiKey → account created (as **admin**) + password synced.

## Troubleshooting (what we hit)
- **Wiped/re-enrolled Mac: Okta sign-in + account creation works at Setup Assistant but NO Platform SSO registration afterward** ("Platform Single Sign-on" missing from the user pane / profile not installed) — hit 2026-08-26, `H6VPXKDQ5C` → a wipe creates a NEW Jamf computer record; **static group membership (SSO-Sandboxing) does not carry over**, so the group-scoped PSSO-Extension profile never installs post-enrollment (PreStage attachment only covers Setup Assistant). Fix: re-add the new record to SSO-Sandboxing (delete the stale record), `sudo jamf manage`, launch Okta Verify → register.
- **Policy stack for password-only new-user enrollment (audited 2026-08-25/26):** PSSO sign-in is evaluated by three layers, all verified password-compatible for a 1-factor new user — (1) Global Session Policy Default = MFA Not Required; (2) "Platform Single Sign-On for macOS" **app-specific** sign-in policy (bound 1:1) catch-all = password-only; (3) Okta Account Management Policy catch-all = **progressive authentication** (1-factor users verify with 1 factor — a YubiKey prompt for users with 2 factors enrolled is EXPECTED, not a failure). Enrollment policy (PSSO-Pilot): Password required only, Passkey demoted to Optional (2026-08-25). **FastPass creation is FORCED at enrollment** — registration is mandatory in Simplified Setup and auto-enrolls FastPass with biometrics (Touch ID unavoidable). New user = one-time temp password (must-change OFF); existing FastPass users register new/wiped Macs via "Use Okta FastPass" (no password). macOS 27 adds QR-code auth at the PSSO window.
- **"Unable to log in" for a NEW user + System Log `Desktop Password Sync Enrollment → FAILURE: User is not assigned to Platform Single Sign-On for macOS App`** (hit 2026-08-25, Ana Gibson / H6VPXKDQ5C) → user isn't assigned to the PSSO app. Auth itself succeeds (password + YubiKey, OIDC tokens granted) — only the PSSO enrollment step fails. Fix: Applications → "Platform Single Sign-On for macOS" (`0oa1w2y9e0jWfdw701d8`) → Assignments → assign user/group. **New-user SOP:** (1) Okta app assignment, (2) user Active + password must-change OFF + MFA factor enrolled, (3) device in Jamf **SSO-Sandboxing** group with profiles **Installed**, (4) zero-touch: ABM→Jamf + PSSO-Sandbox PreStage = Assigned. Always check Reports → System Log for the user first — it names the exact reason.
- **`app-sso platform -s` = null / `-1000 "no extension"`** → Okta Verify's SSO extension isn't loaded. The extension only installs when **Okta Verify is launched** (a pushed-but-never-opened app = missing extension). Fix: launch/reinstall Okta Verify, allow the extension, reboot. Note: the PSSO/SSO extension is an *app* extension — it may not appear in `systemextensionsctl list`; trust `app-sso platform -s` + the `com.apple.AppSSO` log.
- **"could not validate the domain"** → the AASA is served correctly (lists `B7F62B65BN.com.okta.mobile` under `authsrv`); the fix is the **Associated Domains App Identifier must be team-prefixed `B7F62B65BN.com.okta.mobile`** (not plain `com.okta.mobile`), plain domain, Direct Downloads OFF.
- **Registration walls at Setup Assistant on a "wants to use the System keychain — enter administrator" prompt + ZERO Okta System Log events** → the first user was created as Standard, so no local admin exists yet to authorize the keychain. Fix: **New User Account Type = Administrator**. (Post-login this already works because a local admin exists.)
- **Two look-alike prompts:** (A) the **Okta web sign-in** (`helcim.okta.com`) wants the Okta login `sdoe@helcim.com` + password + YubiKey; (B) the **System keychain "administrator name/password"** dialog wants a **local admin** credential (the account being created, per User Mapping).
- **Config won't update on device** → force re-push: exclude from scope → sync → re-target → sync (App Installer status can be stale).
- **Setup Assistant shows plain "create user", no Okta** → device is on the wrong PreStage (default, not PSSO-Sandbox) or not Jamf-assigned in ABM, or Okta Verify wasn't a classic enrollment pkg with a distribution point.
- **"UseSharedDeviceKeys must be 'true'"** → set Use Shared Device Keys = Enable in PSSO-Extension.
- Validation errors name the exact field ("X must be…") — fix what's named, retry.

## Interim validation if zero-touch stalls
Create a local **admin** account → log in → complete the Platform SSO **Register** prompt (works once the extension loads) → password sync. Escalate Simplified-Setup-at-Setup-Assistant to a **Jamf support ticket** (live ADE/enrollment logs).
