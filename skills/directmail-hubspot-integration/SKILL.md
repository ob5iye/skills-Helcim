---
name: directmail-hubspot-integration
description: Feed Directmail.io QR-scan webhook data into HubSpot via a free Google Apps Script receiver — no Operations Hub Pro, no Zapier
---

Guidance for building the Directmail.io → HubSpot QR-scan integration at Helcim.
Everything below reflects decisions made in the Sep 15, 2026 team discussion; treat it as the
agreed approach unless new constraints arrive.

## The job

Direct mail pieces carry personalized QR codes (vendor: **Directmail.io**). When a recipient
scans one, Directmail.io fires a webhook. Requirement from Feyi Oladipo: feed that scan data
into HubSpot. No integration work happens on the vendor's side — they only send the webhook.

**Core constraint:** webhook-`*triggered workflows*` in HubSpot require Operations Hub Pro
(~$10k/yr — quoted by Jared Slemp). We do NOT have that plan and are NOT buying it.
Zapier is also ruled out (not owned, considered too expensive).

**Chosen solution:** Google Apps Script web app as the webhook receiver (Option that was
agreed on). It logs scans to a Google Sheet and writes to HubSpot via the standard CRM API —
both are free and work on the current HubSpot plan.

## People

| Person | Role |
|--------|------|
| Abdi Obsiye | Building the integration (me) |
| Feyi Oladipo | Marketing owner of the direct mail campaign; vendor contact |
| Jared Slemp | Evaluated HubSpot side; quoted the $10k plan |
| Olha | Would have handled a custom-code alternative if Apps Script didn't work |

## Answered questions from the discussion (don't re-litigate)

- **"Does Directmail.io need to customize their JSON structure?"** — No. The Apps Script
  middle layer accepts whatever payload they send and maps fields to HubSpot properties.
  Custom payload shape is only needed when posting *directly* to HubSpot's Forms API, which
  we are not doing.
- **"Is there a no-code integration on the direct mail side?"** — Vendor said webhooks only.
  That is fine; the Apps Script IS the no-cost receiver.
- **Scan → contact identity:** a generic QR scan can't identify the person. Each mail piece
  must carry a **unique per-recipient code** (pURL/unique code) present in the webhook
  payload. Must confirm this is in the real payload.

## Status: LIVE (verified end-to-end Sep 21, 2026)

Tracked as **ITSP-111** (Done). Built, tested with the vendor, handed over to Feyi, team
update posted. History of how it got there:

- Deployed as **Version 4** (Web app, Execute as: Me, access: Anyone). Vendor posts to
  `https://script.google.com/macros/s/AKfycbxP6VcmgqFqGfPW73Gq4j5k20br5BT__Yi_LT18TptzwsmNxVxau4VJPFS7oE9rIcpNkQ/exec?token=<WEBHOOK_SECRET>`
  (URL alone is harmless without the token).
- Sheet has manual header row: `Timestamp | Email | QR Code | Campaign | Raw Payload`.
- **Sep 17, 1:20 PM:** real POST logged with flat test payload
  `{"email":"demo.scanner@helcim-test.com","qr_code":"DEMO-QR-2026","campaign":"Fall2026-DirectMail"}`
  — matches `F` exactly.
- **Sep 18, 9:37 AM:** Directmail.io's live test POST arrived. Payload was an **array of
  campaign/list metadata** (`campaign_id 43957 "Helcim"`, dates 2026-09-18→10-18, list
  `test_contact_webhook.csv`) — no person fields → script created a **blank HubSpot contact**
  (`qr_scan_count=1` + `last_qr_scan_timestamp` only). Contact activity shows source
  "Offline Sources from **QR Scan Webhook Receiver**" (the private app name) — proof the
  vendor → Apps Script → HubSpot chain works.
- **Vendor-side problem:** they claimed 3 test sends; only the 9:37 AM one reached Google
  (Executions page shows no other doPost attempts — every POST that hits Google logs one,
  even rejected ones). The other 2 failed before delivery. Hypothesis to confirm with vendor:
  Apps Script answers `/exec` with a 302 redirect to script.googleusercontent.com and their
  dashboard flags that as failed delivery. Asked vendor for per-send HTTP status/errors.
- **Vendor clarified (Sep 18 PM):** their "3 test records" were **3 objects in ONE batched
  push** — matches the single 9:37 AM execution exactly. Nothing was lost; the
  302-failed-delivery hypothesis for the "missing 2" was wrong.
- **Script updated + redeployed (Sep 18):** array unwrapping (each lead → own sheet row +
  HubSpot contact), per-record fault tolerance, `doGet` health check, parse-failure logging.
  Verified the new version is live via browser GET → `{"status":"ok","service":"directmail-webhook-receiver"}`.
- **Vendor re-test (Sep 18, 3:41 PM):** array unwrap worked — 3 separate sheet rows, emails
  extracted (`louvensa03@bergstrom.oom`, `caleigh.keebler@gmail.com`, `jami84@lueilwitz.com`
  — vendor test data). **But HubSpot got nothing.** Initially suspected missing contacts
  Read scope (search-before-create) — superseded by the confirmed root cause in the Sep 20
  entry below.
- **Real lead payload keys observed (from sheet raw column):** `campaign_id`,
  `campaign_name` (**confirmed** — `F.campaign` must point here, one-word fix pending
  redeploy as of Sep 21), `campaign_start_date`, `campaign_end_date`, `list_name`,
  `list_friendly_name`, `list_created_at`, `email`, + more cut off in screenshots.
  The test pushes look like **list-upload events** (no per-recipient code field visible) —
  the `qr_code`-equivalent key must come from a real scan event payload.
- **Sep 20 incident — midnight-UTC regression (confirmed root cause of the Sep-18 write
  failures):** the deployed Version 3 script sent `last_qr_scan_timestamp:
  new Date().toISOString()` (time-of-day included) → every HubSpot write was rejected with
  `INVALID_DATE ... is at HH:MM:SS UTC, not midnight!` while sheet rows logged normally. The
  runbook script below already had the `setUTCHours(0,0,0,0)` fix; the live code had lost it
  in the Sep 18 edit. Fixed in Version 4 and re-verified live: first POST →
  `{"created":"249609734180"}`, repeat POST → `{"updated":"...","scans":2}`, GET health
  check → `{"status":"ok",...}`, no-token POST → `{"error":"unauthorized"}` (token check works).
- **Vendor re-test (Sep 21, 10:22 AM):** full pipeline green — 3 sheet rows
  (`jacobs.alana@strosin.com`, `dariana40@ritchie.net`, `fcronin@wehner.net`) and matching
  HubSpot contacts created (e.g. `fcronin@wehner.net`, 10:22 AM via "QR Scan Webhook
  Receiver", company auto-associated from domain). Sheet QR Code/Campaign columns still blank
  pending `F` finalization.
- Cleanup pending: delete from HubSpot the blank Sep-18 contact, `demo.scanner@helcim-test.com`,
  Sep-20 `livescan@test.com` (ID 249609734180), and the Sep-18/21 vendor-test contacts once
  the team has seen them. **Rotate the HubSpot private app token** (it appeared in a chat
  screenshot on Sep 18) and update Script Properties.

## Remaining open items

End-to-end verified working (Sep 21). Still open:
(1) paste one FULL raw sheet cell from a production scan to finalize `F` (`campaign_name`
mapping + the per-recipient code key + name fields), (2) max leads per push (payload-size
concern if they ever batch in the hundreds), (3) HubSpot token rotation + test-contact
cleanup (see status bullet above). Vendor behavior: sends are batched, one push carries
multiple lead objects.

## Build steps

1. **Create a Google Sheet** ("QR Scan Log") → `Extensions → Apps Script` → paste the script
   below (replaces the default function).
2. **HubSpot private app:** Settings → Integrations → Private Apps → create with contacts
   read + write scopes → copy the token.
3. **Apps Script Script Properties** (gear icon → Project Settings → Script Properties):
   - `HUBSPOT_PRIVATE_APP_TOKEN` = the private app token
   - `WEBHOOK_SECRET` (optional) = shared secret appended to webhook URL as `?token=`
4. **Create HubSpot custom contact properties** (Settings → Properties → Contacts):
   - `qr_code` (single-line text)
   - `qr_scan_count` (number)
   - `last_qr_scan_timestamp` (date)
   - `last_qr_campaign` (single-line text)
5. **Deploy:** Deploy → New deployment → type **Web app** → Execute as: **Me** →
   Who has access: **Anyone** → copy the `/exec` URL. Give that URL to Directmail.io as the
   webhook endpoint.
6. **Test** before handing the URL out: run `testDoPost()` in the editor, check the Sheet
   row and the HubSpot contact land.

## The script

```javascript
// ===== FIELD MAPPING — provisional until a real per-scan payload is confirmed =====
const F = {
  email:    'email',     // key in their JSON holding recipient email
  code:     'qr_code',   // key holding the unique per-recipient QR/pURL code
  campaign: 'campaign',  // key holding campaign name (optional)
};
// ===========================================================================

function doPost(e) {
  try {
    // Optional shared-secret check: Directmail.io posts to <URL>?token=yoursecret
    const secret = PropertiesService.getScriptProperties().getProperty('WEBHOOK_SECRET');
    if (secret && (!e || e.parameter.token !== secret)) return json_({error: 'unauthorized'});

    if (!e || !e.postData || !e.postData.contents) return json_({error: 'no body'});

    let data;
    try {
      data = JSON.parse(e.postData.contents);
    } catch (parseErr) {
      logRaw_('UNPARSEABLE: ' + e.postData.contents);
      return json_({status: 'error', message: 'invalid JSON — raw body logged to sheet'});
    }

    const records = Array.isArray(data) ? data : [data]; // vendor batches leads per push
    const results = records.map(processRecord_);
    return json_({status: 'ok', received: records.length, results: results});
  } catch (err) {
    return json_({status: 'error', message: String(err)});
  }
}

// Health check (vendor/browser GETs) — prevents noisy Failed doGet executions
function doGet() {
  return json_({status: 'ok', service: 'directmail-webhook-receiver'});
}

function processRecord_(data) {
  logToSheet_(data);
  try {
    return upsertHubSpotContact_(data);
  } catch (err) {
    return {hubspotError: String(err)};
  }
}

function logRaw_(text) {
  SpreadsheetApp.getActiveSpreadsheet().getSheets()[0].appendRow([new Date(), '', '', '', text]);
}

function logToSheet_(data) {
  SpreadsheetApp.getActiveSpreadsheet().getSheets()[0]
    .appendRow([new Date(), data[F.email] || '', data[F.code] || '', data[F.campaign] || '', JSON.stringify(data)]);
}

function upsertHubSpotContact_(data) {
  const token = PropertiesService.getScriptProperties().getProperty('HUBSPOT_PRIVATE_APP_TOKEN');
  if (!token) throw new Error('Set HUBSPOT_PRIVATE_APP_TOKEN in Script Properties');

  const email = data[F.email], code = data[F.code], campaign = data[F.campaign];
  // HubSpot date-picker properties require midnight UTC — do NOT send current time-of-day
  const midnight = new Date(); midnight.setUTCHours(0, 0, 0, 0);
  const props = { last_qr_scan_timestamp: midnight.toISOString() };
  if (campaign) props.last_qr_campaign = campaign;

  let contactId = code ? findContactId_(token, 'qr_code', code) : null;
  if (!contactId && email) contactId = findContactId_(token, 'email', email);

  if (contactId) {
    const existing = hsFetch_(token, 'get', '/crm/v3/objects/contacts/' + contactId + '?properties=qr_scan_count');
    props.qr_scan_count = Number(existing.properties.qr_scan_count || 0) + 1;
    hsFetch_(token, 'patch', '/crm/v3/objects/contacts/' + contactId, {properties: props});
    return {updated: contactId, scans: props.qr_scan_count};
  }

  const createProps = Object.assign({qr_scan_count: 1}, props);
  if (email) createProps.email = email;
  if (code) createProps.qr_code = code;
  const res = hsFetch_(token, 'post', '/crm/v3/objects/contacts', {properties: createProps});
  return {created: res.id};
}

function findContactId_(token, property, value) {
  const res = hsFetch_(token, 'post', '/crm/v3/objects/contacts/search', {
    filterGroups: [{filters: [{propertyName: property, operator: 'EQ', value: String(value)}]}],
    properties: ['email'], limit: 1,
  });
  return res.results && res.results.length ? res.results[0].id : null;
}

function hsFetch_(token, method, path, body) {
  const res = UrlFetchApp.fetch('https://api.hubapi.com' + path, {
    method: method,
    contentType: 'application/json',
    headers: {Authorization: 'Bearer ' + token},
    payload: body ? JSON.stringify(body) : undefined,
    muteHttpExceptions: true,
  });
  const parsed = JSON.parse(res.getContentText());
  if (res.getResponseCode() >= 300) throw new Error('HubSpot API error: ' + res.getContentText());
  return parsed;
}

function json_(obj) {
  return ContentService.createTextOutput(JSON.stringify(obj)).setMimeType(ContentService.MimeType.JSON);
}

// Run this from the editor to test without Directmail.io
function testDoPost() {
  const fake = {
    parameter: {},
    postData: {contents: JSON.stringify([
      {email: 'test1@example.com', qr_code: 'TEST-001', campaign: 'Fall2026'},
      {email: 'test2@example.com', qr_code: 'TEST-002', campaign: 'Fall2026'},
      {email: 'test3@example.com', qr_code: 'TEST-003', campaign: 'Fall2026'},
    ])},
  };
  Logger.log(doPost(fake).getContent());
}
```

## Gotchas (each of these has already bitten someone)

- **Code changes do NOT go live automatically.** The `/exec` URL keeps running the old
  version until Deploy → Manage deployments → pencil icon → **New version** → Deploy.
  Use the `/dev` URL for live-code testing.
- **"Anyone" access is required** so Directmail.io's servers can POST without a Google
  login. The URL is unguessable (long random ID); add the `WEBHOOK_SECRET` check if a
  shared secret is wanted — the hook URL simply gets `?token=...` appended.
- **"Completed" execution ≠ successful HubSpot write.** `doPost` catches HubSpot errors and
  still returns 200 to the vendor, so the Executions status column means "script ran", not
  "contact written." If a sheet row has no HubSpot counterpart, suspect the
  `HUBSPOT_PRIVATE_APP_TOKEN` Script Property or private-app scopes, not the status column.
- **A "Completed" execution exists for every POST that reaches Google** — even unauthorized
  or malformed ones. If the vendor claims sends that have no executions, the requests never
  arrived (vendor-side failure), full stop.
- **Failed `doGet` executions are normal noise.** The script only defines `doPost`; browser
  visits and vendor health-check GETs log as Failed doGet ("function not found"). Silence
  them with `function doGet() { return json_({status: 'ok'}); }`.
- **Payloads may be JSON arrays.** The Sep 18 vendor test was `[{...}]`. `data[F.email]` on
  an array is `undefined` → blank sheet columns B–D and a junk no-email contact in HubSpot.
  Handle `Array.isArray(data)` when finalizing the script.
- **Verifying `/exec` with curl works IF you don't force `-X POST`.** Use
  `curl -sSL "<URL>?token=$WEBHOOK_SECRET" -H "Content-Type: application/json" -d '{...}'` —
  with `-d` and no `-X`, curl follows the 302 chain correctly (verified live Sep 20).
  `-X POST`, `--post302`, or replaying the googleusercontent echo URL manually all fail
  (411 Length Required / 405 / Drive "unable to open the file"). A GET with no body hits
  `doGet` and returns the health-check JSON.
- **Field mapping block `F` is a placeholder** until the real payload arrives. Matching
  order matters: search by `qr_code` first, fall back to `email`.
- **Quotas:** free Gmail accounts cap `UrlFetchApp` at ~20k calls/day; each scan costs 2–3
  calls. Orders of magnitude above expected scan volume — not a concern, but don't reuse
  this script for something high-frequency.
- **Never commit the private app token.** Script Properties, not source code.
