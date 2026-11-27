# Helcim Confluence

Site: https://helcim.atlassian.net/wiki
Cloud ID: `5b0727ab-0d7a-42ea-8f77-6d56032fab31` (hostname `helcim.atlassian.net` also works as cloudId in MCP calls)

## Spaces

| Key | Name | Use for |
|---|---|---|
| `SKAI` (id `8617988`, homepage `8618121`) | Systems KB Articles [Internal] | How-to guides, SOPs, troubleshooting — end-user and Systems-team knowledge base. Default home for procedures like token renewals. |
| `ISP` (id `51740679`, homepage `51740944`) | IT Services Projects | Project tracking: retrospectives, spike/design docs. Not for how-to articles. |

## SKAI title conventions (from the space homepage)

- How-to guide → title starts with 💻 (computer emoji), e.g. `💻 GitLab Personal Access Token Renewal`
- Process document → title starts with ⭐ (star emoji)

## Atlassian MCP gotchas (learned 2026-11-27)

- **No attachment/image upload tool exists.** Pages must be created with text placeholders, then images drag-dropped manually in the UI.
- **Cannot move published pages between spaces** via `updateConfluencePage` — API rejects with "Only DRAFT pages can be moved between spaces using the Update API". Cross-space moves happen in the UI: page → ••• menu → Move.
- No delete/archive tool either — plan placement before creating pages.
- Author page bodies with `getContentFormatGuide` first; use HTML (not Confluence storage XML).

## Pages created via MCP

- **💻 GitLab Personal Access Token Renewal** (id `347177705`, SKAI, 2026-11-27) — PAT expiry walkthrough: create new token (365-day cap), find where it's used (app settings / Windows Credential Manager `git:https://gitlab.helcim.com` / CI/CD variables / script files), revoke old. Written plain-language for non-technical Windows users.
