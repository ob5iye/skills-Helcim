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

## Blocked on (ask Feyi)

A **sample webhook payload** from Directmail.io. Needed to finalize the field mapping block
`F` in the script. Ask at the same time: (1) does the payload include the unique
recipient code per QR scan, (2) is the webhook real-time per scan or batched.

Message already sent to the team (for context):

> We don't need the $10k HubSpot plan or Zapier. I can build it with Google Apps Script for
> free: Directmail.io's webhook hits a script I host, it logs every scan to a Google Sheet
> and pushes the data into HubSpot through the API. Can you send me a sample of the actual
> webhook payload so I can confirm the field mapping? Also confirm the payload includes the
> unique QR code per recipient — we need that to match scans to contacts.

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
// ===== FIELD MAPPING — adjust once Directmail.io shares a sample payload =====
const F = {
  email:    'email',     // key in their JSON holding recipient email
  code:     'qr_code',   // key holding the unique per-recipient QR/pURL code
  campaign: 'campaign',  // key holding campaign name (optional)
};
// ===========================================================================

function doPost(e) {
  try {
    // Optional shared-secret check: Directmail.io posts to <URL>?token=yoursecret
    // const secret = PropertiesService.getScriptProperties().getProperty('WEBHOOK_SECRET');
    // if (secret && e.parameter.token !== secret) return json_({error: 'unauthorized'});

    if (!e || !e.postData || !e.postData.contents) return json_({error: 'no body'});

    const data = JSON.parse(e.postData.contents);
    logToSheet_(data);
    const result = upsertHubSpotContact_(data);
    return json_({status: 'ok', hubspot: result});
  } catch (err) {
    return json_({status: 'error', message: String(err)});
  }
}

function logToSheet_(data) {
  SpreadsheetApp.getActiveSpreadsheet().getSheets()[0]
    .appendRow([new Date(), data[F.email] || '', data[F.code] || '', data[F.campaign] || '', JSON.stringify(data)]);
}

function upsertHubSpotContact_(data) {
  const token = PropertiesService.getScriptProperties().getProperty('HUBSPOT_PRIVATE_APP_TOKEN');
  if (!token) throw new Error('Set HUBSPOT_PRIVATE_APP_TOKEN in Script Properties');

  const email = data[F.email], code = data[F.code], campaign = data[F.campaign];
  const props = { last_qr_scan_timestamp: new Date().toISOString() };
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
    postData: {contents: JSON.stringify({email: 'test@example.com', qr_code: 'TEST-001', campaign: 'Fall2026'})},
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
- **Field mapping block `F` is a placeholder** until the real payload arrives. Matching
  order matters: search by `qr_code` first, fall back to `email`.
- **Quotas:** free Gmail accounts cap `UrlFetchApp` at ~20k calls/day; each scan costs 2–3
  calls. Orders of magnitude above expected scan volume — not a concern, but don't reuse
  this script for something high-frequency.
- **Never commit the private app token.** Script Properties, not source code.
