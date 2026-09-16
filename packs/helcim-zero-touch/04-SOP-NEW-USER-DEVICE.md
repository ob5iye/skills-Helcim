# ⭐ SOP — New User / New-or-Wiped Device (THE standard procedure)

> Run top to bottom for every new hire and every laptop reissue. Born from the Ana Gibson incident (2026-08-25) and hardened through Mike Delamont prep + Sue Doe wipe tests. **Do not skip steps; every skip has caused a specific documented failure** (see 06-ERROR-CATALOG.md).

## A. Okta side (before touching the laptop ~10 min)

1. **User exists** — production users arrive via **HiBob push** (never Add Person). Test users: create manually.
2. **Set the handover password:**
   - New user created in Okta: Add Person → **Set password** → **uncheck "User must change password on first login"**
   - HiBob-provisioned or expired-mode user (the production case): **API set** — the UI has no no-expiry option for existing users; UI "Create a temporary password" = expired mode = the PSSO sheet rejects it:
     ```bash
     read -s OKTA_TOKEN   # paste token once (Security → API → Tokens; store in 1Password)
     curl -X POST "https://helcim.okta.com/api/v1/users/LOGIN@helcim.com" \
       -H "Authorization: SSWS $OKTA_TOKEN" \
       -H "Content-Type: application/json" \
       -d '{"credentials":{"password":{"value":"<HandoverPassword>"}}}'
     ```
     Password policy (Helcim): 12+ chars, upper+lower+number, no username substring, not common. Success = JSON user object, status ACTIVE, fresh `passwordChanged` timestamp.
   - **Reissuing a previously-used account** (wipe/reissue): first **More Actions → Reset Authenticators** → remove YubiKey + old Okta Verify/FastPass enrollments (stale FastPass causes the browser↔OV loop; 2+ factors trigger the progressive 2-factor challenge).
3. **PSSO-Pilot group** membership ✓ (carries the enrollment policy).
4. **App assignments** (group-driven): **"Platform Single Sign-On for macOS"** AND **"Netskope Client Enrollment - SAML Forward Proxy"** — assign group `PSSO-Pilot` to both apps once; then per-user = one group add.
5. **Secondary email** (personal) on the profile — company email is Okta-SSO-protected; resets must self-serve to the secondary.
6. No forced factor pre-enrollment (no YubiKey rush) — PSSO-Pilot policy requires Password only; FastPass/Touch ID is created AT enrollment.

## B. Jamf device side

7. **ABM** → serial → Assign Device Management → **Jamf MDM Server** → Jamf Device Enrollments → Refresh → **PSSO-Sandbox PreStage** scope shows **Assigned**.
8. Device in **SSO-Sandboxing** static group.
9. **After ANY wipe/re-enroll:** the Mac returns as a NEW computer record → re-add to SSO-Sandboxing + **delete the stale old record**. Missed = Okta sign-in works at Setup Assistant but no registration afterward (profile gone when scope syncs).

## C. The user's experience (what to tell them / demo)

1. Power on → connect Wi-Fi → Remote Management → **Okta sign-in: email + handover password** (only time they type it)
2. Account created automatically as **admin**
3. **Touch ID pane** → fingerprint
4. Registration completes → **FastPass auto-enrolled, bound to Touch ID** (a brief "continue in browser" handoff may appear — allow opening Okta Verify, tap fingerprint)
5. Done. From now: Mac unlock = Touch ID; Okta app sign-ons = Touch ID (FastPass)

## D. Verification (5 min)

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
- The only remaining manual step at scale = the API password set (candidate for an Okta Workflows flow or a `psso-onboard.sh` helper script).
- Chrome standardization: deploy Chrome (Jamf App Installers) + enable Okta EA "SSO extension support for Chrome on macOS" + set default browser (user confirmation on macOS 26).
