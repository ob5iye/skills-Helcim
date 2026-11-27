# Tools (Swift, macOS-native, no dependencies)

## `psso-setpass.sh` — THE onboarding password tool (bash)

Sets an Okta user's PSSO handover password with must-change OFF, then **proves it with a live authn** (clears the PASSWORD_EXPIRED trap if found). Token auto-revokes after 30 days idle — recreate in console, then update wherever it lives.

**Token resolution order (2026-11-27):** macOS Keychain (`okta-psso-onboarding`, via `--set-token`) → **1Password `op://Employee/okta-psso-token/credential`** (fallback; override the ref with `OP_TOKEN_REF=...`). A stored header prefix `Authorization: SSWS ` is stripped automatically, but store the **raw token** anyway. With the token in 1Password, the script works on ANY laptop — only requirement is the 1Password CLI signed in, no per-machine `--set-token`.

**Onboarding one-liner (2026-11-27):** 1Password item `op://Employee/Okta-Zero-touch` holds the per-user `username` + `password` fields (edited per onboarding, pulled straight into the call):
```bash
psso-setpass.sh "$(op read 'op://Employee/Okta-Zero-touch/username')" \
                "$(op read 'op://Employee/Okta-Zero-touch/password')"
```
Success = `OK: password set ... verified by live authn`.

⚠️ Retired: the old Notes "Zero touch - secret reference" snippet — two fatal bugs (no line-continuation backslashes → zsh `command not found: -H`; plus the double `SSWS` prefix). Do not resurrect it.

## Swift utilities

Run: `swift <script>.swift <args>`

| Script | Purpose |
|---|---|
| `extract_frames.swift <video> <outdir> [interval_s]` | Pull frames from screen recordings (.mov) for reviewing enrollments/tests |
| `pdf_text.swift <file.pdf>` | Extract all text from a PDF page by page |
| `pdf_page.swift <file.pdf> <page#> <out.png>` | Render one PDF page to PNG (for PDFs with image-only pages) |
| `sample_colors.swift <image>...` | Sample hex colors at grid points of PNGs (used to extract brand palette) |
| `gen_brand*.swift` | Generate Okta background gradients (diagonal family gradients, radial glow). Edit hexes/paths at top |
