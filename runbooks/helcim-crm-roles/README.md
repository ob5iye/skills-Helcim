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
