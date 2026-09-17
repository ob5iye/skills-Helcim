# Laptop Asset Tracking — Jira Assets (RUNBOOK)

> Initiative ticket: **ITSP-110** (label `asset-tracking`). Pilot built & validated 2026-09-17.
>
> Problem solved: laptops were tracked by user; terminated user → wipe → reissue broke the paper
> trail, and Finance had no inventory answer. New identity = **hardware serial number** (+ printed
> QR asset tag); the user is a changing attribute with full history.

## What exists (live in helcim.atlassian.net)

| Item | Value |
|---|---|
| Assets workspace ID | `9c2136e0-6a9b-4ea4-8df2-7e6e8bc80e32` |
| Schema | `Helcim IT Assets` — id **103**, key **HLCA** |
| Object type | `Laptop` — id **139** |
| Pilot objects | `HLCA-93` HLC-0001 (Abdi's MacBook, serial `N6VN9M200T`), `HLCA-94` HLC-0002 (Win test), `HLCA-95` HLC-0003 (Mac test) |

**Laptop attribute IDs** (needed for all API writes):

| ID | Attribute | Type |
|---|---|---|
| 412 | Name (= label, printed on QR stickers) | Text |
| 413 | Serial Number | Text, **unique** |
| 414 | Platform | Select: `macOS`/`Windows` |
| 415 | Model | Text |
| 416 | Assigned User | Text (upgrade to User-type later) |
| 417 | Lifecycle Status | Select: `In Stock`/`Assigned`/`Ready for Redeploy`/`In Repair`/`Retired` |
| 418 | Purchase Date | Date |
| 419 | Purchase Cost | Float |
| 420 | Warranty Expiry | Date |

## API patterns that work (learned the hard way)

- Auth: `curl -u "$ATLASSIAN_EMAIL:$ATLASSIAN_API_TOKEN"` — token in `skills-Helcim/.env`
  (git-ignored). Create tokens at https://id.atlassian.com/manage-profile/security/api-tokens
- Base: `https://api.atlassian.com/jsm/assets/workspace/<WS>/v1`
- Workspace discovery: `GET https://helcim.atlassian.net/rest/servicedeskapi/assets/workspace`
- Create attribute: `POST /objecttypeattribute/<objectTypeId>` — **must use `defaultTypeId`**
  (int), NOT `defaultType:{id:n}` (rejected: "Default Type invalid").
  defaultTypeIds: 0=Text, 3=Float, 4=Date, 10=Select (+`"options":"a,b,c"`).
  Uniqueness: `"uniqueAttribute":true`.
- Schema/object-type `description` has a SHORT size limit — keep to a few words or creation fails
  with an opaque `i18n.constraint.violation...Size.description` error.
- Create object: `POST /object/create` — attributes array of
  `{"objectTypeAttributeId":N,"objectAttributeValues":[{"value":"..."}]}`
- Read object's attrs: `GET /object/<id>/attributes`
- Cost: REST API + token = **$0**; no per-call metering.

## QR workflow (the human loop)

- Print: Assets UI → schema → Objects (list view) → select rows → **Bulk actions → Print QR codes**
  → size (~60–80px for stickers) → Print/PDF. UI-only step (no public QR-print API).
- Scan: iPhone **Camera** opens the record (universal link). In-app scanner only exists inside an
  **Assets objects custom field** on a work item — one still needs to be created for ITSP to get
  in-app scanning (rollout task).
- Reissue loop: returned laptop → scan → Status `Ready for Redeploy`; after wipe/redeploy per
  SOP `hacks/helcim-zero-touch/04-SOP-NEW-USER-DEVICE.md` → scan → assign + `Assigned`.

## Pilot scripts

- `pilot/01-schema-and-type.sh` — schema + object type + attributes (source format, uses fixed
  defaultTypeId)
- `pilot/02-pilot-objects.sh` — 3 pilot objects

## Rollout (tracked on ITSP-110)

1. Fleet import from Jamf + Intune keyed on serial (REST or CSV bootstrap)
2. Nightly n8n sync Jamf/Intune → Assets (assignee/status self-heals after wipe/reissue)
3. Fleet-wide HLC-#### QR sticker print + apply
4. `Linked Asset` Assets-objects custom field on ITSP screens (mobile in-app scanner)
5. Finance read-only view + weekly digest (new purchases / assignment changes)
6. SOP update: check-in/check-out scan steps added to 04-SOP

## Watch-outs

- Object limits: current Jira plan includes 1,000 objects (Service Collection Std = 5,000).
  Fine for laptops; add monitors/phones → re-check.
- Paid shortcut exists (Jamf/Intune importers, OnLink) — not needed; free API sync preferred.
- Cleanup: delete HLCA-94/95 test objects after fleet import (keep HLC-0001; it's the real asset).
