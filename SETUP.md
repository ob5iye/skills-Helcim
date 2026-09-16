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
│   ├── jira-configuration/SKILL.md
│   └── helcim-psso-playbook/ (SKILL.md + Okta-LDAP-Jamf-Netskope-Runbook.md)
├── hacks/                        ← project memory packs (inject 00-* first)
│   └── helcim-zero-touch/ (00-…08-*.md + tools/*.swift)
└── runbooks/                     ← human-readable procedures/config
    ├── zero-touch/ (PSSO handoffs, checklist, 2 Okta Verify plists)
    ├── okta-apps/ (Lingo SAML SSO)
    └── google-workspace/ (Google Workspace Hacks)
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

## 7. PENDING — onboard laptop #2

Laptop #2 has its **own local-only repo with unique content**. Plan: stage it on GitHub, merge here, then laptop #2 also runs only `ai-skills`.

**Run on laptop #2:**
```bash
cd ~/path/to/that-repo
git config --global user.name "Abdi Obsiye"   # if unset
git config --global user.email "soolizia@gmail.com"
git status || { git init -b main; git add -A; git commit -m "Laptop 2 notes"; }
ssh-keygen -t ed25519 -C "laptop2" -f ~/.ssh/id_ed25519 -N ""
cat ~/.ssh/id_ed25519.pub                     # add at github.com/settings/ssh/new
# Create PRIVATE repo "skills-laptop-2" at github.com/new (no README/gitignore)
git remote add origin git@github.com:ob5iye/skills-laptop-2.git
git push -u origin main
```

**Then, on this Mac (Devin-assisted):**
1. `git clone git@github.com:ob5iye/skills-laptop-2.git` into a temp folder
2. Re-scan for secrets
3. Diff vs `ai-skills`; file unique content into `skills/` / `hacks/` / `runbooks/`
4. Commit + push
5. Laptop #2: `git clone git@github.com:ob5iye/ai-skills.git`, verify content arrived, then **archive/delete its old repo folder** (never keep two editable copies)
6. Optionally delete the temporary `skills-laptop-2` GitHub repo once merge is confirmed
