# Laptop Compliance Automation — Proposed Jira Structure (PREVIEW)

**Initiative (Brett):** Develop the processes and configure the technology to allow IT Services to keep laptops in compliance — kept up-to-date, with hardening in place, and required applications. Provision laptops consistently with the right base apps and hardening.

**This pass covers (per Abdi):** Intune update push (Windows), Jamf update push (macOS), application updates (both OS), reboot policies (both OS), and a **research-stage** zero-touch provisioning workstream (Okta + MacBooks).

**Status:** CREATED in Jira on 2026-06-21 — 5 epics + 29 tasks in project ITSP, all tagged `laptop-compliance`.

**Created issues:**

- Epic 1 — Intune: `ITSP-43` (tasks `ITSP-48`–`ITSP-53`)
- Epic 2 — Jamf: `ITSP-44` (tasks `ITSP-54`–`ITSP-59`)
- Epic 3 — Apps: `ITSP-45` (tasks `ITSP-60`–`ITSP-65`)
- Epic 4 — Reboot: `ITSP-46` (tasks `ITSP-66`–`ITSP-70`)
- Epic 5 — Zero-touch research: `ITSP-47` (tasks `ITSP-71`–`ITSP-76`)

---

## Proposed Jira setup

- **Project:** ITSP — IT Services Projects ([board 269](https://helcim.atlassian.net/jira/software/c/projects/ITSP/boards/269))
- **Hierarchy:** Epic → Task (issue types available in ITSP: Epic, Story, Task, Sub-task, Bug)
- **Suggested label on all issues:** `laptop-compliance` (so the whole initiative is filterable as one body of work)
- **Cross-team links:** Several tasks touch Cybersecurity (CYBER) — Okta IaC, hardening baselines, PCI/secure laptops. These are flagged as "link to CYBER" rather than duplicated.
- **5 epics, 29 tasks.** Each task below includes a one-line acceptance criterion (AC) that goes into the ticket description.

---

## Epic 1 (ITSP-43) — Intune: Automate Windows OS update delivery & enforcement

**Goal:** Windows laptops automatically receive and install OS quality/feature updates on a governed cadence with enforced deadlines — no manual admin action.

**Context (2026):** "Windows Update for Business" is now **Windows Update Client Policies**; the deployment service is folded into **Windows Autopatch**. Update rings control deferral, deadline, and restart behavior; deadline = days after the device sees the update before force-install.

| # | Task | Acceptance criteria |
|---|------|---------------------|
| 1.1 | Inventory & segment the Windows fleet into deployment rings (Pilot / Early / Broad) via Entra ID dynamic groups | 3 ring groups exist; every enrolled Windows device lands in exactly one ring |
| 1.2 | Configure Windows Update Client Policies (update rings) per ring — deferral, deadline, grace period | Quality-update deadline defined per ring; settings deployed and visible in Intune |
| 1.3 | Decide on and (if adopted) enable Windows Autopatch for service-managed rollout cadence | Documented decision (Autopatch vs. manual rings); if adopted, devices registered and excluded from conflicting custom rings |
| 1.4 | Configure feature-update policy to pin the approved Windows version and block unwanted upgrades | Target version pinned; no device auto-jumps to an unapproved release |
| 1.5 | Build Windows update-compliance reporting (Intune reports + Datadog dashboard) | Dashboard shows % devices on latest patch / pending / failed, refreshed daily |
| 1.6 | Define deferral/exclusion process for critical-role devices (e.g., HSM / PCI laptops) | Documented exception group + approval path (linked to CYBER) |

## Epic 2 (ITSP-44) — Jamf Pro: Automate macOS OS update delivery & enforcement

**Goal:** Macs autonomously update to approved macOS versions with enforced deadlines.

**Context (2026):** Apple deprecated legacy MDM software-update commands at WWDC 2025 (removed in 2026). macOS update automation must use **DDM Managed Software Updates / Blueprints** ("Latest OS version" rolling cadence: enforcement date = posting date + delay days).

| # | Task | Acceptance criteria |
|---|------|---------------------|
| 2.1 | Confirm Jamf Pro version & fleet support DDM Managed Software Updates / Blueprints | Jamf Pro on a Blueprints-capable version; Macs supervised and on DDM-capable macOS |
| 2.2 | Migrate off legacy MDM software-update commands / OS update policies to DDM declarations | No reliance on deprecated update commands; migration plan documented |
| 2.3 | Create Managed Software Update Blueprints with rolling cadence for minor + major macOS updates | Blueprint enforces minor updates within N days of posting; deadline auto-recalculates |
| 2.4 | Segment Macs into staged update groups (Pilot / Broad) via smart groups | Staged rollout; pilot validates before broad enforcement |
| 2.5 | Configure end-user notification & deferral experience | Users get a nonintrusive countdown; update enforced at deadline |
| 2.6 | Build macOS update-compliance reporting (Jamf + Datadog) | Dashboard shows % Macs on enforced version / deferred / failed |

## Epic 3 (ITSP-45) — Application update automation (Windows + macOS)

**Goal:** Required business apps are deployed and kept patched automatically on both platforms.

**Context (2026):** Intune **Enterprise App Catalog** supports auto-update / "Update with Supersedence" (most updates available within ~24h SLO). Jamf offers App Catalog / patch policies (or Installomator) for Mac apps.

| # | Task | Acceptance criteria |
|---|------|---------------------|
| 3.1 | Define the required-application baseline per role/OS (browsers, CrowdStrike, Netskope, Okta Verify, productivity, VPN, etc.) | Documented app list with an owner per app, mapped to Windows/Mac |
| 3.2 | (Windows) Deploy core apps via Intune Enterprise App Catalog with auto-update / supersedence | Catalog apps install on assignment and auto-update within SLO |
| 3.3 | (Windows) Define deploy + update strategy for non-catalog/custom apps (Win32 / PowerShell installers) | Each required non-catalog app has a documented deploy + update method |
| 3.4 | (macOS) Configure Jamf App Catalog / patch policies (or Installomator) for required Mac apps | Mac apps auto-patch to latest within the defined window |
| 3.5 | Establish app-update reporting & failure alerting (Datadog / n8n) | Dashboard of app versions; n8n/alert fires on stuck or failed updates |
| 3.6 | Define new-app intake & vetting process | Documented request → security review (CYBER) → packaging → deploy flow |

## Epic 4 (ITSP-46) — Reboot / restart policy (both OS)

**Goal:** Updates actually complete via enforced, predictable reboots with minimal user disruption.

**Context (2026):** Intune uses deadline + grace period (users prompted up to 7 days, then forced; grace = days after install before reboot is forced) and active hours. Jamf DDM handles reboot notifications/enforcement at the declared deadline.

| # | Task | Acceptance criteria |
|---|------|---------------------|
| 4.1 | Define the org reboot standard: max uptime, maintenance window, grace period, notification cadence, active hours | Written standard approved by IT Services + Cyber |
| 4.2 | (Windows) Configure restart / grace-period / active-hours settings in update rings | Forced reboot after grace; active hours respected |
| 4.3 | (macOS) Configure DDM enforcement deadline + user deferral/notification for reboots | Macs reboot to apply updates by deadline with a countdown UX |
| 4.4 | Configure reboot behavior for app updates that require a restart | App-triggered reboots follow the same org standard |
| 4.5 | Add reboot-compliance monitoring (devices with pending reboot beyond threshold) | Datadog dashboard + alert for stale-reboot devices |

## Epic 5 (ITSP-47) — [RESEARCH] Zero-touch provisioning: Okta + macOS (Apple ADE + Platform SSO)

**Goal (research stage):** Determine how to deliver true zero-touch Mac provisioning where a new Mac is identity-aware from first boot via Okta. Output = findings + go/no-go recommendation + a follow-on implementation epic.

**Context (2026):** Okta **Platform SSO + Device Access** now supports simplified setup during **Apple Automated Device Enrollment (ADE) on macOS 26 Tahoe** (requires Okta Verify 9.52+). On first boot the user signs into Okta, the first local account is created from Okta attributes, and the account is registered with Platform SSO for password sync. Jamf + Okta were first to support Platform SSO.

| # | Task (Spike) | Acceptance criteria |
|---|------|---------------------|
| 5.1 | Spike: Document the current Mac provisioning flow and gaps vs. the zero-touch target | As-is flow + prioritized gap list |
| 5.2 | Spike: Validate prerequisites — Apple Business Manager / ADE tokens in Jamf, macOS 26 Tahoe baseline, Okta Verify 9.52+, Okta Device Access licensing | Prerequisite checklist with current-vs-required state |
| 5.3 | Spike: Evaluate Okta Platform SSO Simplified Setup during ADE (first local account from Okta, password sync) on a lab Mac | Documented feasibility + lab test result |
| 5.4 | Spike: Map the enrollment-time security baseline (FileVault, hardening profile, required apps, Okta Device Trust) | Documented "first-boot → compliant" sequence |
| 5.5 | Spike: Define the Okta side — device assurance/trust policies, groups, app assignment for newly provisioned devices | Okta policy design documented (links to CYBER Okta IaC work) |
| 5.6 | Decision & recommendation: go/no-go + draft the implementation epic | Written recommendation reviewed with Brett/Cyber; follow-on epic created if "go" |

---

## Suggested sequencing (phases)

1. **Phase 1 — Foundations & visibility:** Epic 1 (1.1–1.2, 1.5), Epic 2 (2.1–2.2, 2.6). Get fleet segmented, rings/blueprints in place, and reporting live first.
2. **Phase 2 — Enforce updates:** Epic 1 (1.3–1.4, 1.6), Epic 2 (2.3–2.5), Epic 4 (reboot policy). Turn on deadlines and reboots once visibility confirms readiness.
3. **Phase 3 — Apps:** Epic 3 end to end.
4. **Parallel research track:** Epic 5 spikes can run alongside Phases 1–2; its implementation epic lands later.

## Decisions needed from you / the team

- Approved target OS versions (Windows 11 release; minimum macOS) and per-ring deadline lengths.
- Windows Autopatch: adopt the service, or keep manually-managed update rings? (Task 1.3)
- Confirm the exact required-application baseline owners (Task 3.1).
- Who owns Okta-side policy design — IT Services or Cyber? (Epic 5 links to existing CYBER Okta IaC tickets.)

## Not included in this pass (flag if you want them added)

- A dedicated **Hardening / security baseline** epic (CIS/PCI configuration profiles, FileVault/BitLocker, disk encryption escrow). Currently referenced inside Epics 4–5 but could be its own epic.
- Okta → HubSpot / other-app SSO + SCIM provisioning (was the broader stretch goal beyond device zero-touch).
