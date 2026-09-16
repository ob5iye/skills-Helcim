# Error Catalog — signature → root cause → fix

> Every failure this project hit. Check here before debugging anything. Format: symptom/signature | cause | fix. Dates in brackets.

## PSSO / Okta enrollment

| # | Symptom / signature | Root cause | Fix |
|---|---|---|---|
| 1 | **"Unable to log in"** for a brand-new user; System Log `Desktop Password Sync Enrollment → FAILURE: User is not assigned to Platform Single Sign-On for macOS App`; auth itself fully succeeds (password+MFA, OIDC tokens, device added) [2026-08-25, Ana Gibson, H6VPXKDQ5C] | User never assigned to the PSSO app (Sue Doe was individually assigned at build time; nobody added Ana) | Applications → PSSO app → Assignments → assign user/GROUP. SOP makes it group-driven |
| 2 | **Expired password with Okta-protected mailbox** = chicken-egg ("Password expired / one-time password mode" banner; user can't read the reset email because email needs Okta) [Mike Delamont] | UI reset options (email link / "temporary password") both unusable or keep expired state | (a) Set **secondary email** (personal) on profile → reset email goes there too; (b) temp password + **phone browser** — forced change completes in browser and clears the state; (c) API password set (best) |
| 3 | **Native PSSO registration sheet rejects BOTH the local password AND a correct temp Okta password** (greyed-out username) [Anna's laptop rerun] | (a) That sheet wants the OKTA password only — local password will never work; (b) the account was in **expired/one-time mode** — the sheet cannot render a forced-change flow, so it rejects valid credentials silently | Set password with must-change OFF (creation-time option, or API). Never enroll with a temporary/expired-mode password |
| 4 | **Browser ↔ Okta Verify loop** during registration ("Open Okta Verify?" allow → bounces back → repeats instead of Touch ID) [Anna's laptop, Sue Doe] | Sue's **stale FastPass enrollment from the July loaner**: sign-in widget auto-starts FastPass, this Mac's OV has no key for her yet (registration is what creates it) → handoff loop. NOT a Touch ID timing issue (Touch ID was already set up at Setup Assistant) | **Reset Authenticators** for the account (remove old Okta Verify/FastPass + YubiKey) then retry; or on the sign-in page choose **"Sign in another way"** → Password explicitly; clear Safari helcim.okta.com cookies if it sticks |
| 5 | **YubiKey demanded during a "no-YubiKey" test** | Account still had 2 factors enrolled → Account Management Policy **progressive authentication** requires 2. Test account wasn't actually "new-user state" | Reset Authenticators → Password-only → test again. Progressive auth scaling (1 factor for 1-factor users) is by design |
| 6 | Okta Verify/Phone enrollment **offered after browser password set** even though Optional in enrollment policy | OIE by design (bannered doc note on the Password authenticator page): offer appears even when optional/disabled | Skip it, or ignore — PSSO registration enrolls OV/FastPass on the Mac regardless |
| 7 | **Wiped Mac: Okta sign-in + account creation work at Setup Assistant, then nothing — no registration, "Platform Single Sign-on" absent from user pane/profile** [2026-08-26, H6VPXKDQ5C] | Wipe = NEW Jamf computer record; **static group membership (SSO-Sandboxing) does not carry over** → group-scoped PSSO-Extension profile missing post-enrollment (PreStage attachment only covers Setup Assistant) | Re-add the new record to SSO-Sandboxing; delete stale record; `sudo jamf manage`; launch Okta Verify → register. In SOP device-side step |
| 8 | `app-sso platform -s` = null / `-1000 "no extension"` | Okta Verify's app extension loads only when **Okta Verify is launched** | Launch/reinstall Okta Verify, allow extension, reboot |
| 9 | "could not validate the domain" | Associated Domains App Identifier must be **team-prefixed** `B7F62B65BN.com.okta.mobile`; AASA is fine | Fix identifier; don't just edit-in-place — remove payload, save, re-add |
| 10 | "UseSharedDeviceKeys must be 'true'" | Enable button set but **Include toggle** on the right was off | Both ON |
| 11 | Setup Assistant registration walls on **System-keychain "enter an administrator"** prompt with zero Okta log events | First user created as **Standard** — no local admin exists to authorize keychain | **New User Account Type = Administrator** + Account Authorization Type = Administrator |
| 12 | `$USERNAME`/`$EMAIL` variables don't resolve in custom-settings plists at Setup Assistant | Variable substitution not available there | Remove `OktaVerify.UserPrincipalName` from the plists entirely |

## Jamf mechanics

| # | Symptom / signature | Root cause | Fix |
|---|---|---|---|
| 13 | Policy log = **"Completed" but Details shows only "Executing Policy …"** — no script/package lines; nothing installed | **Packages/Scripts payloads silently dropped on policy save** | Re-add payloads, Save, REOPEN and verify left rail counts (Packages 1 / Scripts 1) before trusting it; then Logs → **Flush** |
| 14 | `sudo jamf policy` doesn't run a Login-trigger policy | `jamf policy` only fires Recurring Check-in; **Login trigger isn't simulated** | `sudo jamf policy -event login`, or log out/in, or enable Recurring Check-in on the policy |
| 15 | Remediation policy reinstalls repeatedly all day | Smart group can't drop the member — inventory stale | **Maintenance → Update Inventory ✓** so recon runs right after install |
| 16 | Setup Assistant shows plain "create user", no Okta | Wrong PreStage / ABM pointing at Kandji / Okta Verify pkg not a classic enrollment package with a distribution point | ABM → Jamf MDM Server; scope serial to PSSO-Sandbox until "Assigned"; default PreStage auto-assign OFF; classic pkg + Cloud DP |
| 17 | Device on Kandji after reassignment | Default PreStage auto-assign re-grabs | Turn default PreStage auto-assign OFF |
| 18 | Jamf scope targets look right but mis-behave ("scoped to group A but also ran elsewhere") | Jamf scope targets are a **UNION**, not intersection | Put intersection INSIDE smart-group criteria (AND member of …), or use Exclusions |

## Netskope

| # | Symptom / signature | Root cause | Fix |
|---|---|---|---|
| 19 | **Netskope install failed on new device** (`nsinstparams.json` missing/empty email) | Race: install ran before stamp→LDAP→$EMAIL→plist chain completed | Architecture replaced by **IdP/SAML mode** (05-NETSKOPE-IDP.md) — chain deleted. Legacy stopgaps: scope email-dependent pieces to "Email populated" smart group; pre-flight guard at top of script checking the plist |
| 20 | Script parameters "prefilled" but nothing passed | Grey strings were **parameter LABELS**, not values | Type real values in the fields; fix labels in Settings → Scripts → Options (or duplicate script with honest labels) |
| 21 | Enforcement param did nothing (bare `10`) | Bare values are ignored — script only parses keywords: `idp`, `enrollencryptiontoken=`, `ENFORCEENROLL*=`, `mode=` etc. | `ENFORCEENROLLFREQUENCY=10`; and update to the latest JAMFScripts bundle — v22 script ignores ENFORCEENROLL entirely |
| 22 | After Okta sign-in, "can't reach enrollment page" | Two Netskope Okta apps conflated / wrong SAML account record | Distinct apps + distinct Forward Proxy SAML account; verify ACS/Entity pairing |

## LDAP (Okta ↔ Jamf)

| # | Symptom / signature | Root cause | Fix |
|---|---|---|---|
| 23 | LDAP bind denied: `password_auth_denied_policy` / "invalid credentials (49) … denied by sign on policy" | OIE: the bind (ROPC) is governed by the LDAP Interface app's **app-level** sign-on policy (Default MFA Policy, catch-all 2 factors) — Global Session Policy changes do nothing (no session is created) | Default MFA Policy P1 rule: IF group "LDAP Service Accounts" → password only. Keep that group exclusive |
| 24 | LDAP search returns result 50 **Insufficient access** | Standard-user bind can read only its own entry | Grant bind account **Read-only Administrator** role |
| 25 | Empty lookups / wrong email imported | Wildcards unsupported; `mail` is multi-valued (incl. personal email) | Uncheck "Use Wildcards When Searching"; Email → `mail` with `uid` fallback; UUID → `uniqueIdentifier` |

## Terminal / ops gotchas

| # | Symptom | Cause | Fix |
|---|---|---|---|
| 26 | curl command hangs doing nothing | Smart quotes from pasting (`“”` vs `"`) — shell waits for balanced quotes | Ctrl+C; retype as single line with hand-typed quotes |
| 27 | `read -s VAR` "doesn't work" in new terminal | Variables don't persist across windows | Re-run `read -s` per window |
| 28 | Okta background image rejected | 2MB upload limit (PNG gradients are ~8MB) | Export JPEG (sips -s format jpeg) → ~150KB |
| 29 | Button color looks washed-out on sign-in page | Disabled state (empty Username field) — Gen3 widget lightens primary when disabled | Type text → full color; not a theme bug |

## Housekeeping incident residue

- GSP "LDAP Service Accounts [No MFA]" — dead config (harmless but grants password-only interactive sessions; delete after jamf-ldap password rotation)
- "Testing & Migration (MFA Bypass)" policy serves Rundeck + Helcim Argo CD — keep; only a stray LDAP-rule copy inside it may be deleted
- jamf-ldap service-account password was exposed during Aug-21 troubleshooting — **rotation still pending** (08-PENDING-ITEMS.md)
