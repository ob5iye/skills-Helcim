# Pending Items — open actions, ordered by urgency

## Security (do first)

1. **Rotate `jamf-ldap@helcim.com` password** — exposed in chat during Aug-21 troubleshooting. Steps: Okta reset → update Jamf LDAP server password field. Then delete/deactivate the dead GSP "LDAP Service Accounts [No MFA]" policy (it grants password-only interactive sessions to that account as long as the password is stale).
2. **API token hygiene** — the `psso-onboarding` SSWS token (created 2026-09-01) can set ANY user's password. Stored per guidance (1Password); consider IP-zone restriction (recreate token restricted to office zone); revoke when the onboarding helper script gets keychain storage.
3. Netskope enrollment tokens appeared in screenshots/shared output — low sensitivity, treat as internal.

## Confirmations still open (tests not closed)

4. **Sue's laptop (H6VPXKDQ5C) final confirmation** — registration went through post-API-password; browser sign-in leg was being redone at last report. Confirm: Registered ● / tokens ● / synced + FastPass factor dated today.
5. **Mike Delamont real-device run** — the true production-scenario demo (password-only new user, wiped laptop). Not yet executed end-to-end.
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
