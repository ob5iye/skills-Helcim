# Okta Platform SSO (Desktop Password Sync) — Full Deployment Procedure

**Org:** helcim.okta.com · **MDM:** Jamf Pro (Jamf MDM Server) · **macOS 26** · **Okta Verify 9.65**
Follow top to bottom. Exact names/values below — don't substitute.

---

## KEY LESSON (why this was hard)
The System-keychain authorization during registration needs a **local admin**.
- **Post-login registration** works because a local admin already exists. ← proven working
- **Zero-touch at Setup Assistant** stalled because the first user was being created as **Standard** (no admin) → nothing could authorize the keychain. **Fix = create the first user as Administrator** (Part 2, step B7). This is the change to make zero-touch work from a wipe.

---

## ⭐ NEW USER / NEW DEVICE SOP (VERY IMPORTANT — required for EVERY new user; learned 2026-08-25)

Adding a device to Jamf is NOT enough. A new user gets **"Unable to log in"** on the Mac unless BOTH the Okta user side and the Jamf device side are done. System Log signature when the app assignment is missed:
`Desktop Password Sync Enrollment → FAILURE: User is not assigned to Platform Single Sign-On for macOS App`

**User side (Okta):**
1. **Assign the user to the app** — Applications → **"Platform Single Sign-On for macOS"** (`0oa1w2y9e0jWfdw701d8`) → **Assignments** → Assign to People (or add the user to the assigned group). ← **THE most-missed step**
2. User is **Active** with an admin-set **temp password** ("must change on first login" **OFF**). **No YubiKey/MFA pre-enrollment needed** — the PSSO-Pilot enrollment policy requires Password only (Passkey demoted to Optional 2026-08-25); **FastPass is created automatically during enrollment.**
3. User is in the **`PSSO-Pilot` group** (applies the password-only enrollment policy).
4. Set **Secondary email** (personal) at creation — company email is Okta-protected, so resets self-serve to the secondary.

**Device side (Jamf):**
3. Add the device to the **SSO-Sandboxing** static computer group → it receives the **PSSO-Extension** profile (SCEP + SSOe + Associated Domains + System Extensions + custom settings). Confirm on the computer record → Configuration Profiles = **Installed** (not Pending).
4. **Zero-touch only:** ABM → device assigned to **Jamf MDM Server**; **PSSO-Sandbox PreStage → Scope** → serial shows **Assigned** (Part 3). PreStage Setup Assistant: **Touch ID pane NOT skipped** — that pane is the forced fingerprint step.
5. **After ANY wipe/re-enroll:** the Mac comes back as a **NEW computer record — static group membership does NOT carry over.** Re-add it to **SSO-Sandboxing** and delete the stale old record. Symptom if missed: Okta sign-in works at Setup Assistant (PreStage pushes the profile during ADE) but **no Platform SSO registration afterward** — the profile is removed/never installed when scope syncs post-enrollment. (Hit 2026-08-26 on `H6VPXKDQ5C`.)

**First troubleshooting move for any login failure:** Okta → Reports → **System Log** → search the user's email → read `outcome.reason` on the failed event BEFORE touching the device.

### Enrollment security model (verified 2026-08-25/26 — policy audit + Ana Gibson registration)

**FastPass creation is FORCED at enrollment:** Simplified Setup makes PSSO registration mandatory (the account is created through it), and registration **auto-enrolls FastPass with biometric user verification** — Touch ID setup is unavoidable. New users sign in exactly ONCE with the temp password (FastPass can't verify a user it doesn't exist for yet); from then on the Mac unlocks with Touch ID and app sign-ons use FastPass.

PSSO sign-in is evaluated by **three layers** — all verified password-compatible for a 1-factor new user:
1. **Global Session Policy (Default)** — MFA Not Required.
2. **"Platform Single Sign-On for macOS" app sign-in policy** (app-specific, bound 1:1 to the app) — catch-all = password-only.
3. **Okta Account Management Policy** — catch-all = **progressive authentication**: 1-factor users verify with 1 factor. Users with 2+ factors enrolled get asked for 2 — that's why Ana saw a YubiKey prompt; it was not a failure and requires no fix.

**Existing users** who already have FastPass can register a new/wiped Mac by choosing **"Use Okta FastPass"** on the PSSO sign-in page — no password needed (verified visible in Ana's registration 2026-08-25). **macOS 27** will add QR-code auth at the PSSO window (fully passwordless first enrollment) — not available on macOS 26.

---

## PART 0 — One-time org prerequisites (verify once)
1. **Okta app:** "Platform Single Sign-On for macOS" exists, **Client ID `0oa1w2y9e0jWfdw701d8`**, assigned to the test user/group.
2. **Test user:** `sdoe@helcim.com` — **Active**, has an **Okta password** (admin-set, "must change" OFF), and a factor (YubiKey) enrolled.
3. **Okta Verify package:** the **MDM build `OktaVerify-9.65.x.pkg`** uploaded to Jamf: Settings → Computer Management → **Packages** → New → upload.
4. **AASA check (once):** browser → `https://helcim.okta.com/.well-known/apple-app-site-association` returns JSON listing `B7F62B65BN.com.okta.mobile` under `authsrv`. ✅ (already confirmed)

---

## PART 1 — Config profiles (Computers → Configuration Profiles)

### Profile A — `PSSO-Device Access` (SCEP), Level = Computer
1. General → Name `PSSO-Device Access`, Level **Computer Level**.
2. Add **SCEP** payload:
   - URL = your Okta **SCEP URL** (Security → Device Integrations → **Device Access** → Dynamic SCEP URL – Generic)
   - Name = `Okta Device Access CA`
   - Redistribute Profile = **30 days**
   - Subject = `CN=$COMPUTERNAME ODA $UDID`
   - Challenge Type = **Dynamic-Microsoft CA** · Challenge URL / Username / Password from Okta
   - Key Size **2048** · **Use as digital signature** ✓ · **Allow export from keychain** ✗
   - CERTIFICATE / Fingerprint: leave **blank** (nothing to upload)
3. Scope → **loaner static group**. Save.

### Profile B — `PSSO-Extension`, Level = Computer
Add **Single Sign-On Extensions** payload:
1. Payload Type = **SSO**
2. Extension Identifier = `com.okta.mobile.auth-service-extension`
3. Team Identifier = `B7F62B65BN`
4. Sign-on Type = **Redirect**
5. URLs (Add both):
   - `https://helcim.okta.com/device-access/api/v1/nonce`
   - `https://helcim.okta.com/oauth2/v1/token`
6. **Use Platform SSO** = Include **ON** · Authentication Method = **Password**
7. **Use Shared Device Keys** = Include ON → **Enable**  *(required — else "UseSharedDeviceKeys must be 'true'")*
8. **Enable registration during setup** = **Enable**
9. **Create first user during Setup** = **Enable**
10. **New User Account Type** = Include ON → **Administrator**  ← THE zero-touch keychain fix
11. **Account Authorization Type** = **Administrator**
12. **Device identifiers in attestation** = Include ON → **Allow**  *(Okta needs UDID/serial to register the device)*
13. **Quick login for temporary session** = **Disable**  *(don't wipe the home dir)*
14. **Registration Token** = leave blank · `$USERNAME` mapping = **do NOT set** (leave User Mapping off or omit UserPrincipalName)

Add **Associated Domains** payload (same profile):
- App Identifier = `B7F62B65BN.com.okta.mobile`  *(Team ID prefix — must match the AASA)*
- Associated Domain = `authsrv:helcim.okta.com`  *(Enable Direct Downloads = OFF)*

Add **Application & Custom Settings** payload — two preference domains:
- `com.okta.mobile` → upload `okta-psso-okta-mobile.plist`
- `com.okta.mobile.auth-service-extension` → upload `okta-psso-auth-service-extension.plist`
- *(Both plists are in the OKTA folder; Client ID filled; `UserPrincipalName`/`$USERNAME` removed.)*

Scope → **loaner static group**. Save.

### Profile C — `Okta System Extensions`, Level = Computer
1. Add **System Extensions** payload → System extension types = **Allowed team identifiers** → Team Identifier = `B7F62B65BN` (one entry only).
2. Scope → loaner static group. Save.

---

## PART 2 — PreStage `PSSO-Sandbox` (Computers → PreStage Enrollments)
1. **General:** Name `PSSO-Sandbox`; ADE instance = **Jamf MDM Server**; **auto-assign new devices OFF**; Prevent Activation Lock ON; Make MDM Mandatory ON; Allow MDM Removal OFF; Require Authentication OFF.
2. **Setup Assistant section:** **Enable Simplified Setup for Platform Single Sign-on** ✓ → workflow **Attended** → **Select configuration profile = PSSO-Extension**.
3. **Configuration Profiles:** attach **PSSO-Device Access + PSSO-Extension + Okta System Extensions**.
4. **Enrollment Packages:** add **Okta Verify 9.65** → **Distribution Point = Cloud Distribution Point (Jamf Cloud)**.
5. **Scope:** add the loaner serial.

---

## PART 3 — Route the device to this PreStage
1. **ABM** → the device → **Assign Device Management → Jamf MDM Server** (loaners often land on Kandji).
2. Jamf → Settings → **Device Enrollments → Jamf MDM Server → Refresh** (sync).
3. Default PreStage (`Jamf Pro Enrollment`) → turn **auto-assign new devices OFF** (so it doesn't re-grab the loaner).
4. **PSSO-Sandbox → Scope** → add the serial → wait until status reads **"Assigned"** (not "Pending Sync").

---

## PART 4 — Wipe + zero-touch test
1. Erase the Mac: hold power → **Options** (Recovery) → Disk Utility erase → Reinstall macOS.
2. Setup Assistant → **Remote Management** appears → **Okta sign-in**.
3. Sign in as **`sdoe@helcim.com`** → password → tap **YubiKey**.
4. With **New User Account Type = Administrator**, the first user is created as admin → it authorizes the System keychain → **"Single Sign-On for Mac — Registration Complete"** → password synced. ✅

**If it still shows the keychain admin prompt / stalls at Setup Assistant → use Part 5 (proven working).**

---

## PART 5 — Fallback: post-login registration (PROVEN working)
Use this if zero-touch stalls, or as the primary rollout model.
1. Temporarily set PreStage **Enable Simplified Setup OFF** (and/or PSSO-Extension → "Enable registration during setup" + "Create first user during Setup" = Disable), so Setup Assistant does a **normal** account.
2. Wipe → normal Setup Assistant → create a **local Administrator** account (e.g. `test`).
3. Re-scope **PSSO-Extension** (+ SCEP) to the device if removed → on the Mac run `sudo jamf manage` → confirm in System Settings → **VPN & Device Management** the profiles installed.
4. Open **Okta Verify** → it prompts to register Platform SSO.
5. **Keychain prompt** ("Okta Verify wants to use the System keychain") → enter the **LOCAL admin** account name + password (e.g. `test`) — **not** the Okta login. Click **Allow**.
6. **Okta sign-in webview** → enter **`sdoe@helcim.com`** + password + **YubiKey**.
7. **"Registration Complete"** + "password has been synchronized." ✅
   - Result: the local account (`test`) is now **linked to the Okta identity** (Sue Doe); its password syncs with Okta.

---

## PART 6 — Verify
1. On the Mac: `app-sso platform -s` → returns a **config** (device registered), not `null`.
2. Change **Sue Doe's Okta password** → lock/log out → log in with the **new** password → it works = **sync confirmed end-to-end**.
3. Watch during any attempt: `log stream --predicate 'subsystem == "com.apple.AppSSO"' --info`.

---

## Status (2026-07-13)
- ✅ **PSSO password sync WORKS** on the loaner via **Part 5 (post-login)** — device registered, `userConfiguration updated`, password synced.
- ⏳ **Zero-touch (Part 4)** — retry with **New User Account Type = Administrator** (Part 1 B10). If the keychain prompt still appears at first-boot Setup Assistant, open a **Jamf + Okta support ticket** (first-boot System-keychain authorization for Simplified Setup).
