# Microsoft Intune (Windows fleet) — knowledge base

Windows/Intune side of the Helcim fleet. Macs live in Jamf (`zero-touch/`,
`hacks/helcim-zero-touch/`); Windows lives here. Intune admin center:
`intune.microsoft.com`.

## Environment facts (verified 2026-10-07)

**Compliance policies (Windows 10 and later):**

| Policy | Purpose | Key settings | Assignment |
|---|---|---|---|
| Default Device Compliance Policy | Intune built-in baseline | — | all |
| Default Windows 10 Compliance Policy (All devices) | Main baseline | BitLocker, Secure Boot, Code Integrity, encryption, firewall required; password: block simple, at-least-alphanumeric, **2 non-alphanumeric chars**, **min 12**, history **5**, expiry 41 days, idle lock 15 min | `Device\Production`; mark noncompliant **immediately** |
| Screen Lock Compliance Policy | **Vanta task — do not delete** (audit evidence) | password-to-unlock Required, inactivity 15 min only | devices |

Compliance policies are **measurement-only** — they never configure anything.
Overlap between them is fine as long as measured values don't contradict.

**Configuration profiles that touch DeviceLock CSP (the password knobs):**

- `Device Lock` (Settings catalog, created 2025-06-25) — **sole owner of device
  password enforcement going forward.** Device Password Enabled, no simple
  passwords, "Password/Numeric PIN/Alphanumeric PIN required", expiry 0,
  history **5**, max failed attempts 10, inactivity 15, min length 12.
- `Password Restrictions` (Device restrictions, created 2023-04-05) — **password
  category stripped 2026-10-07** to end the CSP conflict. Kept: Windows Hello
  device authentication Allow + Preferred Microsoft Entra tenant domain
  `helcim.com`. Edge Legacy (v45) section is dead-weight junk.
- `Hello Profile` (Identity protection, 2021) — Windows Hello PIN complexity;
  third place a password/PIN collision can originate from.

## Case file: "You need a more complex type of password" (2026-10-07)

**Symptom:** Company Portal → Check access → nag "you need a more complex type
of password"; device shown Non-compliant even though the user's password met
every rule.

**Root cause:** NOT the user's password. The compliance policy
`Default Windows 10 Compliance Policy` showed state **Conflict** (not "Not
compliant") on exactly one setting: `Require password type`. Cause: two
configuration profiles owned the same DeviceLock CSP nodes with different
values — old `Password Restrictions` (2023) vs new `Device Lock` settings
catalog (2025), most visibly password history 6 vs 4. Intune pinned the blame
on the newer settings-catalog profile: `Device Lock` fleet status was
**Succeeded 0 / Conflict 36** — the fix was fleet-wide, not per-device.
With "mark noncompliant immediately", the stuck Conflict instantly flagged
devices noncompliant, and Company Portal surfaced it as the generic
password-complexity nag.

**Fix:**
1. `Device Lock` profile: set `Device Password History` 4 → 5 (now matches the
   compliance policy). Nothing else changed.
2. `Password Restrictions` profile → Password category → set to Not configured:
   Require, min length, sign-in failures, inactivity, prevent-reuse, simple
   passwords. Kept Hello auth + preferred tenant domain (no overlap).

**Verify:** device Sync (Settings → Access work or school → Info → Sync) →
Company Portal → Check access → compliance flips Conflict → Compliant;
`Device Lock` conflict count drains 36 → 0 as machines check in. Spot-check a
couple of Production devices before calling it done.

## Hard-won rules

- **ONE owner per CSP area.** Never let a Device restrictions template profile
  and a Settings catalog profile both configure DeviceLock (or any same-node
  area). Conflict reporting blames the newer settings-catalog profile while the
  old template profile looks "Succeeded".
- **Conflict ≠ Not compliant.** Intune refuses to evaluate a conflicted
  setting; with immediate-marking the device goes noncompliant and the
  user-facing remediation text is misleading generic advice.
- **Fastest diagnostic:** device page → Device compliance → *click the policy
  name* → per-setting view shows the exact Conflict/NotApplicable row. Then
  device page → Device configuration → click Conflict profiles for the
  colliding pair.
- Password evaluations (min length, complexity, history) measure the **local
  sign-in credential**. If a password was changed via web/Okta while the
  device was offline, sign in once with the new password on the device before
  re-running Check access.
- **Never paste live passwords in AI chats/tickets** — treat as exposed and
  rotate. (Happened during this incident too.)

## Related

- `runbooks/laptop-compliance/` — Jira structure plan (ITSP epics)
- `runbooks/zero-touch/` + `hacks/helcim-zero-touch/` — Mac side (Jamf, PSSO)
