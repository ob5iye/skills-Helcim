# Tools (Swift, macOS-native, no dependencies)

## `psso-setpass.sh` — THE onboarding password tool (bash)

Sets an Okta user's PSSO handover password with must-change OFF, then **proves it with a live authn** (clears the PASSWORD_EXPIRED trap if found). SSWS token lives in macOS Keychain (`okta-psso-onboarding`) via `--set-token`. Token auto-revokes after 30 days idle — recreate in console, re-run `--set-token`.

**1Password-assisted onboarding one-liner (2026-11-27):** the 1Password item `op://Employee/Okta-Zero-touch` holds the per-user `username` + `password` fields (edited per onboarding); the token is NOT stored in 1Password:
```bash
psso-setpass.sh "$(op read 'op://Employee/Okta-Zero-touch/username')" \
                "$(op read 'op://Employee/Okta-Zero-touch/password')"
```
⚠️ Replaces the old Notes "Zero touch - secret reference" snippet, which had two fatal bugs: no line-continuation backslashes (zsh splits the curl → `command not found: -H`) and a 1Password credential field storing `Authorization: SSWS <token>` while the snippet also prepended `SSWS ` (double prefix → E0000011 even with a live token). If the token is ever stored in 1Password, the field must contain the **raw token only**.

## Swift utilities

Run: `swift <script>.swift <args>`

| Script | Purpose |
|---|---|
| `extract_frames.swift <video> <outdir> [interval_s]` | Pull frames from screen recordings (.mov) for reviewing enrollments/tests |
| `pdf_text.swift <file.pdf>` | Extract all text from a PDF page by page |
| `pdf_page.swift <file.pdf> <page#> <out.png>` | Render one PDF page to PNG (for PDFs with image-only pages) |
| `sample_colors.swift <image>...` | Sample hex colors at grid points of PNGs (used to extract brand palette) |
| `gen_brand*.swift` | Generate Okta background gradients (diagonal family gradients, radial glow). Edit hexes/paths at top |
