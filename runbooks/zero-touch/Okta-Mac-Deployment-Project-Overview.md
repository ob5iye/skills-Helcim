# Okta + Mac Deployment — Project Overview & Status

**Last updated:** 14 Jul 2026
**Owner:** IT / Endpoint
**Platforms:** macOS · Jamf Pro · Okta

---

## Purpose

Modernize how Macs are provisioned and managed by making **Okta the identity backbone** for our Mac fleet. The end goal is that employees sign in to their Mac with their Okta account, their Okta password stays in sync with the Mac, and new Macs set themselves up with little or no manual IT effort.

---

## Status at a glance

| Phase | Description | Status |
|-------|-------------|--------|
| **1** | Zero-touch Mac setup with Okta sign-in (Platform SSO) | ✅ Completed & verified |
| **2** | Auto-populate device owner details in Jamf from Okta | 🔵 In progress |

---

## Phase 1 — Zero-Touch Mac Setup with Okta (Completed)

### Objective
A newly issued or wiped Mac should, on first boot, let the employee sign in with their Okta account, automatically create their Mac account, and use their Okta password to log in going forward — with no IT hand-holding during setup.

### What was blocking us
During first-boot setup, the automated process stalled on a system security prompt that asked for a **local administrator's credentials**. At that early point in setup, no administrator account exists yet — creating a chicken-and-egg deadlock that stopped the Mac from finishing registration on its own.

We also uncovered a related pitfall: after login, that same security prompt was mistakenly being answered with the **Okta username** instead of the **local computer account**, which caused repeated, confusing failures. Clarifying which credential belongs in which prompt was part of the fix.

### How we resolved it
We adjusted the Mac's device-security configuration so the Okta component is **allowed to use the device's security key automatically**, and reissued that configuration to devices. This removed the administrator prompt from the first-boot experience.

### Outcome (verified on a test device)
- A wiped Mac now goes **straight from Okta sign-in to automatic account creation** — fully hands-off.
- The device registers with Okta on its own.
- The employee's **Okta password syncs** to their Mac login.

**Result: zero-touch setup is working end-to-end.**

---

## Phase 2 — Auto-Populate Device Owner Details from Okta (In Progress)

### Objective
Today, when a Mac is assigned to a person, someone has to **manually type the owner's details** (name, email, department, position, phone, location) into Jamf. We want these to **fill in automatically**, with **Okta as the single source of truth**.

### Approach (overview)
Connect Jamf to Okta so an employee's profile details flow in automatically:
- **At enrollment** — the employee authenticates and their details attach to their device.
- **On demand** — existing devices can be updated by looking the owner up from Okta.

### Key considerations / prerequisites
- A **dedicated, secure service connection** between Jamf and Okta.
- **Multi-factor authentication handling** for that connection — a normal user account protected by MFA can't be used for an automated service link, so a properly scoped service account is required.
- Some fields (for example, building/room) will only fill in if that information actually lives in Okta; otherwise they stay manual.

### Status
- Integration method and prerequisites identified.
- Setup and testing not yet started.

---

## Next steps

- [ ] Stand up the secure Okta ↔ Jamf service connection (including MFA handling).
- [ ] Map the owner-detail fields to their Okta equivalents.
- [ ] Enable automatic fill during enrollment.
- [ ] Backfill existing devices via lookup.
- [ ] Pilot test and validate before rolling out fleet-wide.

---

## Key decisions & notes

- **Okta is the source of truth** for identity, sign-in, and device-owner details.
- Zero-touch Mac setup (Phase 1) is **validated** and ready to standardize across new-device provisioning.
- Phase 2 builds on the same Okta ↔ Mac foundation to remove manual data entry in Jamf.

---

*This is an overview document for project tracking. Detailed technical configuration is maintained separately in the IT runbooks.*
