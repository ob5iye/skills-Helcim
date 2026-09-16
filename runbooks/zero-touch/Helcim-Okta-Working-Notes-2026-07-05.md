# Helcim — Okta Lifecycle & Zero-Touch: Working Notes

**Date:** 2026-07-05 · **Owner:** Abdi Obsiye (IT Admin) · **Scope:** everything covered this session
**Companion doc:** `Helcim-Identity-TOM-Runbook.md` (the full Target Operating Model / architecture)

---

## 1. Environment (confirmed / corrected this session)

| Area | State |
|---|---|
| OS | **macOS 26 (Tahoe) fleet-wide** — so Platform SSO Simplified Setup is available on every machine |
| Identity | **Okta** (IdP) + **Okta Verify** deployed + **YubiKeys** (FIDO2, phishing-resistant) in use |
| Okta licensing | **Device Access / Desktop MFA confirmed present** (Device Recovery PIN setting visible — keep it **Disabled**). Lifecycle Management + Okta Workflows still to confirm |
| MDM | **Two MDMs: Jamf Pro (123 devices in ABM) + Kandji (66)**. Kandji's purpose not yet confirmed (legacy / migration / separate group?) |
| HRIS | HiBob (system of record). *Open item:* a **BambooHR** profile also shows in Okta Profile Editor — confirm which is the true HR source |
| Productivity | Google Workspace (migrating apps from Google SSO → Okta SSO) |
| Device enrollment | **Apple Business Manager** linked to Jamf; many retail-bought Macs historically not in ABM |

---

## 2. How Okta RBAC actually works here

- Group membership is assigned by **Okta Group Rules** (native to Okta), **not** by HiBob. HiBob is the *profile source* (masters `title`, `department`); Okta rules read those attributes and assign users to Okta groups.
- Current rules key off **`user.title`** with `stringContains` (brittle — variant/typo titles get missed). **Recommendation:** migrate to `user.department` (a controlled HiBob picklist).
- Groups that a rule can target are **Okta-mastered** by definition (rules can't target app/directory-imported groups).

---

## 3. Offboarding — current state (from Okta System Log analysis)

Analyzed the week of 2026-06-25; reference leaver **gmichel@helcim.com** (deactivated 2026-06-27).

**It's automated, not manual.** Events show admin **Neil Stewart** as actor because an automated rule runs **under his personal account** — not a human clicking.

**What works (cascade completes in ~5s):** Okta sessions ended + cleared; **SCIM deprovision** fires for **Google Workspace, Atlassian, Datadog, Curricula, Netskope**.

**Gaps:**

- **SSO-only apps removed but NOT deprovisioned** — GitLab, Snyk, HubSpot, Bruno, Vanta. Okta assignment is removed but no account-disable call, so **standing tokens survive** (GitLab PATs, Snyk API tokens, etc.).
- **No Jamf device lock/wipe** anywhere in the cascade.
- **Automation tied to a personal account** (breaks if Neil's creds rotate / he leaves) → move to a dedicated service account.

**Other signals caught:** Argo CD OIDC client is **looping** (~926 OAuth events + 649 sign-on policy evals ≈ 1/3 of all log volume — likely token-refresh misconfig); **Vanta** hits Okta rate limits (12×); Okta **ThreatInsight flagged IP 35.254.248.132** (Jun 29).

---

## 4. Jira backlog created (project ITSP, site helcim.atlassian.net)

**Offboarding deprovisioning — Epic [ITSP-85]:**

| Ticket | App | Priority |
|---|---|---|
| ITSP-86 | GitLab | High |
| ITSP-87 | Snyk | High |
| ITSP-88 | HubSpot | High |
| ITSP-89 | Bruno | Medium |
| ITSP-90 | Vanta | Medium |

**Net-new SCIM integrations — Epic [ITSP-91]** (relates to ITSP-85):

| Ticket | App | Priority |
|---|---|---|
| ITSP-92 | 1Password (needs SCIM bridge) | High |
| ITSP-93 | Figma | Medium |
| ITSP-94 | Pendo | Medium |
| ITSP-95 | Certent (confirm SCIM vs SAML-only) | Medium |
| ITSP-96 | Lingo (confirm SCIM vs SAML-only) | Medium |

Onboarding counterpart already existed: **[ITSP-47]** zero-touch provisioning epic (+ spikes ITSP-71/72/73/75).

**ITSP gotcha:** every issue requires the custom **SRED** field (Yes/No) on create — set **No** for routine ops work or the create fails.

**Parked in ITSP-85 for later:** Workflows → Jamf device lock/wipe; move offboarding automation to a service account; confirm HiBob-driven trigger.

---

## 5. Test harness (build once — serves both tracks)

Create one throwaway Okta-mastered identity (NOT in HiBob):

1. **User: Sue Doe — `sdoe@helcim.com`** ("sudo"; deliberately funny, obviously-not-a-service-account name — per security team — and "Doe" also flags it as a placeholder, so no one mistakes it for a real person or a service account). Create it in **Google Workspace** (Test / Service Accounts OU) so it syncs to Okta and can actually authenticate — a staff/Google account is required for Okta sign-in. Password set by admin, "must change" off; secondary email = yours. Assign the **Platform Single Sign-On for macOS** app and enroll MFA (Okta Verify / YubiKey). *(Do NOT reuse an existing service account like `fuzz@helcim.com` — PSSO binds + password-syncs the identity and the offboarding test deactivates it.)*
2. **Department = `Developers`** + a **Title** that matches your Developers group rule (so RBAC fires). Or leave neutral and use a dedicated group.
3. **`TEST-Lifecycle` group** — assign the test apps to it so scope is controlled regardless of department.
4. **Give it real state to kill:** let apps provision; **create tokens** (GitLab PAT, Snyk/HubSpot tokens) so you can prove revocation.
5. **MFA:** enroll Okta Verify (or a YubiKey) so you can sign in as it at Setup Assistant.

**Run the offboarding test:** System Log open (filter the username) → **Deactivate** in Okta → watch `user.lifecycle.deactivate` → `user.session.clear` → `application.user_membership.remove` → `application.provision.user.deactivate/deprovision`. **Then test each token — SSO tile gone but token still works = confirmed gap.**

**Reuse for zero-touch:** reactivate it, then sign in as it at Setup Assistant on the lab Mac.

**Cleanup:** deactivate → delete user + group, revoke tokens, reclaim seats.

---

## 6. Apple Business Manager (ABM)

**Getting Macs into ABM:**

- **Future purchases (no touch):** in ABM add your reseller's **Reseller ID** / your **Apple Customer Number**, and give the reseller your **ABM Org ID** → purchases auto-appear.
- **Already-bought Macs:** **Apple Configurator for iPhone** — boot to Setup Assistant → "Select Your Country or Region" → scan with iPhone. (30-day provisional release applies.)
- **In-use Macs without wiping:** community methods (`add2abm` script / temporary-volume) — reversible but third-party; back up + test first.

**Key facts:**

- A **wipe never changes ABM membership.** In-ABM devices stay and re-enroll via ADE; non-ABM devices are still non-ABM after a wipe.
- **Offboarding wipe is the ideal moment** to Configurator-scan a returned Mac into ABM → migrate the fleet at natural churn.

**ABM console (unified Apple Business portal):** **Devices → Management Services**. Jamf = 123 devices, Kandji = 66; Intune/Google/Configurator = 0. **Set Default Device Assignment → Mac = Jamf.**

**Interim plan (agreed):** for a few months, turn on the loaner and Configurator-scan devices into ABM (so they run the *real* ADE flow), while linking the reseller/Apple Customer Number so it becomes fully hands-off.

---

## 7. Zero-touch architecture (the mental model)

- **PreStage = enrollment only** — NOT per-department. You have one (plus a test one), not one per team.
- **Okta groups = people** (control app / SSO access). **Jamf Smart Groups = computers** (control what installs on the Mac). Jamf does **not** read Okta groups.
- **The bridge = the department attribute** flowing Okta → the Mac's Jamf **User & Location** record at enrollment; a Jamf dept Smart Group then keys off it. Helcim's dept Smart Groups already exist but are dormant.

---

## 8. PSSO-Sandbox PreStage build (IN PROGRESS)

Test PreStage **`PSSO-Sandbox`** scoped to a single loaner Mac (ITSP-73).

**Scoping guardrails (keep blast radius = 1 device):** PreStage Scope = loaner serial only; **"auto-assign new devices" OFF**; config profiles scoped to a **static group of just the loaner**; never "All Managed Clients."

**General options set:**

- Simplified Setup for Platform SSO **ON**, workflow method **Attended**, min macOS **26**, PSSO bundle ID `com.okta.mobile`
- **Prevent user from enabling Activation Lock: ON**
- **Make MDM Profile Mandatory: ON**, **Allow MDM Profile Removal: OFF**
- Require Authentication: OFF (Simplified Setup handles the Okta sign-in)
- Enrollment Customization: None (can't be used with PSSO)
- Setup Assistant Options: hide the consumer panes (click **All**, then **un-hide Touch ID / Face ID**); enforce **FileVault via policy** (with key escrow), not the pane

**Current status:** shows **"1 Error"** on General because the **SSO-extension (SSOe) profile isn't created/attached yet** (the Attended workflow requires it).

### Config profiles to create (all **Level = Computer**, scope = loaner static group)

**A. SCEP (device cert / management attestation)** — **Okta side:** the four values are already generated under **Okta → Security → Device Integrations → Device Access** (your active *Dynamic SCEP URL – Generic* config): SCEP URL, Challenge URL, Username (`okta-PYGYN4`), Password.
**Jamf side (2026-07-08 fix):** use the **SCEP payload** (search `SCEP` in the payload picker) — **NOT** the *Certificate* payload's *Upload* option. Dynamic SCEP has nothing to upload: the Mac generates its own key and fetches the cert from the SCEP URL at enrollment. Fill: URL = SCEP URL; challenge type = **Dynamic – Microsoft CA**; Challenge URL; Username/Password; Subject `CN=$COMPUTERNAME ODA $UDID`; Key Size **2048**; check *Use as digital signature*; uncheck *Allow export from keychain*; redistribution ~30 days before expiry (Okta can't auto-renew).

**B. Okta Platform SSO – SSO Extension** — payload **Single Sign-On Extensions**:

| Field | Value |
|---|---|
| Extension Identifier | `com.okta.mobile.auth-service-extension` |
| Team Identifier | `B7F62B65BN` |
| Sign-on Type | `Credential` |
| Realm | `Okta Device` (exact case) |
| Host / URL | `https://helcim.okta.com` |
| Auth method | Password (credential sync) **or** Secure Enclave key (phishing-resistant) — pick one |

> **Watch-point (2026-07-08):** the values above (`Credential` + Realm `Okta Device`) are the Helcim playbook standard — kept as-is. Public Okta+Jamf PSSO *password-sync* walkthroughs instead use Sign-on Type `Redirect` + nonce/token URLs (`…/device-access/api/v1/nonce`, `…/oauth2/v1/token`) + a PasswordSync **Client ID** — a different PSSO mode. If the loaner test stalls at the SSO-extension step, revisit this against the live tenant before changing anything else.

**C. Associated Domains** — app `com.okta.mobile`, domain `authsrv:helcim.okta.com`.

### Then

1. Attach **SSOe + SCEP (+ Associated Domains)** under PreStage → **Configuration Profiles** → clears the "1 Error".
2. **Enrollment Packages** → add **Okta Verify 9.52+**.
3. **Scope** → loaner serial only.
4. **Wipe loaner → test:** Setup Assistant → Okta sign-in → JIT local account → TouchID. Then set the loaner's **Department** (pretend) → confirm the Jamf dept Smart Group picks it up and scoped apps deploy.

---

## 9. ▶ RESUME POINT (updated 2026-07-10)

**Loaner:** MacBook Pro 14" M5 Pro, serial **C7RQFYWHYG** ("TL1"). **Test user:** Sue Doe `sdoe@helcim.com` (password set, YubiKey enrolled, "Platform Single Sign-On for macOS" app assigned).

### ✅ Proven working
- **SCEP** device cert issues from Okta CA and installs (CN `…ODA <UDID>`, Active/Issued). Jamf **SCEP payload** (not Certificate/Upload); challenge **Dynamic – Microsoft CA**; key 2048; Use as digital signature ON, Allow export OFF.
- **PSSO config loads on-device** (`app-sso platform -s` returns a config; log shows `success = YES`) — but **only once Okta Verify (9.65) is installed AND launched**. The SSO extension registers when the app runs; a pushed-but-never-opened Okta Verify = missing extension = `null` / `-1000 "no extension"`.
- **Credential-vs-Redirect: SETTLED.** PSSO password sync = **Sign-on Type `Redirect`** + URLs `https://helcim.okta.com/device-access/api/v1/nonce` and `…/oauth2/v1/token` + **"Use Platform SSO" ON** + Auth Method **Password**. (Credential+Realm `Okta Device` was the *device-trust* extension — wrong for password sync.)
- Also in PSSO-Extension: **Associated Domains** (App `com.okta.mobile`, domain `authsrv:helcim.okta.com`) + **Application & Custom Settings** two domains (`com.okta.mobile`, `com.okta.mobile.auth-service-extension`) via the two plists (Client ID `0oa1w2y9e0jWfdw701d8`, ProtocolVersion 2.0).
- A separate **System Extensions allowlist profile** (Allowed Team ID `B7F62B65BN`) is deployed so the extension auto-approves.

### ✅ Zero-touch chain (all resolved — hard-won)
1. Loaner was assigned to **Kandji** in ABM → reassign to **Jamf MDM Server** (ABM → device → Assign Device Management → Jamf).
2. Jamf's **default PreStage ("Jamf Pro Enrollment") auto-assign** kept re-grabbing the device → turned its auto-assign **OFF**, released the device, then assigned the serial to **PSSO-Sandbox**. Must read **"Assigned"** (not "Pending Sync") before wiping.
3. **Okta Verify must be a classic Enrollment Package on PSSO-Sandbox, Distribution Point = Cloud Distribution Point (Jamf Cloud).** The Jamf **App Installer** version installs post-login — too late for Setup Assistant. Uploaded `OktaVerify-9.65.2` as a package.

### ▶ CURRENT BLOCKER — START HERE
Simplified Setup now **triggers** at Setup Assistant (Remote Management appears, PSSO validates), but rejects the profile:
> **"Platform SSO configuration profile is invalid. (PlatformSSO:UseSharedDeviceKeys must be 'true')"**

**Fix:** PSSO-Extension → Single Sign-On Extensions → **Platform SSO** → **Use Shared Device Keys = Enable**. Recommended too: **User Mapping** → AccountName `macOSAccountUsername`, FullName `macOSAccountFullName`. Leave Create-New-User-at-Login / IdP Authorization / Login Frequency OFF. **Save → re-wipe (or retry Enroll).**

If a *different* `must be…` error appears next, it names the exact field — fix that one, retry (same pattern).

### After it enrolls
Okta sign-in at Setup Assistant → **Sue Doe + YubiKey** → local account created from Okta → Touch ID → verify: SCEP cert in System keychain, PSSO registered, and changing Sue Doe's Okta password syncs to the Mac login.

### Interim fallback (if zero-touch stays stuck → Jamf ticket)
Core PSSO works without Simplified Setup: let it create a local account → log in → the Platform SSO **Register** prompt (works now the extension loads) → Sue Doe + YubiKey → password sync. Simplified Setup's account-creation is the finicky *convenience* layer; open a **Jamf support ticket** for it (they can inspect live ADE + enrollment logs).

---

## 10. Open items / to confirm

- **Kandji** — what are the 66 devices for? (Affects default MDM assignment + zero-touch target.)
- **HiBob vs BambooHR** — which is the real HR source of truth in Okta?
- **Licensing** — confirm Okta **Lifecycle Management** + **Okta Workflows** entitlements.
- **Move offboarding automation** off Neil's personal account → dedicated service account.
- **Argo CD OIDC loop** — fix token refresh (cuts ~⅓ of log noise).
- **Group rules** — migrate from `user.title` to `user.department`.
- **Certent / Lingo** — confirm SCIM support vs SAML-only.
- **PSSO SSO-ext type** — ✅ RESOLVED (2026-07-10): password sync = **`Redirect` + nonce/token URLs + Use Platform SSO ON**. Credential+Realm was the device-trust extension. Playbook/appendix values below are stale for PSSO — trust §9.
- **"Pilot - macOS Pass Sync + Verify" enrollment policy** — assigned to **Everyone** (org-wide, priority 3, above Default). Likely a migration artifact that became the de-facto MFA standard. Confirm intent; **do NOT remove "Everyone" without first checking the Default policy still enforces the MFA baseline**, or you downgrade MFA org-wide.
- **Okta/Jamf docs are network-blocked** — `help.okta.com` and `learn.jamf.com` are blocked in-browser on Helcim's network; use web-search summaries / third-party writeups (IAMSE, Kandji, Addigy) instead of fetching the official docs.

---

## Appendix — exact values reference

| Item | Value |
|---|---|
| Okta Verify / PSSO app bundle ID | `com.okta.mobile` |
| SSO extension identifier | `com.okta.mobile.auth-service-extension` |
| Okta Verify Team ID | `B7F62B65BN` |
| PSSO SSO-ext Sign-on Type | `Credential` |
| PSSO SSO-ext Realm | `Okta Device` (case-sensitive) |
| Okta org URL | `https://helcim.okta.com` |
| Associated domain entry | `authsrv:helcim.okta.com` |
| Min macOS for Simplified Setup | 26.0 |
| Okta Verify min version | 9.52+ |
| Jira SRED field | required Yes/No on create (use **No** for ops work) |

*Pull the SCEP URL/challenge and any org-specific values from the live Okta Device Access setup; product identifiers can change between releases.*
