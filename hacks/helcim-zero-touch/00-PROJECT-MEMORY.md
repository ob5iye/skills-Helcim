# Helcim Zero-Touch macOS Project — Master Memory File
**Last updated: 2026-09-01 · Author of record: Abdi Obsiye (IT) · Stack: ABM → Jamf Pro → Okta (OIE, Device Access) → Netskope**

> **For AI models:** Start here. This file is the index + executive summary. Each numbered file is self-contained — inject this file plus whichever topic file matches the task. Everything is verified against a live org (`helcim.okta.com`), not generic documentation. When this pack conflicts with vendor docs, this pack wins for THIS org.

---

## What this project is

Zero-touch provisioning of MacBooks at Helcim (fintech, ~100% Mac fleet, Jamf Pro cloud, Okta Identity Engine with Device Access):

**A new hire (created via HiBob → Okta) is handed a factory/wiped MacBook → Setup Assistant asks for Okta email + one-time handover password → local admin account is created from the Okta identity → Touch ID setup is forced → Okta FastPass is auto-enrolled and bound to the fingerprint → from that moment the user is effectively passwordless (Mac unlock = Touch ID; app SSO = Touch ID/FastPass) → Netskope self-installs and enrolls via Okta SAML with one Touch ID tap → no IT touches the device.**

Head of security's requirement that drove the final design: *"someone given a laptop and the enrollment forces him to create FastPass."* Delivered via mandatory PSSO registration in Simplified Setup + Okta Verify authenticator set to biometric user verification.

## Project phase

**Pilot → production transition.** PSSO password-sync proven (post-login + Setup Assistant). FastPass forced-enrollment design validated in policy audit and live registration. Netskope re-architected from a fragile email-stamping chain to IdP (SAML) enrollment — pilot succeeded, production rollout in progress.

## File map (read order for a new AI/engineer)

| File | Content |
|---|---|
| `01-CURRENT-STATE.md` | Where everything stands RIGHT NOW — what's live, what's pilot, what's proven |
| `02-EXACT-CONFIG.md` | Every exact value: Jamf profiles, PreStage, SCEP, Okta apps, LDAP, Netskope params |
| `03-POLICY-MODEL.md` | The three-layer auth evaluation model + FastPass enrollment design — the hardest-won knowledge |
| `04-SOP-NEW-USER-DEVICE.md` | THE standard procedure: new user + new/wiped device, end to end |
| `05-NETSKOPE-IDP.md` | Netskope IdP-mode architecture, parameters, remediation loop, rollout |
| `06-ERROR-CATALOG.md` | Every error hit + signature + root cause + fix. Check here FIRST when something breaks |
| `07-BRANDING.md` | Corporate brand: official palette, generated assets, Okta brand settings |
| `08-PENDING-ITEMS.md` | Open actions (password rotation, cleanups, unconfirmed tests) |
| `tools/` | Swift utilities used: video frame extraction, PDF text/page extraction, color sampling, brand asset generation |

## Core environment facts

- **Okta:** OIE org `helcim.okta.com`, Device Access licensed. Users provisioned from **HiBob** (no manual Add Person in production)
- **Jamf Pro:** cloud, ADE instance "Jamf MDM Server", 11.29+. Second MDM Kandji exists — default ABM assignment must be Jamf
- **Fleet:** macOS 26 (Tahoe). Test devices: Sue's M5 Pro (C7RQFYWHYG), H6VPXKDQ5C M2 Pro (Sue_Doe test), PMQG2X21TQ (Test's)
- **Test users:** Sue Doe `sdoe@helcim.com` (test account; reset to password-only for clean enrollment tests), Ana Gibson `agibson@helcim.com`, Mike Delamont `mdelamont@helcim.com`
- **Netskope tenant:** `helcim.goskope.com` — production used email-stamping mode (being replaced), new standard = IdP/SAML enrollment

## The five hard-won principles (never violate)

1. **Passwords for enrollment must be admin-set with must-change OFF.** Any "temporary password"/expired-mode password is rejected by the native PSSO sheet. New-Okta-user: set at creation. Existing/expired user: API `PUT /api/v1/users/{login}` with `credentials.password` (UI cannot do this). Users come from HiBob → the API set is THE standard onboarding step.
2. **Group, not person.** Every app assignment and policy scope should be group-based (`PSSO-Pilot` group carries: PSSO app assignment + enrollment policy + Netskope enrollment app assignment). Individual assignments caused two incidents (Ana; Netskope enrollment app).
3. **A wipe = a new Jamf record.** Static group membership does NOT survive. After every wipe/re-enroll: re-add to static groups, delete the stale record.
4. **System Log first.** For ANY Okta-side failure: Reports → System Log → user email → `outcome.reason` names the exact fault. Never debug the device first.
5. **Order the dependency chains.** Netskope-before-identity was the recurring failure. New architecture (IdP mode) removes the chain; where ordering matters (profiles, stamping), gate with smart groups + Update Inventory.
