# ai-skills — Setup Log & Sync Guide

Handoff doc for how this repo was created (2026-09-16), what it contains, and how machines stay in sync. Repo: `git@github.com:ob5iye/ai-skills.git` (**private**).

---

## 1. Goal

Unify all personal AI skills files (Devin `SKILL.md` skills, project memory packs, IT runbooks) into one versioned GitHub repo, live-wired into Devin on this Mac, and syncable to other machines.

## 2. Decisions made

- **Repo name:** `ai-skills`, owner `ob5iye`, visibility **Private** (docs contain internal Helcim hostnames, staff names, service-account names — no secrets, but not public material).
- **Structure model:** Repo holds *everything*; runnable skills are exposed to Devin via **symlinks** into `~/.config/devin/skills/`. (Chosen over cloning the repo *as* the skills dir, so runbooks/packs don't sit in the live folder.)
- **Directory rename:** `packs/` → `hacks/` (commit `de2a16f`).

## 3. Repo layout

```
ai-skills/
├── SETUP.md                      ← this file
├── README.md/.gitignore
├── skills/                       ← runnable Devin skills (frontmatter name+description)
│   ├── jira-configuration/SKILL.md        (merged LEGAL+OPS copies, see §7)
│   ├── helcim-psso-playbook/ (SKILL.md + Okta-LDAP-Jamf-Netskope-Runbook.md)
│   └── directmail-hubspot-integration/SKILL.md   (added from laptop #2)
├── hacks/                        ← project memory packs (inject 00-* first)
│   └── helcim-zero-touch/ (00-…08-*.md + tools/*.swift)
└── runbooks/                     ← human-readable procedures/config
    ├── zero-touch/ (PSSO handoffs, checklist, 2 Okta Verify plists)
    ├── okta-apps/ (Lingo SAML SSO)
    ├── google-workspace/ (Google Workspace Hacks + Gmail-Logs-to-BigQuery.docx)
    ├── laptop-compliance/ (Jira structure plan, ITSP)          ← from laptop #2
    └── apple-id/ (Mobile Test Account Migration .docx)          ← from laptop #2
```

**Content sources (copied, originals left in place):**
- `~/Documents/Devin/jira-configuration/` → `skills/jira-configuration/`
- `~/Claude/Projects/OKTA/helcim-psso-playbook/` → `skills/helcim-psso-playbook/`
- `~/Documents/Devin/helcim-zero-touch/` → `hacks/helcim-zero-touch/`
- `~/Claude/Projects/OKTA/*.md, *.plist` → `runbooks/zero-touch/`
- `~/Documents/Claude Skills/…` → `runbooks/okta-apps/`, `runbooks/google-workspace/`
- **`~/Documents/Claude Skills/Zero Touch` is a duplicate of `~/Claude/Projects/OKTA`** (verified identical) — one source only going forward.

**Deliberately excluded:**
- `~/Documents/Devin/slite-confluence-migration/` — working folder; contains `.env` with a **live Atlassian API token** (also flagged for rotation — it's been copied around) and a known-bad `payload-meet-the-team.json`.
- `Zero Touch/ziormO5t` (mystery zip) and `helcim-psso-playbook.skill` (empty file).

## 4. Secret scan results (done BEFORE first commit)

- `password|secret|token|api_key` patterns → only placeholders/procedure text (`$OKTA_TOKEN`, `<HandoverPassword>`, "from Okta"). ✔
- High-entropy patterns (`ATATT3x…`, `eyJ…`, `ghp_…`, `-----BEGIN`) → only real hit was the Atlassian token in the excluded `.env`. ✔
- Okta Verify plists contain only client-ID key names, no embedded certs/secrets. ✔

## 5. Machine wiring (this Mac)

- Symlinks (both verified live — Devin picked them up immediately):
  ```bash
  ~/.config/devin/skills/jira-configuration   → ~/Documents/Devin/ai-skills/skills/jira-configuration
  ~/.config/devin/skills/helcim-psso-playbook → ~/Documents/Devin/ai-skills/skills/helcim-psso-playbook
  ```
- Git identity: `Abdi Obsiye <soolizia@gmail.com>` (global).
- GitHub auth: **SSH** key `~/.ssh/id_ed25519` (ed25519, no passphrase), registered on the GitHub account. HTTPS push failed (no credential helper; `brew` not installed, so no `gh`). Remote is `git@github.com:…`.
- GitHub known_hosts pinned via `ssh-keyscan`.

## 6. Daily workflow (both machines)

```bash
cd ~/Documents/Devin/ai-skills
git pull                                    # before editing
# …edit files…
git add -A && git commit -m "…" && git push
```

New skill = folder under `skills/<name>/SKILL.md` with frontmatter + one symlink:
```bash
ln -sfn "$PWD/skills/<name>" ~/.config/devin/skills/<name>
```

## 7. DONE — laptop #2 onboarded (M3 MacBook Pro, 2026-09-16)

The plan below assumed laptop #2 had its own git repo — it didn't. Reality: loose folders only,
so onboarding was clone-then-merge instead of push-then-merge. What actually happened:

1. Laptop #2's existing `~/.ssh/id_ed25519.pub` (created Mar 2025) added to GitHub as "M3"
   (Authentication Key). SSH auth verified.
2. `git clone git@github.com:ob5iye/ai-skills.git ~/Documents/Devin/ai-skills` (same path as laptop #1).
3. **Diverged copy found:** `~/Documents/Devin Skills/jira-configuration/SKILL.md` (262 lines,
   OPS space: forms/automation/board-filters) vs repo copy (77 lines, LEGAL space: workflows/
   statuses/service accounts). Complementary, not conflicting → **merged into one SKILL.md**
   (`skills/jira-configuration/`). Keep editing the repo copy only.
4. **Unique content added from laptop #2:**
   - `~/Documents/Devin Skills/directmail-hubspot-integration/` → `skills/directmail-hubspot-integration/`
   - `~/Claude/Projects/JIRA - INTUNE project/…Plan.md` → `runbooks/laptop-compliance/`
   - `~/Claude/Projects/Google Workspace hacks/Gmail-Logs-to-BigQuery-Runbook.docx` → `runbooks/google-workspace/`
   - `~/Claude/Projects/Apple ID/…Apple-First Plan.docx` → `runbooks/apple-id/`
5. Secret scan on all new text + inside docx XML: placeholders only, no tokens. ✔
6. Symlinks created on laptop #2 for all three skills (jira-configuration, helcim-psso-playbook,
   directmail-hubspot-integration) into `~/.config/devin/skills/`.
7. Legacy folder `~/Documents/Devin Skills/` renamed to `Devin Skills (MIGRATED to ai-skills — safe to delete)`.
   Delete once verified. `~/Claude/Projects/*` originals left in place.
8. **Sahan import (done 2026-09-16, same day, per user request):** `~/Claude/Projects/Sahan NHSP` →
   `sahan/grants/nhsp/`; `~/Claude/Projects/CIP` → `sahan/grants/cip-gate/`; Sahan grant masters from
   `~/Downloads` → `sahan/grants/<name>/` + `sahan/registry/`. Found two ready-made Devin skills in the
   CIP folder → promoted to `skills/sahan-rise-together-calgary/` + `skills/cip-newcomer-women-program/`
   (symlinked live). Org profile + pipeline index written at `sahan/README.md` (load-first context doc).
   **Excluded on purpose:** `~/Documents/SAHAN` (3.1 GB Syncthing photo dump; `Salwa/` is a *separate*
   org's incorporation package with PII — not Sahan's content) and banking docs (`SAHAN-XX/Sahan
   Account`, balance-confirmation letters). Duplicates removed by md5 (4× contribution record,
   3× society return, 2× incorporation cert).
9. ⚠ Laptop #2 global git identity is `@aobsiye <aobsiye@helcim.com>` (work). Set repo-local
   identity before committing from laptop #2:
   `git -C ~/Documents/Devin/ai-skills config user.name "Abdi Obsiye"` and
   `git -C ~/Documents/Devin/ai-skills config user.email "soolizia@gmail.com"`
