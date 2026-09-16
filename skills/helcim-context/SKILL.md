---
name: helcim-context
description: Use for ANY Helcim work task — Jira, Okta, Jamf, Intune, Google Workspace, HubSpot, Directmail, integrations, access requests, compliance. Points at the right skill/runbook and keeps the knowledge base current after the work.
---

# Helcim Context Router + Write-Back Rules

Work repo lives at `~/Documents/Devin/skills-Helcim/`. Route first, answer second.

## Route to the right knowledge

| Task smells like | Load/use |
|---|---|
| Jira projects, boards, workflows, forms, flows, service accounts | `/jira-configuration` skill |
| Okta Platform SSO, Jamf Pro deploys, zero-touch, Netskope | `/helcim-psso-playbook` skill + `hacks/helcim-zero-touch/` (inject `00-PROJECT-MEMORY.md` first) |
| Direct mail / HubSpot webhook integration | `/directmail-hubspot-integration` skill |
| Gmail logs, Workspace admin, Lingo SSO, laptop compliance, Apple test accounts | matching folder under `runbooks/` |

`skills-Helcim/README.md` has the full inventory if none of the above fit.

## After the work (write-back — do this without being asked)

If anything **durable** changed — a config value, a procedure that worked, a
troubleshooting fix, a new integration/credential name, a project decision — then:

1. Update the affected skill/runbook/memory-pack file (append to change-history
   sections where they exist, e.g. the jira skill).
2. Commit and push:
   ```bash
   cd ~/Documents/Devin/skills-Helcim
   git add -A && git commit -m "<what changed>" && git push
   ```
3. Tell the user it was committed and pushed.

**Do not write when**: exploratory session only, or nothing agreed/final changed.

Never commit secrets or tokens (reference as `$VAR`/placeholders; `.env` is git-ignored).
Personal/Sahan content does NOT belong in this repo — it goes in `skills-sahan`.
