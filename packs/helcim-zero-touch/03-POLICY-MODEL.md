# Okta Policy Model — how a PSSO sign-in is actually evaluated

> The hardest-won knowledge in this project. OIE evaluates THREE policy layers during a PSSO registration; understanding this model is what unlocked password-only new-user enrollment.

## The three layers (in evaluation terms)

1. **Global Session Policy** (Security → Global Session Policy) — establishes the Okta session for interactive sign-ins.
   - Helcim Default rule: **MFA Not Required** → password-only sessions allowed.
   - NOT evaluated for LDAP/ROPC binds (session-less) — that's why the Aug GSP "LDAP No MFA" policy never worked; LDAP is governed only at app level.
2. **App sign-in policy** (per-application) — governs access to that specific app.
   - "Platform Single Sign-On for macOS" has its OWN app-specific policy (created automatically): catch-all **Allowed with password** → password-only registration allowed.
   - LDAP Interface app is bound to "Default MFA Policy" → that's why the LDAP fix was a P1 password-only rule there ("LDAP Service Accounts + Password Only").
3. **Okta Account Management Policy** (Authentication Policies → "Okta account management") — gates **authenticator enrollment operations**, which fire when PSSO registration enrolls FastPass/Okta Verify.
   - Catch-all: **"progressive authentication" — 1-factor users verify with 1 factor; users with 2+ factors enrolled verify with 2.**
   - Symptom of this layer: a registration that prompts for a second factor (e.g. YubiKey) even though layers 1+2 are password-only — the user simply HAD two factors enrolled. Not a policy failure.

**Read any failed sign-in in this order:** System Log event → which policy was evaluated (the event names it) → fix that layer only.

## Authenticator Enrollment Policy "PSSO-Pilot" (who must enroll what)

- Required: **Password** only (since 2026-08-25; Passkey/YubiKey demoted Optional)
- Optional: Email, Google Authenticator, **Okta Verify**, Passkey (FIDO2, YubiKey group list)
- Okta Verify stays Optional on purpose: making it Required would force phone-app enrollment (QR flow) during any browser sign-in — friction for zero benefit, because PSSO registration auto-enrolls Okta Verify/FastPass on the Mac anyway.
- OIE always **offers** Okta Verify/Phone enrollment after a password set/change even when Optional/disabled — a bannered doc note confirms this is by design. It's skippable.

## Forced-FastPass enrollment design (the head-of-security requirement)

Requirement: *"someone given a laptop and the enrollment forces him to create FastPass."*

How it's forced, no opt-out:
1. Simplified Setup: the Okta sign-in IS account creation — no local-account bypass at Setup Assistant; no "Not Now".
2. PSSO registration **auto-enrolls FastPass** (documented Okta behavior: "when Setup Assistant finishes, the user has a local account synced with Okta and a pre-enrolled Okta FastPass authenticator").
3. Okta Verify authenticator = **biometric user verification required** → FastPass enrollment cannot complete without Touch ID → fingerprint setup is unavoidable.

Result: new user = temp/handover password typed ONCE → Touch ID → passwordless from then on (Mac unlock = Touch ID; app SSO = FastPass).

## FastPass availability rules (reconciliation that settled the security-team debate)

- FastPass appears as a sign-in option ("Use Okta FastPass" / auto-start) **only for users already enrolled** — an enrolled user registering a NEW/WIPED Mac can complete PSSO sign-in with **FastPass and no password**.
- A **brand-new user cannot use FastPass at enrollment** — it doesn't exist until registration creates it (bootstrap; the one-time password is mandatory).
- macOS 27 will add QR-code/web-based auth at the PSSO window (fully passwordless first enrollment) — not on macOS 26.

## Browser coverage for app SSO

- Safari: seamless SSO extension support out of the box.
- Chrome: requires Okta Early Access feature **"SSO extension support for Chrome on macOS"** (Settings → Features) + Chrome 146+.

## Group-discipline rules learned from incidents

- Assign apps/policies to **groups**; every individual-assignment skip caused an outage (Ana: PSSO app; Netskope enrollment app was 6 individuals).
- Rules scoped to pilot group during pilot; production widening = change group condition (e.g. Everyone + Device: Not registered for enrollment-moment rules).
- Do NOT add broad rules to Default MFA Policy (20+ apps bound) — a group-scoped password-only rule there would also weaken pilot users on OTHER apps from unregistered devices. PSSO was fixed without touching it because the PSSO app has its own policy.
