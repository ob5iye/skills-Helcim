# ⭐ SOP — New User / New-or-Wiped Device (THE standard procedure)

> Run top to bottom for every new hire and every laptop reissue. Born from the Ana Gibson incident (2026-08-25) and hardened through Mike Delamont prep + Sue Doe wipe tests. **Do not skip steps; every skip has caused a specific documented failure** (see 06-ERROR-CATALOG.md).

## A. Okta side (before touching the laptop ~10 min)

1. **User exists** — production users arrive via **HiBob push** (never Add Person). Test users: create manually.
2. **Set the handover password:**
   - New user created in Okta: Add Person → **Set password** → **uncheck "User must change password on first login"**
   - HiBob-provisioned or expired-mode user (the production case): **API set** — the UI has no no-expiry option for existing users; UI "Create a temporary password" = expired mode = the PSSO sheet rejects it. **Standard tool: `tools/psso-setpass.sh`** (2026-10-16) — token lives in macOS Keychain:
     ```bash
     # one-time per admin Mac:
     psso-setpass.sh --set-token              # paste token at hidden prompt -> Keychain
     # per user:
     psso-setpass.sh LOGIN@helcim.com         # generates + sets a compliant password and prints it
     psso-setpass.sh LOGIN@helcim.com "Hand-over1!"   # or set an explicit one
     ```
     Success = `OK: password set ... (passwordChanged=<today>)`. Fallback raw API set:
     ```bash
     read -s OKTA_TOKEN   # paste token once (Security → API → Tokens; store in 1Password)
     curl -X POST "https://helcim.okta.com/api/v1/users/LOGIN@helcim.com" \
       -H "Authorization: SSWS $OKTA_TOKEN" \
       -H "Content-Type: application/json" \
       -d '{"credentials":{"password":{"value":"<HandoverPassword>"}}}'
     ```
     Password policy (Helcim): 12+ chars, upper+lower+number, no username substring, not common. Success = JSON user object, status ACTIVE, fresh `passwordChanged` timestamp. Token errors → `E0000011` = deleted/expired OR zone-restricted from an out-of-zone IP (catalog #31).
   - **Reissuing a previously-used account** (wipe/reissue): first **More Actions → Reset Authenticators** → remove YubiKey + old Okta Verify/FastPass enrollments (stale FastPass causes the browser↔OV loop; 2+ factors trigger the progressive 2-factor challenge).
3. **PSSO-Pilot group** membership ✓ (carries the enrollment policy).
4. **App assignments** (group-driven): **"Platform Single Sign-On for macOS"** AND **"Netskope Client Enrollment - SAML Forward Proxy"** — assign group `PSSO-Pilot` to both apps once; then per-user = one group add.
5. **Secondary email** (personal) on the profile — company email is Okta-SSO-protected; resets must self-serve to the secondary.
6. No forced factor pre-enrollment (no YubiKey rush) — PSSO-Pilot policy requires Password only; FastPass/Touch ID is created AT enrollment.

## B. Jamf device side

7. **ABM** → serial → Assign Device Management → **Jamf MDM Server** → Jamf Device Enrollments → Refresh → **PSSO-Sandbox PreStage** scope shows **Assigned**. Assign close to the wipe; an assignment that sat for weeks may need the uncheck→Save→recheck→Save re-push (#30).
8. ~~Device in SSO-Sandboxing static group~~ **Not needed since 2026-10-21** — the three PSSO profiles are scoped to the smart group `PSSO-Sandbox Enrolled` (Enrollment Method: PreStage enrollment = PSSO-Sandbox); any device enrolling through the PreStage is in scope automatically (#38).
9. **After a wipe:** nothing to re-add. Stale duplicate records (if Jamf created one) → delete the old one. Verify the fresh enrollment in the record: `lastEnrolledDate` moved, all three PSSO profiles listed, no "Remove Configuration Profile" commands in its history.
10. **PreStage must be Device first** (`com.okta.mobile`), never Identity first (#36). If anyone re-enables Simplified Setup after a drift, re-check the workflow radio.

## C. The user's experience (what to tell them / demo)

1. Power on → connect Wi-Fi → Remote Management → **Okta sign-in: email + handover password** (only time they type it)
2. Account created automatically as **admin**
3. **Touch ID pane** → fingerprint
4. Registration completes → **FastPass auto-enrolled, bound to Touch ID** (a brief "continue in browser" handoff may appear — allow opening Okta Verify, tap fingerprint)
5. Done. From now: Mac unlock = Touch ID; Okta app sign-ons = Touch ID (FastPass)

## D. Verification (5 min)

- [ ] **Okta System Log, in order (the proof signature):** `pki.cert.issue` → `device.enrollment.create` + `pki.cert.bind` → `device.platform_sso.keys.register` → `device.password_sync.authentication SUCCESS` → `user.mfa.factor.activate` (Okta Verify) + `device.password_sync.enrollment.create`. Marcelo 2026-10-21: whole chain in 3m35s. Missing `cert.bind`/`keys.register` = no cert at registration (#36/#37); zero events = extension failed locally
- [ ] Okta → user profile → **Okta Verify (FastPass)** factor dated today
- [ ] Mac System Settings → Users & Groups → user → **Registered ● / SSO tokens present ● / "password synced"**
- [ ] `app-sso platform -s` returns a config
- [ ] Lock screen → unlock with Touch ID and/or synced password
- [ ] Browser to `helcim.okta.com` → FastPass/Touch ID offered (no password)
- [ ] Jamf record: stamped username (`user@helcim.com`) + Full Name/Email via LDAP
- [ ] Netskope: client installed by remediation policy → user completed enrollment → console shows user+device

## E. Troubleshooting triggers

- Any sign-in failure → **Okta System Log → user → `outcome.reason`** first, device second.
- Error signatures and fixes: **06-ERROR-CATALOG.md**.

## Production rollout widening (when leaving pilot)

- Swap `PSSO-Pilot` group conditions for broader groups / Everyone where policies allow; consider an Okta **group rule** (HiBob-created users → macOS group) so steps 3–4 become automatic.
- Handover password is one command: `tools/psso-setpass.sh` (delivered 2026-10-16; verifies via live authn, clears PASSWORD_EXPIRED). Remaining manual step at scale = this one call unless an Okta Workflows flow takes it over.
- Chrome standardization: deploy Chrome (Jamf App Installers) + enable Okta EA "SSO extension support for Chrome on macOS" + set default browser (user confirmation on macOS 26).

### Making PSSO-Sandbox the default PreStage (the production flip — order matters)
Blast radius: **existing enrolled Macs are NOT affected.** PreStage settings only apply at activation/Setup Assistant. Impact = future new devices AND any production Mac that gets wiped later (its *user* must then pass the Okta gate: app assigned, clean factors, non-expired password).
1. **Widen the PSSO app assignment FIRST** — "Platform Single Sign-On for macOS" (`0oa1w2y9e0jWfdw701d8`) → onboarding group rule (HiBob users → macOS group) or Everyone. With pilot-only assignment, the first non-pilot hire hits error #1 at first boot.
2. Widen the Netskope enrollment app assignment in the same pass (rollout item).
3. Security sign-off: **New User Account Type = Administrator** must hold as a fleet default, not just pilot.
4. Old default ("Jamf Pro Enrollment") → auto-assign **OFF** — keep the PreStage as rollback/exception lane (loaners, presentation machines).
5. PSSO-Sandbox → set as default PreStage for computers.
6. Proof run: one clean wipe (record spawns at enrollment, naming+stamp at first login, apps land — zero terminal). Only then announce; the Confluence walkthrough (ISP page 312737890) is the doc to link.
7. Exceptions after flip: release the serial from PSSO-Sandbox scope → device falls to... nothing (old default has auto-assign OFF) → manually assign the serial to the old PreStage for that device's next enrollment.
