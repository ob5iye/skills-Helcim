# skills-Helcim

Work AI skills + knowledge base for Helcim IT work (Devin CLI / Claude).

Split out of `ai-skills` on 2026-09-16 — personal/Sahan content lives in the
separate private repo **skills-sahan**. Keep employer material in this repo only.

## Layout

| Path | What it is | Loaded by Devin? |
|---|---|---|
| `skills/<name>/SKILL.md` | Runnable Devin skills (frontmatter + instructions) | Yes — symlinked into `~/.config/devin/skills/` |
| `hacks/<name>/` | Project memory packs (numbered markdown docs, inject `00-*` first) | No — attach to sessions as context |
| `runbooks/<topic>/` | Human-readable procedures, checklists, config plists | No — reference material |

## Current contents

**Skills**
- `helcim-context` — **router**: routes any Helcim task to the right skill/runbook; writes durable learnings back and pushes
- `jira-configuration` — Helcim Jira environment: projects, workflows, statuses, forms, automation flows, boards, service accounts
- `helcim-psso-playbook` — Okta Platform SSO / Desktop Password Sync on macOS via Jamf Pro
- `directmail-hubspot-integration` — Directmail.io QR-scan webhook → HubSpot via Google Apps Script receiver (no Ops Hub Pro / Zapier)

**Hacks**
- `helcim-zero-touch` — 9-file Okta PSSO + Jamf + Netskope master archive (inject `00-PROJECT-MEMORY.md` first) + Swift tools

**Runbooks**
- `zero-touch/` — PSSO handoffs, deployment procedure, checklists, Okta Verify plists
- `okta-apps/` — Lingo SAML SSO integration
- `google-workspace/` — Google Workspace hacks + Gmail-Logs-to-BigQuery runbook (.docx)
- `laptop-compliance/` — Jira structure plan (5 epics/29 tasks, ITSP)
- `apple-id/` — Mobile test account migration, Apple-first plan (.docx)

## Wiring skills into Devin (symlinks)

```bash
mkdir -p ~/.config/devin/skills
ln -sfn "$PWD/skills/helcim-context"                  ~/.config/devin/skills/helcim-context
ln -sfn "$PWD/skills/jira-configuration"              ~/.config/devin/skills/jira-configuration
ln -sfn "$PWD/skills/helcim-psso-playbook"            ~/.config/devin/skills/helcim-psso-playbook
ln -sfn "$PWD/skills/directmail-hubspot-integration"  ~/.config/devin/skills/directmail-hubspot-integration
```

Devin follows symlinks, so `git pull` = updated skills everywhere. Adding a new skill = new folder under `skills/` + one more symlink line above.

## House rules

- **No secrets, ever.** Tokens live in `.env` files (git-ignored) or 1Password. Reference them as `$VAR`/placeholders in docs.
- **No personal/Sahan content** — that lives in `skills-sahan`. This repo is employer-related material; keep it clean so it can be shared/handover-ready if ever needed.
- Skills get frontmatter `name` + `description` so Devin can auto-invoke them.
- Memory packs stay numbered `00- … 08-` with `00` as the inject-first index.
