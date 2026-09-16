# Okta Platform SSO on macOS via Jamf — FULL HANDOFF (2026-07-13)

**Read this whole file first.** It is self-contained: the goal, environment, exact config, everything we learned, what works, and exactly where we stopped. Written for another assistant to continue with no prior context.

---

## 1. GOAL
Stand up **Okta Platform SSO / Desktop Password Sync** on macOS (Jamf-managed) so that:
- A Mac's **local login password syncs with the user's Okta password** (change Okta pw → Mac pw follows).
- Ideally **zero-touch**: wipe → at Setup Assistant the user signs in with Okta → their local account is **created from their Okta identity** + password sync on ("Simplified Setup").

## 2. CURRENT STATUS (where we stopped)
- ✅ **PROVEN WORKING via the post-login path** — on the loaner we created a normal local admin, opened Okta Verify, registered, and got **"Registration Complete" + "password has been synchronized with your identity provider."** `app-sso platform -s` returned a real config; log showed `registrationDidCompleteWithCompletion … error=(null)` and `userConfiguration updated`.
- ⏳ **Zero-touch (Simplified Setup at Setup Assistant) — IN TEST.** We applied the final fix (**New User Account Type → Administrator**) and re-wiped. **We stopped at the Setup Assistant prompt** — need to confirm whether the account-being-created (now Admin) can authorize the **System keychain** step that previously walled us. See §7 for the exact open question.

## 3. ENVIRONMENT / EXACT VALUES
| Item | Value |
|---|---|
| Okta org | `https://helcim.okta.com` |
| MDM | Jamf Pro (cloud), instance name **"Jamf MDM Server"**, **11.29.1** |
| Second MDM | Kandji (66 devices) — loaners sometimes land here in ABM; must be Jamf |
| macOS | 26 (Tahoe) |
| Okta Verify | **9.65.2** (MDM build) |
| Loaner (test device) | MacBook Pro 14" M5 Pro, **serial C7RQFYWHYG** |
| Test user | **Sue Doe `sdoe@helcim.com`** — Active, has Okta **password** (admin-set, must-change off) + **YubiKey** (FIDO2). Assigned the app below. |
| Okta app | **"Platform Single Sign-On for macOS"**, **Client ID `0oa1w2y9e0jWfdw701d8`** |
| SSO extension bundle id | `com.okta.mobile.auth-service-extension` |
| Okta Verify Team ID | `B7F62B65BN` |
| Redirect URLs | `https://helcim.okta.com/device-access/api/v1/nonce` and `https://helcim.okta.com/oauth2/v1/token` |
| Associated domain | `authsrv:helcim.okta.com` · **App Identifier `B7F62B65BN.com.okta.mobile`** (team-prefixed) |
| AASA (verified served) | `https://helcim.okta.com/.well-known/apple-app-site-association` → lists `B7F62B65BN.com.okta.mobile` under `authsrv` ✅ |
| Custom-settings domains | `com.okta.mobile` and `com.okta.mobile.auth-service-extension` (ProtocolVersion `2.0`) |
| Local admin used in post-login test | `test` |

## 4. THE CORRECT CONFIG (Jamf)

### Profile A — `PSSO-Device Access` (SCEP), Computer level
- **SCEP payload:** CA type Manual · URL = Okta Device Access dynamic SCEP URL · Name `Okta Device Access CA` · **Redistribute 30 Days** · Subject `CN=$COMPUTERNAME ODA $UDID` (Jamf appends `$PROFILE_IDENTIFIER` automatically when redistribute is on) · **Challenge Type Dynamic-Microsoft CA** · Challenge URL `https://helcim.okta.com/api/v1/certificateAuthorities/CD4EB6420AB5D4A86B04C3DAC378F3D4276E3819/registrationAuthorities/rac37834dmgUFKlD81d8/challenge` · Username `okta-SMFSWE` · Key Size **2048** · **Use as digital signature ✓** · **Allow export ✗** · Fingerprint blank · no cert upload.

### Profile B — `PSSO-Extension`, Computer level (THE important one)
**Single Sign-On Extensions payload:**
- Payload Type **SSO** · Extension Id `com.okta.mobile.auth-service-extension` · Team `B7F62B65BN`
- **Sign-on Type = Redirect** (password sync uses Redirect; Credential+Realm is the *device-trust* extension — wrong here)
- URLs: the two above
- **Use Platform SSO = ON** · Auth Method **Password**
- **Use Shared Device Keys = Enable** (required, else "UseSharedDeviceKeys must be 'true'")
- **Enable registration during setup = Enable**
- **Create first user during Setup = Enable**
- **New User Account Type = Administrator** ← key fix (first user must be admin to authorize keychain)
- **Account Authorization Type = Administrator**
- **User Mapping** → Full Name `macOSAccountFullName`, Account Name `macOSAccountUsername` (**turn the Include toggle ON** so it applies)
- **Device identifiers in attestation = Allow** (Okta needs UDID/serial to register the device)
- **Quick login for temporary session = Disable** (don't wipe the home dir)
- Registration Token blank · login/screensaver/FileVault conditions = Attempt (non-blocking)

**Associated Domains payload:** App Identifier `B7F62B65BN.com.okta.mobile` · Associated Domain `authsrv:helcim.okta.com` · Enable Direct Downloads OFF.

**Application & Custom Settings payload — two preference domains:**
- `com.okta.mobile` → plist `okta-psso-okta-mobile.plist`
- `com.okta.mobile.auth-service-extension` → plist `okta-psso-auth-service-extension.plist`

### Profile C — `Okta System Extensions`, Computer level
- **System Extensions payload:** Allowed Team Identifiers = `B7F62B65BN` (so the extension auto-approves).

Scope all three to the loaner static group.

### The two plists (both in OKTA folder; `$USERNAME`/UserPrincipalName REMOVED)
`okta-psso-auth-service-extension.plist`:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>OktaVerify.OrgUrl</key><string>https://helcim.okta.com</string>
  <key>OktaVerify.PasswordSyncClientID</key><string>0oa1w2y9e0jWfdw701d8</string>
  <key>PlatformSSO.ProtocolVersion</key><string>2.0</string>
</dict></plist>
```
`okta-psso-okta-mobile.plist`: same but WITHOUT the ProtocolVersion key.

### PreStage `PSSO-Sandbox`
- General: ADE instance **Jamf MDM Server** · **auto-assign new devices OFF** · MDM mandatory ON · Allow removal OFF · Require Auth OFF · min macOS 26
- Setup Assistant: **Enable Simplified Setup for Platform SSO ✓** · workflow **Attended** · **Select configuration profile = PSSO-Extension**
- Configuration Profiles: attach **PSSO-Device Access + PSSO-Extension + Okta System Extensions**
- **Enrollment Packages: `OktaVerify-9.65.2.pkg`** (classic package) with **Distribution Point = Cloud Distribution Point (Jamf Cloud)** — the Jamf **App Installer** version installs post-login, TOO LATE for Setup Assistant
- Scope: loaner serial

### Routing the device (must all be true before wiping)
1. **ABM** → device → **Assign Device Management → Jamf MDM Server** (was on Kandji)
2. Jamf → Settings → **Device Enrollments → Jamf MDM Server → Refresh**
3. **Default PreStage ("Jamf Pro Enrollment") → auto-assign new devices OFF** (else it re-grabs the loaner)
4. **PSSO-Sandbox → Scope** → add serial → wait until it reads **"Assigned"** (not "Pending Sync")

## 5. EVERYTHING WE LEARNED (chronological gotchas + fixes)
1. **SCEP** is configured in the Jamf **SCEP payload**, not Certificate/Upload — nothing to upload; the device fetches the cert from the SCEP URL. SCEP cert issued fine (CN `…ODA <UDID>`, Active/Issued).
2. Okta **Device Access tab** = Desktop MFA/PSSO SCEP; **Certificate authority tab** = separate. Endpoint management iOS/Android is unrelated.
3. **Okta PSSO has NO native Jamf "Platform SSO" section for Okta** beyond the SSO Extensions payload — the Okta-specific keys go in the two Custom Settings plists.
4. **Credential vs Redirect: for password sync it's `Redirect` + the nonce/token URLs + "Use Platform SSO" ON.** Credential+Realm `Okta Device` was the device-trust extension (wrong).
5. **The SSO extension only loads when Okta Verify is actually LAUNCHED** — a pushed-but-never-opened Okta Verify = extension MISSING = `app-sso platform -s` returns `null` / `-1000 "no extension"`. The PSSO extension is an *app* extension; it does NOT appear in `systemextensionsctl list`.
6. **ABM assignment must be Jamf** — the loaner was assigned to **Kandji**; that's why wipes went to a plain "create user" (no Okta). Reassigned to Jamf.
7. **Default PreStage auto-assign re-grabs the device** — had to turn its auto-assign OFF, then explicitly scope the serial to PSSO-Sandbox.
8. **Okta Verify must be a classic Enrollment Package w/ Cloud Distribution Point** (App Installer is too late for Setup Assistant).
9. **"UseSharedDeviceKeys must be 'true'"** error → set **Use Shared Device Keys = Enable** (the Include toggle on the right must be ON, not just the Enable button).
10. **"could not validate the domain"** → the **AASA is correct/served**; fix was the **Associated Domains App Identifier must be team-prefixed `B7F62B65BN.com.okta.mobile`** (not just `com.okta.mobile`), plain domain, Direct Downloads OFF.
11. **`$USERNAME` in the plists doesn't resolve at Setup Assistant** → removed `OktaVerify.UserPrincipalName`.
12. **Network is NOT the problem** — `curl -vI https://helcim.okta.com/device-access/api/v1/nonce` returns a genuine **DigiCert** cert (not Netskope) and HTTP 405 (reachable). No SSL interception, no block.
13. **"Registration failed" with ZERO Okta System Log events** = the request wasn't completing to Okta; root cause was the **System-keychain authorization** step.
14. **The keychain step needs a LOCAL admin.** Post-login it works (a local admin `test` exists to authorize). At first-boot Setup Assistant the first user was being created as **Standard** → no admin → keychain auth failed. **Fix = New User Account Type → Administrator** (+ Account Authorization Type → Administrator) so the first user is created as admin.
15. **Post-login registration WORKS end to end** (device registered, password synced). The account linked was `test` ↔ Sue Doe's Okta identity (in the post-login path PSSO links the *existing* local account to the Okta identity; it does not rename it to `sdoe`).
16. Two macOS prompts look alike: (A) the **Okta web sign-in** wants the **Okta login `sdoe@helcim.com`**; (B) the **"wants to use the System keychain — administrator name/password"** dialog wants a **LOCAL admin** credential (e.g. `test`), not the Okta login.
17. **New user "Unable to log in" = app assignment missing** (2026-08-25, Ana Gibson / `H6VPXKDQ5C`): authentication fully succeeds (password + YubiKey, OIDC tokens granted, device added to user) but System Log shows `Desktop Password Sync Enrollment → FAILURE: User is not assigned to Platform Single Sign-On for macOS App`. Fix = assign the user to the PSSO app. **The required new-user/new-device SOP is now the top section of `PSSO-Deployment-Procedure.md` — very important, do not skip.**
18. **Wipe/re-enroll = new Jamf record; static groups don't carry over** (2026-08-26, `H6VPXKDQ5C`): after wiping Anna's laptop, Okta sign-in + account creation worked at Setup Assistant (PreStage attaches the profile during ADE), but no Platform SSO registration afterward — the new record wasn't in SSO-Sandboxing, so the group-scoped PSSO-Extension profile was missing post-enrollment. Fix: re-add new record to the static group, delete stale record, `sudo jamf manage`, launch Okta Verify → register. Now in the SOP device-side checklist (item 5).
19. **Three-layer policy model + forced FastPass (verified 2026-08-25/26):** PSSO registration is evaluated by (1) Global Session Policy Default (MFA Not Required), (2) the PSSO app's **own app-specific sign-in policy** (catch-all password-only, bound 1:1), (3) **Okta Account Management Policy** (catch-all = progressive auth: users with 2+ enrolled factors must verify with 2 — hence Ana's YubiKey prompt; password-only users pass with password alone). Final new-user flow: admin-set temp password (must-change OFF) → Setup Assistant → Touch ID forced → **FastPass auto-created at registration, mandatory, no opt-out** → passwordless from then on. PSSO-Pilot enrollment policy = Password only (YubiKey no longer forced). Existing FastPass users register new/wiped Macs with FastPass instead of a password. Ana's post-login registration completed successfully with System Settings showing Registered + SSO tokens present + password synced.

## 6. TWO DEPLOYMENT MODELS
- **Post-login (PROVEN, shippable today):** enroll Mac (normal admin account) → open Okta Verify → register (keychain prompt = local admin; then Okta sign-in `sdoe@helcim.com` + password + YubiKey) → password sync on. Works on new AND existing Macs.
- **Zero-touch (Simplified Setup, IN TEST):** wipe → Setup Assistant → Okta sign-in creates the account from Okta. Was blocked at the keychain step; **New User Account Type → Administrator** is the fix under test.

## 7. ▶ EXACT OPEN QUESTION / NEXT STEP (where we stopped)
We re-wiped with **all fixes applied incl. New User Account Type → Administrator**. At Setup Assistant a prompt appeared ("Okta Verify … username and password"). **Determine which prompt and act:**
- If it's the **Okta web sign-in** (`helcim.okta.com`, "Sign In"): enter **`sdoe@helcim.com`** + Okta password + **YubiKey**.
- If it's the **"Okta Verify wants to use the System keychain — enter an administrator's name and password"** dialog: enter **User Name `sdoe`** (the account being created, per User Mapping) + **Sue Doe's Okta password** → Allow. (If rejected, try `sdoe@helcim.com` + Okta password.)

**Expected if the Admin fix worked:** the account is created as admin, authorizes the keychain, and shows **"Single Sign-On for Mac — Registration Complete"** + password synchronized = **zero-touch works from a wipe.**

**If it STILL rejects/walls at the keychain step:** the first-boot System-keychain authorization can't be satisfied at Setup Assistant → **use the post-login model (proven)** and open a **Jamf + Okta support ticket** (see §8).

## 8. SUPPORT TICKET SUMMARY (if zero-touch still fails)
> macOS 26 Simplified Setup + Okta Device Access (Desktop Password Sync), Jamf 11.29, Okta Verify 9.65.
> **Works:** AASA correct & served (lists `B7F62B65BN.com.okta.mobile`/authsrv); user `sdoe@helcim.com` signs into Okta fine; device-access endpoint reachable with genuine DigiCert cert (no interception); **post-login PSSO registration completes and password syncs**; Simplified Setup triggers at Setup Assistant and passes `UseSharedDeviceKeys` + domain validation.
> **Fails:** at Setup Assistant the registration stops at the **System-keychain authorization** — a "Okta Verify wants to use the System keychain / enter administrator" prompt that no credential satisfies because no local admin exists yet at first boot. Even with **New User Account Type = Administrator**, [state result]. Registration produces **zero Okta System Log events** at that moment.
> **Ask:** how should the first-boot System-keychain authorization be satisfied for Okta Simplified Setup account creation (bootstrap token / SecureToken / expected behavior)?

## 9. VERIFY (once registered, either path)
- `app-sso platform -s` → returns a config (not `null`).
- Change **Sue Doe's Okta password** → lock/log out → log in with the **new** password → works = sync confirmed.
- Live diagnostics during any attempt: `log stream --predicate 'subsystem == "com.apple.AppSSO"' --info`.

## 10. FILES IN THE OKTA FOLDER
- `Helcim-Okta-Working-Notes-2026-07-05.md` — broader lifecycle runbook (§9 resume point)
- `PSSO-Deployment-Procedure.md` — step-by-step build procedure
- `okta-psso-auth-service-extension.plist`, `okta-psso-okta-mobile.plist` — the two Custom Settings plists (Client ID filled, `$USERNAME` removed)
- `Okta-PlatformSSO-Jamf-Checklist.md` — earlier checklist
