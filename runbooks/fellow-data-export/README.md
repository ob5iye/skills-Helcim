# Fellow.app Data Export (ITSP-104, Sept 2026)

Full export of the Partnerships Team's Fellow meeting data before subscription
cancellation (Oct 5, 2026). Requested by Joanna Wynn.

## Context

- Workspace: `helcim.fellow.app`, **Business plan**, 4 seats
- Fellow permissions are attendance-based: an API key only sees what its
  owner's account can see. Admin role ≠ content access.
- Joanna's account held the full Partnerships library (Sept 2024 – Sept 2026),
  so the export ran with an API key created from **her** account.

## Procedure that worked

1. Admin: Workspace Settings → Security → Connections → enable **Developer API**
2. From the content owner's account: User Settings → Developer Tools →
   Create API key (shown once)
3. Key stored locally in `~/Documents/Devin/fellow-export/.env`
   (`FELLOW_API_KEY=...`) — never in chat/email/Slack
4. Scripts in `~/Documents/Devin/fellow-export/`:
   - `inventory.py` — lists all recordings + notes (cursor pagination)
   - `download.py` — pulls recordings with transcripts + AI notes
     (`POST /api/v1/recordings` with `include: {transcript, ai_notes}`),
     then each note via `GET /api/v1/note/{id}` (resumable JSONL)
   - `convert.py` — per-meeting `.txt` files (metadata, AI summary/actions/
     decisions/topics, speaker-labeled transcript)
   - `bundle.py` — monthly bundle files for NotebookLM source limits

## API gotchas

- Base: `https://{subdomain}.fellow.app/api/v1`, auth header `X-API-KEY`
- List endpoints are **POST** with JSON body; responses nest under the
  endpoint name (`{"recordings": {"page_info": ..., "data": [...]}}`)
- Python `urllib` default User-Agent gets **403**; set a curl-like UA
- Rate limits: 3 req/s, 10k/day
- `media_url` (video/audio download) **requires privileged/Enterprise key** —
  not available on Business plan. Videos must be downloaded manually from the
  UI per recording if needed.

## Result (2026-09-29)

- 394 recordings (377 with transcripts, 390 with AI notes), 3,406 notes
- Output: `~/Documents/Devin/fellow-export/` — `raw/` (canonical JSON),
  `transcripts/` (394 txt), `notes_only/` (14 txt), `bundles_monthly/`
  (25 monthly files), plus dated zip archive
- Destination: Google Drive + NotebookLM (25 monthly bundles fit the free
  50-source cap)
- Cleanup after: delete the API key from Joanna's Developer Tools
