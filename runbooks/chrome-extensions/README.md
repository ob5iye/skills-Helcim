# Helcim Chrome Extensions (Chrome Web Store)

## Publisher account
- **Account:** `fuzz@helcim.com` (Helcim Fuzz service account)
- **Dashboard:** https://chrome.google.com/webstore/devconsole (publisher: `fuzz`)
- Extension limit on this publisher: 3 new items.

## Published items (both private — Helcim domain only)

| Item | ID | Created | Notes |
|---|---|---|---|
| **Autogenerating EDD Note Builder** | `lbmamfaknapdjdbgkcdllmlemjfohkkb` | Mar 6, 2023 | Original EDD tool for Trust & Safety, ~11 users. MV3, no permissions. |
| **Credit Risk EDD Note Builder** | (see dashboard) | Dec 13, 2024 | Separate item, v1.0.0, ~3 users. Newer variant for Credit Risk team. |

They are **separate store items** — uploading a package to the wrong one replaces
that item's code and renames its listing. The zip's `manifest.json` `name` field
tells you which item the source belongs to.

## How to push an update (verified 2026-09-29)

1. Get the source zip. Google Drive folder downloads nest everything inside a
   top-level folder — **Chrome Web Store requires `manifest.json` at the zip root**,
   so repackage:
   ```bash
   unzip -q "downloaded.zip" -d /tmp/ext && cd "/tmp/ext/<folder>"
   zip -qr ~/Downloads/upload.zip . -x "README.md" ".*"
   ```
2. Bump `"version"` in `manifest.json` — it must be **strictly greater** than the
   currently published version or the upload is rejected.
3. Dashboard → item → **Package → Upload new package** → confirm Draft shows the
   new version next to Published.
4. **Submit for review** (top right), leave auto-publish on.
5. Private domain + no permissions = fast review. Users update automatically
   within hours, or force via `chrome://extensions` → Developer mode → **Update**.

## Gotchas
- If Submit is blocked, fill the **Privacy tab**: single-purpose description,
  data-usage certification ("does not collect user data" — these run locally).
- "Verified CRX uploads" opt-in: skipped for now (adds signing friction, not
  needed for private domain items).
- Don't confuse the CWS dev console with Google Play — same Google account,
  different consoles.

## Change history
- **2026-09-29:** Autogenerating EDD Note Builder updated 0.0.0.1 → 0.0.2
  (source edited Sept 24–25, 2026; repackaged from Drive export, submitted for review).
