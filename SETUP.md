# skills-Helcim — Setup Log & Sync Guide

Repo: `git@github.com:ob5iye/skills-Helcim.git` (**private**). Born 2026-09-16, cloned from
`ai-skills` at the domain split. Personal/Sahan content was removed here and lives in the
separate private repo **skills-sahan**. Prior history still contains the Sahan side (private
repo; cosmetic only — scrub with git filter-repo + force push if it ever needs to be handover-clean).

## What lives here

- `skills/` — work skills: `jira-configuration`, `helcim-psso-playbook`, `directmail-hubspot-integration`
- `hacks/helcim-zero-touch/` — Okta PSSO + Jamf + Netskope memory pack + Swift tools
- `runbooks/` — `zero-touch/`, `okta-apps/`, `google-workspace/`, `laptop-compliance/`, `apple-id/`

## Machines

**Both Macs** (local path convention — keep identical on every machine):

```bash
cd ~/Documents/Devin
git clone git@github.com:ob5iye/skills-Helcim.git
mkdir -p ~/.config/devin/skills
ln -sfn "$PWD/skills-Helcim/skills/jira-configuration"              ~/.config/devin/skills/jira-configuration
ln -sfn "$PWD/skills-Helcim/skills/helcim-psso-playbook"            ~/.config/devin/skills/helcim-psso-playbook
ln -sfn "$PWD/skills-Helcim/skills/directmail-hubspot-integration"  ~/.config/devin/skills/directmail-hubspot-integration
```

SSH keys for both machines are registered on the GitHub account (laptop 2 key title "M3").

## Daily workflow (both machines)

```bash
cd ~/Documents/Devin/skills-Helcim
git pull            # before editing
# …edit…
git add -A && git commit -m "…" && git push
```

New skill = `skills/<name>/SKILL.md` with frontmatter + one symlink + README bullet.

## Carry-over notes from the ai-skills era

- ⚠ **Atlassian API token rotation still pending** (2026-09): a live token sits in an excluded
  `.env` inside laptop 1's `~/Documents/Devin/slite-confluence-migration/` working folder and has
  been copied around. Rotate it, then delete the stray copies.
- Same folder also has a known-bad `payload-meet-the-team.json`. Neither file is in git (git-ignored patterns).
- Historical detail: the pre-split `ai-skills` SETUP.md documented the original secret scan and
  machine onboarding; equivalent records for both new repos live in each repo's SETUP.md.
