# Elavon Partner Space — Jira Guest Access Plan

**Status: PREP ONLY — nothing created in Jira yet.**
Miranda's exact position (Oct 7, 2026): make an "Elavon" space specifically for the
partner so they can collab on open items; it's a discussion point with Elavon this
week — execute this plan only after her go-ahead.

## Context / why

- Miranda Russell (mrussell@helcim.com, accountId `5da741291a43fe0ddbb470a0`),
  Operations / Card Brands, asked whether Jira spaces can be shared externally
  (their Asana precedent was a dedicated "Michelin" space).
- **Yes — Atlassian now has native free guest access in Jira** (this did not exist
  in the Asana era; the old way was paid seats + permission-scheme surgery).
- Partner: **Elavon** (acquirer; existing relationship via OPS form 1325, the
  Elavon Card Scheme Merchant Registration flow).
- **Decision: dedicated partner space with Elavon as guests — NOT guests in OPS.**
  Guest visibility = the entire space, and OPS contains merchant DBA names, MIDs,
  card-scheme registration PDFs, other vendor epics, and equipment tickets. There
  is no per-issue hiding from guests (issue-security-level retrofit = fragile).

## Atlassian guest access facts (verified 2026-10-07)

- **Free: up to 5 guests per paid Jira user.** Our seat count makes the quota a
  non-issue. Guests do not consume licenses.
- **Standard/Premium/Enterprise plans only** — verify by opening the Invite dialog
  and checking the **Guest** role appears (plan check happens implicitly there).
- **One space per guest, per site, ever.** Guests see nothing outside that space —
  no other spaces, dashboards, Goals, or directory. Our open
  "any logged-in user" permission schemes (Default software scheme etc.) do NOT
  leak to guests — the guest role is fenced by design.
- Guests show a visible **Guest lozenge** everywhere; no global permissions.
- Guests **must be external** — no `@helcim.com` addresses, and current/former
  paid users can't be converted to guests.
- Two-step setup: **(1) site admin invites** via ⚙️ → User management → Invite
  users → Roles dropdown → **Guest**; **(2) space admin adds** the guest to the
  space (only possible after the guest accepts and joins the site).
- Inside their space, admins control guest powers via the guest role — view /
  create / edit / transition / comment / attach are grantable; guests can never
  administer, manage sprints, edit workflows.
- Docs: support.atlassian.com/jira-cloud-administration/docs/manage-guest-access-in-jira/
  and .../guest-permissions-in-jira/

## What to collect from Miranda before starting

- [ ] Outcome of the Elavon discussion (go / no-go)
- [ ] Elavon contact list: names + **corporate** emails
- [ ] Access review/end date for the engagement (set this at invite time)
- [ ] Which internal Helcim people join the space (Miranda + card-brands folks)
- [ ] Miranda's confirmation on data hygiene rule below (no merchant-sensitive
      content beyond what Helcim would normally share with Elavon)

## Setup procedure (all UI, Jira admin)

1. **Plan check.** ⚙️ → User management → Invite users → confirm **Guest** exists
   in the Roles dropdown. Note the plan tier discovered.
2. **Create the space** (Plan A):
   - **Team-managed, Private access**, name `Elavon`, key **`ELV`**
     (verified free 2026-10-07 — no project matches "elav"; fallback key `ELVN`).
   - Team-managed chosen deliberately: fully self-contained config, zero shared
     scheme/screen/workflow risk, guests fully supported. Anyone can create it;
     recommend site admin creates and adds Miranda as space admin.
   - Plan B if OPS-style parity is preferred instead: company-managed space with
     simplified workflow reusing existing global statuses (Backlog / In Progress /
     Done). Either works with the board step below.
3. **Invite the Elavon guests (site level).** ⚙️ → User management → Invite users
   → Elavon email → Apps tab → helcim.atlassian.net → Roles → **Guest**. Repeat
   per person. They accept + sign in with an Atlassian account on their Elavon email.
4. **Add guests to the ELV space (space level)** — only after each has accepted:
   Space settings → Access/Manage access → Add people → pick the guest (Guest role).
5. **Add internal members** (Miranda as space admin + named card-brands staff).
   Note for Miranda: once she's space admin she can add/remove *already-invited*
   guests herself; only the site-level invite needs IT.
6. **Extend Miranda's Card Brands board** so partner items land in her existing
   view (this is the step that makes it attractive for her side):
   - Saved filter **"Operations Card Brand Board Filter"**:
     `"Team[Team]" IS EMPTY AND project = OPS ORDER BY created DESC`
     → change to `"Team[Team]" IS EMPTY AND project in (OPS, ELV) ORDER BY created DESC`
     (board → ⋯ → Configure board → General → Edit filter — needs board/filter owner
     or admin; Miranda owns this board).
   - Then Configure board → Columns: drag ELV's statuses from the Unmapped panel
     into the matching columns (`IN PROGRESS / BACKLOG / WAITING ON… / DONE`) —
     unmapped statuses make items invisible on the board.
7. **Post a short welcome note** as the first ELV item for the Elavon contacts
   (how to create/comment, who to @mention).

## Security checklist (do not skip)

- Guests are **non-managed external Atlassian accounts** — outside Okta, outside
  the HiBob lifecycle. Offboarding is a manual Atlassian action; no automatic
  cleanup. Record every guest in the registry table below.
- **2FA:** check admin.atlassian.com → Security → Authentication policies whether
  our Guard tier can enforce/require 2FA for non-managed accounts; apply if
  possible and record the outcome here.
- **Data hygiene rule (agree with Miranda up front):** only Elavon-shareable work
  goes in ELV. Merchant registrations (form 1325 output: DBA names, MIDs,
  registration PDFs) stay in OPS. Anything placed in ELV — items, comments,
  attachments — is visible to all guests.
- Cross-links between OPS and ELV items are created by **internal users only**
  (guests can only link within their own space) — which is the direction of
  control we want anyway.
- Review guest list **quarterly** and at engagement end; remove immediately when
  the relationship ends or a contact leaves Elavon.

### Guest registry (fill at execution)

| Name | Email | Invited | Accepted | Removed |
|------|-------|---------|----------|---------|
| _tbd_ | _tbd_ | | | |

## Verification (before telling Miranda it's ready)

- Sign-in check with a guest account: Spaces list shows **only** ELV; Guest
  lozenge present.
- Guest hits `https://helcim.atlassian.net/browse/OPS-1` → permission error
  (expected; proves the fence).
- Create one test ELV item as an internal user → appears in the correct column
  on Miranda's Card Brands board (proves filter + column mapping). Delete the
  test item after (deletion = user does it, destructively, in the UI).
- Guest creates/comments on an ELV item (proves collaboration works for them).

## Rollback / removal

- Remove guest from the space (Space settings → Access), then suspend/remove the
  guest at site level (⚙️ → User management).
- Revert the board filter JQL to `project = OPS`.
- Archive the space if the engagement ends (Space settings → Archive; reversible).

## Gotchas for future partner spaces

- One space per guest — second space for the same contact = paid seat path.
- Guests can't be JSM agents and can't be added to service projects as agents;
  partner collaboration lives in software/business spaces like this one.
- Don't burn a guest's one space on OPS or any other internal space.
- If the pattern repeats for other partners (Curve Dental, Boulevard, …), copy
  this file — one dedicated space per partner.
- Rovo/automation flows: none in scope for ELV initially; remember flow runs count
  toward allocations from 2026-12-03 if we add any later.

## After execution (write-back)

- Fill the guest registry above; append outcomes + actual plan tier + Guard 2FA
  result to this file.
- Add a change-history entry in `SKILL.md` (this folder) with what was created.
- Commit + push (see repo root README house rules).
