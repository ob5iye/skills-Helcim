# Current State — as of 2026-09-01

## PSSO / Desktop Password Sync — LIVE, PROVEN

| Component | State |
|---|---|
| PSSO-Extension profile (5 payloads consolidated: SSOe + SCEP + Associated Domains + System Extensions + 2 custom settings) | Deployed, scoped to **SSO-Sandboxing** static group |
| PSSO-Sandbox PreStage (Simplified Setup, macOS 26+, Okta Verify 9.65.2 classic pkg via Cloud DP) | Active; 3 test devices Assigned |
| Setup Assistant zero-touch enrollment (Okta sign-in creates local admin account) | **Working** — verified on wiped H6VPXKDQ5C with Sue Doe |
| Post-login registration | Working — verified on Ana's device (Registration ● / SSO tokens ● / password synced) |
| Forced FastPass/Touch ID at enrollment | Working by design (biometric user verification required on Okta Verify authenticator) |
| Password sync rotation | Proven earlier: device password rotated to Okta password on test device |

## Okta policy state (all audited, see 03-POLICY-MODEL.md)

| Layer | State |
|---|---|
| Global Session Policy (Default) | MFA Not Required ✓ |
| "Platform Single Sign-On for macOS" app-specific sign-in policy | Catch-all = password-only, bound 1:1 to the app ✓ |
| Okta Account Management Policy | Catch-all = **progressive authentication** (1-factor users → 1 factor; 2+ factors → 2) ✓ |
| Authenticator Enrollment Policy "PSSO-Pilot" | Password required ONLY; Email/Google Auth/Okta Verify/Passkey all Optional (changed 2026-08-25 — YubiKey no longer forced) |
| Default MFA Policy (20+ apps) | P1 "LDAP Service Accounts + Password Only" (LDAP fix, keep); P2 FastPass rule (Everyone + Registered device); catch-all 2 factors |
| Dead config to clean | GSP "LDAP Service Accounts [No MFA]" (never functional — ROPC is session-less); possible stray LDAP rule copy inside "Testing & Migration (MFA Bypass)" policy (which legitimately serves Rundeck + Helcim Argo CD — do NOT delete the policy) |

## Netskope — ARCHITECTURE MIGRATION IN PROGRESS

| Mode | State |
|---|---|
| **Legacy: preference_email mode** (stamp → LDAP → $EMAIL → plist → script) | Production currently; fragile, caused repeated failures on new devices. Being replaced. |
| **New: IdP/SAML mode** (client enrolls via Okta sign-in, one Touch ID tap with FastPass) | **Pilot proven on Abdi's Mac** (script → install → Okta sign-in page appeared). Policy `Netskope – IdP Pilot` scoped to smart group "Netskope - Not Installed", Recurring Check-in + Ongoing + Update Inventory = self-healing remediation loop |
| SAML plumbing | Already existed: Netskope "Client Enrollment SAML - Okta" Forward Proxy account + Okta OIN app `netskopeuserenrollment` (exk234kg25xtJ8s0Q1d8) |
| Known gaps | Script in Jamf is v22 (no ENFORCEENROLL* support — need latest JAMFScripts bundle); Param 10 was set as bare `10` (ignored — needs `ENFORCEENROLLFREQUENCY=`); enrollment app assigned to 6 individuals (must become group/Everyone for production); old email-mode policy must be disabled to avoid double-install |

## Branding — LIVE

Okta default brand themed with new September palette: Plum `#4F1B86` primary, Navy `#1A0F4C` secondary, radial Plum-family gradient background (website-style), Helcim logomark as logo, favicon set, heading "Sign in to Helcim". Applied to sign-in/verify/error pages + end-user dashboard (violet sidebar). See 07-BRANDING.md.

## Test-device ledger

| Device | Serial | State |
|---|---|---|
| Sue's MacBook Pro | C7RQFYWHYG | PSSO registered (post-login path), works |
| H6VPXKDQ5C M2 Pro (ex-Ana, renamed Sue_Doe) | H6VPXKDQ5C | Wiped → Setup Assistant enrollment with Sue OK → profile re-added to SSO-Sandboxing → registration re-run with API-set password → "went through", browser sign-in leg being redone at last report |
| Test's MacBook Pro | PMQG2X21TQ | In scope, pilot |
| Abdi's Mac | N6VN9M200T M3 Pro | Netskope IdP pilot machine #1 — enrolled via Okta sign-in |

## User ledger (pilot accounts)

| User | Factors | PSSO app | Netskope enrollment app |
|---|---|---|---|
| Sue Doe | Password only (reset via Reset Authenticators) | assigned | to add for pilot |
| Ana Gibson | Password + YubiKey (+ FastPass from 2026-08-25 registration) | assigned ✓ (fixed — was the "User is not assigned" incident) | — |
| Mike Delamont | set up with temp password (was in expired mode initially — fixed) | assigned | — |

## Historical resolutions (fully closed, details in 06-ERROR-CATALOG.md)

- Okta LDAP → Jamf bind (OIE app-level policy fix + Read-only Admin role) — Aug 21
- macOS username stamping for User&Location/Netskope email — superseded by IdP mode (chain no longer needed for Netskope; LDAP still feeds Jamf inventory)
- PSSO zero-touch keychain wall (New User Account Type = Administrator) — July
- Brand system update to September palette (design director) — done

**Companion docs repo:** `/Users/aobsiye/Claude/Projects/OKTA/` (handoffs, deployment procedure, playbook skill) — mirrored copy at `/Users/aobsiye/Documents/Claude Skills/Zero Touch/`. This Devin pack is the AI-injection master copy.
