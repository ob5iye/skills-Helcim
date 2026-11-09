---
name: twilio-extension-assign
description: Assign a phone extension to a Twilio Flex worker (or remove one) and sync the "Twillio extensions" Google Sheet. Use whenever the user names a person to give/take a Twilio extension, e.g. "assign ext to X" or "remove extension from X".
---

# Twilio Extension Assign — Helcim

Source of truth: Twilio worker `attributes.ext` (string), workspace **Flex Task Assignment**.
Tracker: Google Sheet "Twillio extensions", tab `extensions`, one row per number 1135–1413
(row for ext N = sheet row `N - 1133`; header at row 1):
https://docs.google.com/spreadsheets/d/150TZ_oQgUc1OdTbTtuDEHxJWDoZ6CuajMX_BJVOhCkQ/edit

## Preconditions

- Twilio creds in `~/Documents/Devin/skills-Helcim/.env` (`TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN`) — never print or commit them.
- Listing/export script: `runbooks/twilio/list_workers.py` (outputs `workers.csv`; run from repo root).
- GAM7 at `~/bin/gam7/gam` for sheet writes (user `aobsiye@helcim.com`).

## Assign an extension (given a user)

1. **Find the worker.** Refresh `workers.csv` (`cd ~/Documents/Devin/skills-Helcim/runbooks/twilio && python3 list_workers.py`),
   then match the user by email/name in `worker` or `full_name`. Prefer the `@helcim.com` record;
   several people have a duplicate bare-username worker (see runbook). If no worker exists, stop
   and tell the user — do NOT create workers.
2. **Pick a number.** Default: the lowest available number in 1135–1413 that is not present in
   `workers.csv` (1317 and 1399 were recently freed — safe but callers may remember them; mention
   if picked). If the user names a specific number, verify it is unused first; if taken, report who has it.
3. **Update Twilio.** GET the worker
   (`https://taskrouter.twilio.com/v1/Workspaces/{WS}/Workers/{WK}`; discover WS SID via
   `GET .../v1/Workspaces`), parse `attributes` JSON, **preserve every key**, add `"ext": "<n>"`
   (string), POST back with form field `Attributes=<json>`. GET again to verify.
4. **Update the Google Sheet** row for that ext:
   `gam user aobsiye@helcim.com update sheetrange 150TZ_oQgUc1OdTbTtuDEHxJWDoZ6CuajMX_BJVOhCkQ json '<json>' raw`
   with `{"range":"extensions!A<row>","majorDimension":"ROWS","values":[[ "<n>","<worker>","<full_name>","<email>","<activity>","<sid>" ]]}`.
5. **Regenerate exports**: rerun `list_workers.py` and rebuild `extensions.csv` (filter `workers.csv`
   for non-empty ext). Both files are git-ignored.
6. Report: assigned number, worker, and that the sheet was updated.

## Remove an extension

Same flow, but `attrs.pop("ext")` and write the sheet row as `[ "<n>", "Available", "", "", "", "" ]`.

## Gotchas

- `ext` is a **string** in attributes JSON.
- Never overwrite attributes with only `{ext}` — the blob carries routing, roles, contact_uri, email.
- GET after POST both to verify; the two numbers reassigned on 2026-11-09 (1317 → jsandhu only,
  1399 → ldeleon only) were confirmed this way.
- If GitHub push protection blocks a push mentioning the Account SID or token, remove the literal
  value (keep `$VAR` references) — it happened once, in `runbooks/twilio/README.md`.
