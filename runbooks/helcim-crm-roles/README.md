# Helcim CRM / Admin role permission matrices

Documented permission sets for internal Helcim admin roles (internal CRM console,
not merchant-side roles). Source: screenshots of the role editor, 2026-11-27.

## Role: Cybersecurity

Broad read access for investigation/audit, identity tooling (verify, password
reset), and ticket case management. **Deliberately zero funds movement** — no
transaction processing, no refunds, no batches, no ACH.

### Helcim Commerce

| Section | Checked | Unchecked |
|---|---|---|
| Developer project access | — | Access |
| Transactions | View | Process, Void, Refund, Preauth, Capture, Settle |
| Customers | View, Modify | Create, Delete |
| Invoices | View | Create, Modify |
| Products | View | Modify, Create, Delete, Delete All |
| Recurring | View | Modify, Create, Delete |
| Subscriptions | View | Modify, Create, Delete |
| Pay Page | View | Modify, Create, Delete |
| Online Store | View | Modify |
| Customer Portal | View only (per screenshots) | — |

### Helcim Account (My Business)

| Section | Checked | Unchecked |
|---|---|---|
| Dashboard | — | View Charts |
| Merchant Account | View | Create, Modify, Deactivate |
| Bank Account | View | Modify |
| Employee | View | Create, Modify, Deactivate, Delete |
| Role | View | Create, Modify, Delete |
| Location | View | Create, Modify, Delete |
| Equipment | View | Order |
| Chargeback | — | View, Respond |
| Statement | — | View |
| Security | — | View, Restore |
| Ticket | View | — |

### CRM tabs

| Section | Checked | Unchecked |
|---|---|---|
| CRM-Tickets | View, Modify, Create | — |
| CRM-People | View, Modify, Verify, Password Reset | — |
| CRM-Leads | — | View, Modify, Create |
| CRM-Process Engines | — | View, Modify, Run |
| CRM-Equipment Processing | — | All, Discount |
| CRM-Ownership Transfer | — | View, Create, Modify |
| CRM-Jobs | — | View, Create |

### Payments

- Payments section: Access unchecked
- Credit Processing: all unchecked (Close Batch, Settle, Refund, Reverse, Super Reverse)
- ACH Processing: all unchecked (Close Batch, Settle, Reverse, Reject/Return, Update)
- Card Terminals: none granted

### Notes / rationale

- Identity work (Verify + Password Reset + CRM-People Modify) + Tickets
  Create/Modify is the core toolkit; everything else is read-only so security
  can audit and investigate without touching money.
- Not a support role: support would lack Verify/Password Reset; finance/ops
  would have Card/ACH Processing, Equipment Processing, and Ownership Transfer.
- Initial guess was "frontline merchant support" — corrected by owner to
  **Cybersecurity** (2026-11-27).

## Role: Executive (documented 2026-11-27, screenshots low-res — verify before citing)

Near-superuser with safety rails.

### Helcim Commerce
- Access, full Transactions (View/Process/Void/Refund/Preauth/Capture/Settle),
  Customers all 4, Invoices all 3, Products all 5 (incl. Delete All),
  Recurring/Subscriptions: View/Modify/Create (Delete denied), Pay Page all 4,
  Online Store + Customer Portal: View/Modify, Settings View/Modify, Reports View

### Helcim Account (My Business)
- Dashboard View Charts; Merchant Account all 4 (View/Create/Modify/Deactivate);
  Bank Account View/Modify; Employee View/Create/Modify/Deactivate (Delete looks
  denied — low-res); Role/Location/Equipment at least View

### Payments
- Access; Credit Processing: Close Batch/Settle/Refund/Reverse (**Super Reverse denied**);
  ACH: Close Batch/Settle/Reverse (Reject/Return + Update denied);
  Card Terminals: Update + Create; ACH Terminals: Update;
  Process Engines: View/Modify/Run
- **Denied:** EQ Movement Create, Decrypt (Credit/Debit/Bank), Import Card Data

### Only-in-Executive sections
- Granted: Defender Access; Boarding Event Approve/Decline/Board; Leads; Referrals;
  Risk Decisions View/Modify; Chargebacks full (Create/Modify, Process Engines,
  Financial Actions Create/Modify/View); HSSO full (Staff-Roles Create/Modify/Delete,
  Staff-Users Create/Modify/Delete, all 5 Logs views); Compliance Access + Business
  Attestation/Domains/Lead Attribution/Web Session; Growth (Email, Email Blast,
  Ad Conversion, Content, Review-Edit); Partners full (incl. Partner User
  Enable/Disable, Partner Bank Account Modify); Dashboard mgmt (Helcim
  Highlight/Image/Template, Dashboard Setting, Doodle); 1099k Access + Tax Form Actions
- Denied: Emails section (entire), Banned IP, Webhook, internal
  Settings/Business Settings, Stop Approval/Release Batch, TMS Manager Dashboard

## Cybersecurity vs Executive — key diff

| | Cybersecurity | Executive |
|---|---|---|
| Funds movement (refund/settle/batch) | none | yes (no Super Reverse) |
| Chargebacks / Financial Actions | none | full |
| HSSO staff-role/user mgmt + logs | not shown/not granted | full |
| Merchant Account Create/Modify/Deactivate | no | yes |
| Write powers beyond tickets/people | none | most of the platform |
| Design | read-only auditor | operator with safety rails |

Notable: security-ops powers (HSSO staff admin, Banned IP, Webhook) sit with the
Executive role, not Cybersecurity, in these captures.

## Requests / gaps

- **2026-11-27 — Cybersecurity needs account-lockout ability.** No literal "lock"
  exists; it maps to Deactivate/Disable actions. Minimum viable grant:
  Helcim Account → Merchant Account → Deactivate, Employee → Deactivate.
  Extended incident-response set: HSSO → Staff-Users Modify (+ logs: View Brute
  Force Logs, View Password Reset Attempt Logs), Growth → Banned IP full,
  Partners → Partner User Disable, Defender → Access. Currently ALL of these sit
  with Executive or are ungranted to Cybersecurity.

## Internal permission model (section IDs, from access analysis 2026-11-27 — partially unverified)

Sections are gated: if `section.access = 0`, sub-permissions under it are inert
(hypothesis — confirm by having a Cyber user open a CRM ticket, since
`tickets.view: 1` sits under `26.access: 0`).

Known ID → UI-panel mapping:
- Sect 1  = Helcim Commerce (customers.transactions etc.)
- Sect 6  = Risk/Defender (defenderMerchantAccount, riskIncident, event, boardingEvent)
- Sect 18 = parent of CRM + merchant-dashboard perms (merchantAccount, employee,
            crm.business, merchantDashboard.merchantAccount)
- Sect 22 = Users/staff admin (~HSSO panel: merchant.users, staff.*, logs.*)
- Sect 23 = bare gate, no sub-perms (unidentified panel — cheap to test)
- Sect 26 = CRM-Tickets; Sect 45 = Dashboard

Access-gate anomalies on Cybersecurity (grants that may be dead):
`1.customers.modify/delete` under `1.access: 0`; `26.tickets.view` under
access 0; `22.merchant.users.view` under `22.access: 0`; `45.dashboard.view`
under `45.access: 0`. CAUTION: flipping a gate activates ALL sub-grants under
it — before enabling `1.access` re-check `customers.delete` (role was edited
2026-11-27, screenshots may be stale).

Executive gap map for account lockout (Exec=1, Cyber=0):
18.merchantAccount.deactivate + .modify; merchantDashboard.merchantAccount.
deactivate + .modify; 18.employee.deactivate + .modify; 18.crm.business.modify;
22.access + 22.merchant.users.modify (+ optional logs.access/bruteForce/
passwordReset); 6.access + 6.defenderMerchantAccount.view/modify +
6.riskIncident.view/modify/create + 6.event.* + 6.boardingEvent.modify; 23.access.
Ruled out: crm.merchantAccount.haltProcessing, crm.person.* (Exec works with
them at 0), crm.business.super (Cyber HAS it, Exec doesn't — possible dead flag).

Ordered test plan (least privilege): enable group 18 first → test → crm.business
→ 22 → 6 → 23, then subtract to find minimum set. TEST DEACTIVATE ONLY ON A
SANDBOX/TEST MERCHANT — it's destructive. Auditing today's role changes needs
View Change Event Logs (behind the 22 gate) or DB access.

### Cybersecurity CRM panel — hi-res update (2026-11-27, gold-checkbox UI)

- CRM: Access ✓ (top level ON — but subsection gates like 26.access can still be 0)
- CRM-Business: View ✓; Modify ✗; View Dashboard as Super ✗; Reopen Closed
  Business ✗; Commerce Account ✗
- CRM-Addresses: View ✓ only
- CRM-Merchant Account: View ✓, Modify ✓; Duplicate ✗

Read-outs: (1) crm.merchantAccount rule-out CONFIRMED in UI (Cyber has Modify,
Exec works with it off/lower). (2) crm.business.modify=0 verified in UI — group 2
stays a live candidate. (3) DISCREPANCY: DB read had business.super=1 but
"View Dashboard as Super" is unchecked — re-pull that key, or the super flag maps
to a different label. (4) CRM-Business offers "Reopen Closed Business" but NO
close/lock checkbox — further proof lockout lives in section 18/merchantDashboard,
not CRM.
