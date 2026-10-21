# Pending Items — open actions, ordered by urgency

## Security (do first)

1. **Rotate `jamf-ldap@helcim.com` password** — exposed in chat during Aug-21 troubleshooting. Steps: Okta reset → update Jamf LDAP server password field. Then delete/deactivate the dead GSP "LDAP Service Accounts [No MFA]" policy (it grants password-only interactive sessions to that account as long as the password is stale).
2. **API token hygiene** — 2026-10-16: the original 2026-09-01 `psso-onboarding` token was already gone from the console (silent delete → E0000011). Recreated 2026-10-16; zone-restriction attempt self-rejected the caller (no Office Egress zone exists — see catalog #31) so it's **Any IP for now**. TODO: create "Office Egress" IP zone (Security → Networks) → restrict token to it → re-verify from office. **Office egress candidate: `162.217.233.210`** (C7RQFYWHYG check-in 2026-10-16; also Zach U. sign-in IP Sep-28) — confirm with `curl ifconfig.me` from an office Mac before committing the zone. A 2026-10-16 token string was pasted in chat and then REUSED live (zone flipped to Any IP) to set Sue's password — the exposed string is a **proven-working password-set token and must be rotated out today**: delete → recreate via `read -s` → update 1Password. Helper script delivered 2026-10-16: `tools/psso-setpass.sh` (token in macOS Keychain via `--set-token`, generates policy-compliant passwords). **Rotation flow is now concrete:** delete the exposed token → create the final one → `psso-setpass.sh --set-token` once → done.
3. Netskope enrollment tokens appeared in screenshots/shared output — low sensitivity, treat as internal.
3b. **ROTATE BOTH API CREDENTIALS EXPOSED IN CHAT ON 2026-10-20 (same day, non-negotiable):** (a) Okta SSWS `psso-onboarding` (value `006g…3SviK` was pasted and used live) → Security → API → Tokens → delete → create → `psso-setpass.sh --set-token`; (b) **Jamf API client `devin-psso`** (client ID + secret pasted in chat) → Settings → API Roles & Clients → client → *Generate client secret* (invalidates the old one) → `security add-generic-password -U -a jamf -s jamf-api-client-secret -w '<new>'`. Role `Automation-Psso` is narrow (profiles/PreStage/computers/static groups) — add *Read Smart Computer Groups* if API work continues.

## Confirmations still open (tests not closed)

4. ~~Sue's laptop final confirmation~~ → superseded: **the clean proof run is Marcelo Ramos / L9MF750DC9, 2026-10-21** (full Okta chain, no manual steps). H6V and KR29 were wiped 2026-10-20 and sit unenrolled (records show mdm=False, last contact 17:52Z) — re-enroll them under the final config when convenient; they'll land in the smart group automatically.
5. **Mike Quick / JR2X3X4MD2** — JR2 currently carries the `Setup_User` local account and an Okta device record bound to Sandra Mastrovito. Wipe and re-enroll as Mike under the final config (his password `LuckyMorning-18*` is live). Same for any other pilot laptop still showing `Setup_User-…` / `RealName:_…` names.
5b. **Stale Jamf records are generating a SCEP-challenge loop**: pending `Install Configuration Profile PSSO-Device Access` commands to offline/stale records (PMQG "Test's MacBook Pro", JR2 Setup_User, old MQ6K) make Jamf fetch a new Okta dynamic challenge every ~5 min (`device.platform.add` all night 2026-10-20/21). Clean up: delete truly stale records, let online ones complete. Not harmful to enrollments, but noisy in Okta's log and wasteful.
5c. **Retire the static group `SSO-Sandboxing` (54)** from the three profiles' scope once a second clean enrollment confirms the smart group alone is sufficient (it is redundant now; keeping both is harmless).
5d. **Confluence walkthrough page 312737890** still says "validated Oct 16" and lacks the Oct 20–21 lessons (Device first, all-apps access, smart-group scope, the identity-first trap). Update the troubleshooting table and the pre-flight list.
6. **Netskope pilot on Sue's + Test's Macs** — clean old client (`jamfuninstall.sh`), assign both users to the Netskope enrollment app, confirm Touch-ID enrollment + user records appear in console.

## Netskope production rollout (from pilot)

7. Assign Netskope "Client Enrollment - SAML Forward Proxy" app to **Everyone**/group (was 6 individuals)
8. **Disable** legacy email-mode install policy (keep as rollback)
9. Update Jamf `nsclientconfig` script to the **latest JAMFScripts bundle** (ENFORCEENROLL support)
10. Fix param 10: `ENFORCEENROLLFREQUENCY=10`; verify steering profile `459fa765-9e75-43b5-b03b-cacdd9725e5d` is the intended restrictive pre-enrollment profile
11. Watch "Netskope - Not Installed" membership drain to 0 after rollout; then idp mode is the standing install path
12. Optional: SCIM provisioning app for deprovisioning hygiene; EA + smart group for "installed but unenrolled" stragglers

## Cleanup

13. GSP "LDAP Service Accounts [No MFA]" — delete (see #1)
14. "Testing & Migration (MFA Bypass)"→ check Rules tab for stray LDAP-group rule copy; delete the RULE only (policy serves Rundeck + Argo CD)
15. Stale duplicate Jamf computer records (post-wipe duplicates — e.g. double "Sue's MacBook Pro") — delete old
16. ~~"PSSO-Device Access" zombie profile — delete~~ **REVERSED same day:** it is now the LIVE SCEP profile (scoped SSO-Sandboxing + PreStage-attached) after #35 proved dynamic SCEP can't live in the pre-enrollment SSOe profile. Keep. The SCEP challenge password's only copy is the 1Password note "OKTA - SCEP configuration" (Helcim vault) — Okta never re-displays it.
17. **Raise PreStage min macOS from 15.8.1 to a 26.x** once every test/loaner Mac is ≥ that build (currently 26.5.1 on H6V/KR29 blocks picking 26.5.2).
18. **Office Egress IP zone** → restrict `psso-onboarding` token to it (candidate IP `162.217.233.210`, verify with `curl ifconfig.me` from office first).
19. **Three enrolled Macs (JR2, MQ6K, PMQG) → confirm they take the re-split profiles cleanly**: PSSO-Extension (now SCEP-less) Completed, PSSO-Device Access Completed, user pane still Registered ●, `app-sso platform -s` still returns config. JR2 note: its Okta device record is bound to Sandra Mastrovito, not Mike — resolve ownership before handover.
16. Remove accidentally-created duplicate password-only rule if any lingering on Okta Account Management Policy (July note: one was deactivated — verify it's gone/inactive)

## Parked decisions

17. **Custom domain `login.helcim.com`** — needs DNS CNAME owner; unlocks code editor + "Powered by Okta" removal + new brand
18. **End-User Dashboard layout** — sections ("New hire essentials" Everyone / "IT & Security" IT-only), Recently used + Favorites
19. **Chrome as default browser fleet-wide** — Jamf deploys Chrome; macOS 26 asks user to confirm default change; enable Okta EA "SSO extension support for Chrome on macOS"
20. **HiBob activation emails** — check whether the integration auto-sends Okta activation emails on push (confusing parallel path vs the laptop-handover flow); disable if so
21. **HiBob → secondEmail mapping** — Sue's secondEmail is null; if HiBob carries personal email, map it (powers self-service resets)
22. **Device-Bound SSO** (`OktaJoinEnabled`, `com.okta.deviceaccess.servicedaemon`) — silent app SSO after device login; explore as v2 polish
23. **macOS 27 Platform SSO** — QR-code/web-based + require Touch ID at PSSO window; revisit onboarding to fully passwordless when fleet moves

## Other org threads (outside this project's core, don't lose them)

24. Lingo SSO cutover — Okta app done; pending Brad Root's cutover confirmation (was scheduled Tue 2026-08-25) + reconcile user #138
25. Okta org email suppression (bounce issue from Aug) — confirm with Okta whether resolved; it underpins why secondary-email/API flows matter
