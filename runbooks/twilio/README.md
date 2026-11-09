# Twilio Flex / TaskRouter

Helcim's phone system runs on Twilio Flex. Agents are TaskRouter **Workers** in the
**Flex Task Assignment** workspace. Each worker's `attributes` JSON holds the
phone extension under the `ext` key, e.g.

```json
{"ext":"1165","full_name":"Cordell Finnson","roles":["admin"],"email":"cfinnson@helcim.com", ...}
```

The Console worker list does not show extensions; use the API.

## Credentials

Account SID and auth token (Helcim main account) live in the repo-root `.env`
(git-ignored) and in 1Password:

```
TWILIO_ACCOUNT_SID=AC...
TWILIO_AUTH_TOKEN=...
```

An API key pair works too (`TWILIO_API_KEY` / `TWILIO_API_SECRET`), the script prefers it when set.
Console path for both: Account > API keys & tokens.

## List all workers + extensions

```bash
cd ~/Documents/Devin/skills-Helcim
python3 runbooks/twilio/list_workers.py          # table to stdout + workers.csv
python3 runbooks/twilio/list_workers.py --no-csv
```

Stdlib only (no `requests`). Pages through every workspace and every worker,
sorted by extension. `workers.csv` is git-ignored because it is a staff roster.

Underlying call:
`GET https://taskrouter.twilio.com/v1/Workspaces/{WS}/Workers?PageSize=1000` with Basic auth.

## State as of 2026-11-09

- 157 workers, 46 with an `ext`, range 1135 to 1403 (next free 1404).
- Duplicate extensions: **1317** (jsandhu, ltaylor) and **1399** (bnguyen, ldeleon).
- ~12 people have two worker records, one bare username and one email
  (cbeauchamp, rng, sdavis, tmanchee, mcharath, smacisaac, rmccaughey, jgunby,
  avanee, tlitwin, wmcfarland, aobsiye). Likely leftovers from an older login format.
