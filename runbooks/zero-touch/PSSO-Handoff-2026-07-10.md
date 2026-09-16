# ▶ START HERE — PSSO Handoff (2026-07-10)

**For:** the next Claude (Abdi is on a different desktop tomorrow).
**Context that does NOT travel:** the previous chat and that machine's Claude memory. **This OKTA folder is the source of truth** — read it.

## What Abdi is doing
Standing up **Okta Platform SSO / Desktop Password Sync** on macOS via **Jamf Pro**, tested on one loaner (**C7RQFYWHYG**, "TL1") with test user **Sue Doe `sdoe@helcim.com`** (YubiKey). Goal: zero-touch — wipe → Setup Assistant → sign in with Okta → local account created + password synced.

## Read these first (in this folder)
1. `Helcim-Okta-Working-Notes-2026-07-05.md` — the full runbook. **§9 = live resume point** (proven-working list, the resolved zero-touch chain, and the current blocker).
2. `okta-psso-okta-mobile.plist` + `okta-psso-auth-service-extension.plist` — the two managed-app-config plists (Client ID `0oa1w2y9e0jWfdw701d8` already filled).
3. `Okta-PlatformSSO-Jamf-Checklist.md` — clean build checklist.
4. Skill `helcim-psso-playbook` (if installed) — procedures + hard-won gotchas.

## THE one action to do next
Simplified Setup now triggers at Setup Assistant but the profile is rejected:
> "Platform SSO configuration profile is invalid. **(PlatformSSO:UseSharedDeviceKeys must be 'true')**"

**Fix:** Jamf → Configuration Profiles → **PSSO-Extension → Single Sign-On Extensions → Platform SSO** → set **Use Shared Device Keys = Enable** (recommended also: **User Mapping** → AccountName `macOSAccountUsername`, FullName `macOSAccountFullName`). **Save → re-wipe the loaner (or retry Enroll).**
If a different `…must be…` validation error appears, it names the exact field — fix that one, retry.

## Ground rules for this environment
- **`help.okta.com` and `learn.jamf.com` are network-blocked** on Helcim's network (browser + WebFetch return shells/blocks). Use **web-search summaries** and third-party writeups (IAMSE, Kandji, Addigy), not the official docs directly.
- Abdi wants **concise, direct, step-by-step** guidance and works hands-on in the consoles, asking "what next" per screen.
- To force a Jamf config-profile re-push: **exclude device from scope → sync → re-target → sync** (or scope toggle).
- Jamf App Installers install **post-login** — for anything needed at Setup Assistant, use a **classic Enrollment Package** with **Cloud Distribution Point (Jamf Cloud)**.

## If zero-touch stays stuck
Core PSSO already works. Fallback to prove password sync today: create a normal local account → log in → complete the Platform SSO **Register** prompt as Sue Doe + YubiKey. Escalate the Simplified-Setup-at-Setup-Assistant piece to a **Jamf support ticket** (they can see live ADE/enrollment logs).
