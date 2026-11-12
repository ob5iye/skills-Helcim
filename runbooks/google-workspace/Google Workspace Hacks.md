# Google Workspace Hacks

A running collection of fixes and tips for Gmail, Groups, Calendar, and other Workspace tools. For GAM7-based Workspace administration and Shared Drive permission cleanup, use the **`google-workspace` skill** in `skills/google-workspace/SKILL.md`.

---

## GAM7 — CLI admin access (installed 2026-10-09)

GAM7 is installed on Abdi's Mac at `~/bin/gam7/gam` with config/cache in `~/.gam/` (contains `client_secrets.json`, `oauth2.txt`, `oauth2service.json` — **never commit these**).

**GCP wiring:** Reuses the existing `it-services-474319` GCP project ("IT Services") — GAM could not create a new project because no one held org-level `resourcemanager.projects.create` (Workspace super admin ≠ GCP org admin; project creation is denied org-wide). The service account is `it-services-474319@it-services-474319.iam.gserviceaccount.com` (Client ID `113094367552118324360`) with full domain-wide delegation (42 scopes). The OAuth client (`604434694659-rmfceqq453cvrgj9reklpne8jg4p6uaf`) is an Internal desktop app, trusted in Admin console → App access control. An older unused desktop client (`...9uhndkrem...fqssdg0`) was replaced during setup and can be deleted from GCP if it's still listed.

**Authorized as:** `aobsiye-admin@helcim.com` (DwD) / `aobsiye@helcim.com` (client OAuth).

**Credential cleanup:** An OAuth desktop-client secret was exposed in the setup conversation on 2026-10-09. Rotate that client secret in GCP and update/re-authorize GAM locally if this has not already been done. Never paste OAuth secrets, service-account keys, or token files into chat or Git.

**Verify health:** `gam user aobsiye@helcim.com check serviceaccount` — should print "All scopes PASSED!".

**2026-11-12 re-auth:** `~/.gam/` was found with only `gam.cfg` (no `client_secrets.json`, `oauth2.txt`, or `oauth2service.json`). Rebuilt client access: a new client secret was minted on the existing OAuth client (GCP no longer lets you download an existing secret, you must "Add secret" and download the JSON) and saved as `~/.gam/client_secrets.json`. `gam oauth create` was run as **`aobsiye-admin@helcim.com`** with read-only Directory group/user + Groups Settings scopes only. `aobsiye@helcim.com` has **no Workspace admin role** and gets 403 on every Directory call, so always authorize GAM with the `-admin` account. The GCP project `it-services-474319` is only visible when signed into the Cloud Console as `aobsiye@helcim.com` (the `-admin` account has no IAM role there). Still outstanding: restore `oauth2service.json` (service account key for `it-services-474319@...`) before any DwD / Drive-audit work, disable the old client secret `****bUnZ` in GCP, and widen the OAuth scopes (`gam oauth create` again) when write operations are needed. Note: `gcloud auth` cannot be used as a substitute, Google blocks its public OAuth client from requesting Admin SDK scopes ("This app is blocked").

**`team@helcim.com` coverage (2026-11-12):** "Helcim - Team" is a manually maintained nest of ~90 dept/team groups (37 direct members, 181 active users reached after recursion). 67 of 248 active users are NOT reached, including `kveiledal@` and `cjackson@`. The dynamic group `staff@helcim.com` (194 members, auto-populated) is the reliable all-company list. Fix options: nest `staff@` inside `team@`, or send company-wide mail to `staff@` directly. Check with `gam print group-members group team@helcim.com recursive`. Of the 67, 57 were service/`-admin`/kiosk/Okta-disabled accounts, 10 were real staff. On 2026-11-12 eight were added to their team groups (`cjackson`, `kveiledal` → `mx-sales-team@`; `gasejo` → `mx-support-team@`; `htanade` → `operations-supchain-team@`; `kmacgillivray` → `executiveteam@`; `dcardinal-ext`, `mchumakov` → `dev-dept@`; `jhoward` → `trustandsafety-dept@`). `rallan` was added to `people.n.culture-dept@` (a direct member of `team@`) at the user's request; `ssandhu` (last login 2026-01-30, likely on leave) remains the only staff member intentionally unreached. GAM OAuth now includes `admin.directory.group` (write). `oauth2service.json` (GAM Project SA key) was re-created the same day; `check serviceaccount` PASSes 35/38 scopes (drive OK; cloud-identity, cloud-platform, youtube.readonly FAIL but unused).

**Group/Drive cleanup (2026-11-12):** `1pass-all-temp@helcim.com` emptied (175 members removed; 1Password moved to Okta provisioning ~2 months prior, group was dead). Full pre-removal member list kept at runbooks/google-workspace/backups/1pass-all-temp-members-2026-11-12.csv` (restore: `gam csv runbooks/google-workspace/backups/<file> gam update group 1pass-all-temp@helcim.com add member ~email`). Group itself left in place, 0 members. MX - Success shared drive: restructured to direct management. `mgonzaga@` is now a **direct** user Manager (organizer) on the drive and `ac-mx-owner@` was removed from the drive ACL + emptied (it also gates the Sales drive as Manager and feeds MX reporter chains, so the group itself was left in place, empty). GAM shared-drive ACL writes need `asadmin` (e.g. `gam user aobsiye-admin@helcim.com add|delete drivefileacl <driveId> <email> [role X] asadmin`); plain calls fail with "Does not exist" because the admin isn't a member of most drives. MX - Success drive ID: `0AGdXeeMV42IEUk9PVA`; Product drive ID: `0AITCgl2PYCdxUk9PVA`. MX - Success has one orphaned fileOrganizer ACL (blank name/email, deleted account) pending cleanup. Final MX - Success structure (2026-11-12): `mgonzaga@` direct Manager; `mx-success-team@helcim.com` (the team@ newsletter feeder group: anadeem, ascego, cpocza, keze, kvejvoda, mgonzaga) as Content manager; `ac-mx-success-maintainer@`/`ac-mx-success-reporter@` removed from ACL (groups still exist, empty-ish, may gate future things via `ac-mx-dept@` nesting); duplicate direct entries for ascego/cpocza/keze removed. `smccaskill@`, `ldeleon@`, `tbarnden@` were later added to `mx-success-team@` (now 9 members) and their direct drive entries removed, leaving the ACL as exactly: mgonzaga (direct Manager) + mx-success-team@ (Content manager) + one orphaned ghost ACL. Note: group grants Content manager to all, so tbarnden@ went Commenter → Content manager; a group member cannot be demoted by a lower direct entry (highest role wins), demoting anyone now requires removing them from the team group. PILOT started 2026-11-12: all users stripped from `ac-mx-success-maintainer@` (was ascego, cpocza, keze, ldeleon, mgonzaga) and `ac-mx-success-reporter@` (was ascego, cpocza, keze + nested tier groups, which were kept). Success team is the test case for retiring `ac-*` tier groups; if no complaints by ~2026-12-12, apply the same to `ac-product-*`, `ac-mx-sales-*`, `ac-mx-support-*`, etc. Restore backups in runbooks/google-workspace/backups/ac-mx-success-*-members-2026-11-12.csv` (in git now). If someone complains: restore the CSV, tell this repo's runbook, revert the drive ACL too. Same day, success-team members were also stripped from the SUPPORT AC groups: `ac-mx-support-developer@` (removed keze, smccaskill, tbarnden) and `ac-mx-support-reporter@` (removed keze, smccaskill, tbarnden, anadeem, kvejvoda). Backups: runbooks/google-workspace/backups/ac-mx-support-{developer,reporter}-members-2026-11-12.csv`. Note smccaskill@ is still titled Merchant Support Specialist in the directory but intentionally lives in Success groups now. Full department-by-department rollout plan lives in `Drive-Consolidation-Tracker.md` in this folder. Note: `gam print group-members` can show stale/empty results immediately after an add; re-read after ~10s before trusting it. Product shared drive (`0AITCgl2PYCdxUk9PVA`) access is gated by the `ac-product-*@helcim.com` tier groups (owner/maintainer = content manager, developer/reporter = contributor, dept = viewer), NOT by `productteam@`. Consolidating that to `productteam@` as content manager was under discussion; `bmattas@` and `mkissinger@` are on `productteam@` but had NO drive access under the old scheme.

**Useful reports:**
```bash
gam print shareddrives          # all shared drives + restrictions
gam print shareddriveacls       # membership/roles per shared drive
gam print users all             # full user directory
gam print groups all
gam print group-members group <group@helcim.com>
gam user <user> print filelist fields id,name,parents   # per-user Drive listing
gam info domain                 # customer ID C02twm3z6, 245 users
```

**Update GAM:** `gam version battlereport` or rerun the installer script from gam-shortn.appspot.com.

**Groups / dynamic groups:** the tenant already runs 10 dynamic groups (`staff@`, `townhall@`, `dg-<department>@` …). Inventory, constraints and the Product-team pilot facts are in the `google-workspace` skill ("Groups landscape"); the department-attribute cleanup list that must be done before building more `dg-*` groups is `Department-Attribute-Cleanup.md` in this folder.

---

## Group emails land in "All Mail" instead of the Inbox

**Symptom:** A member of a Google Group (e.g. `compliance@helcim.com`) is subscribed to "Each email" and is receiving every message, but the messages skip the Inbox and land in All Mail.

**Fix this in the member's own Gmail settings — not in the Group admin panel.** The Group's "Each email" subscription is already correct.

### Cause 1 — You're the sender (most common)

If the member sends messages *to* the group they belong to, Gmail intentionally keeps their own copies out of the Inbox to avoid clutter. Those copies go to Sent and All Mail.

> Google: "To prevent clutter, Gmail doesn't deliver messages that you send to your own alias (or to a Group you belong to) to your inbox."

**Fix — add the group as a "Send mail as" address:**

1. Gmail → Settings (gear) → **See all settings**
2. **Accounts** tab → **Send mail as** → **Add another email address**
3. Enter the group address (e.g. `compliance@helcim.com`) → verify
4. Once registered, Gmail delivers the group copies to the Inbox.

### Cause 2 — A filter is archiving them

If the messages come from *other* senders and still skip the Inbox, a filter is archiving them.

**Fix:**

1. Gmail → Settings → **Filters and Blocked Addresses**
2. Find any rule matching the group address with **"Skip the Inbox (Archive it)"** and remove it.
3. Optionally add a filter: To = group address → **Categorize as Primary** + **Never send it to Spam**, leaving Skip Inbox unchecked.

### How to tell which one it is

Open a few of the All Mail messages and check the sender. From the member themselves → Cause 1. From other people → Cause 2.

**Source:** https://support.google.com/a/answer/1703601

---

## Mail merge blocked: "External recipients not allowed"

**Symptom:** User composes a mail merge (purple banner, `@firstname` tags) and gets "Your administrator has not allowed multi-send to recipients outside the organization."

**Cause:** The **Allow for external recipients** checkbox is **off by default on Enterprise edition**. Mail merge itself is on, but external sending is blocked.

**Fix (Admin console):**

1. admin.google.com → **Apps → Google Workspace → Gmail → User settings**
2. Select the sender's OU in the left panel (do NOT enable org-wide)
3. Pencil icon on the **Mail merge** card → check **Allow for external recipients → Override → Save**
4. Sender hard-reloads Gmail, retries in a few minutes (worst case up to 24h)

**Gotchas:**

- The override only applies if the sender's account is actually in that OU — verify in Directory → Users.
- Limits: 1,500 mail merge recipients/day, 500 external per message, 2,000 unique external/day.
- Unsubscribes are handled by mail merge automatically — always keep the merge in merge mode.

**Helcim config (2026-09-24):** Enabled **Mail merge → Allow for external recipients** as an override on the **Exec No Public Cal** OU only (inherited=off at Helcim Inc. root), for Nic's personal "No Hidden Fees" newsletter send. Long-term recommendation: exec newsletters should move off the corporate domain (e.g. Ghost on nicbeique.com) to protect helcim.com sender reputation.

---

## Group alias can't receive external email (vendor notifications bounce)

**Symptom:** An external sender (bank, vendor, monitoring service) emails a group alias like `dev-payments-team@helcim.com` and the message never reaches members — bounces or vanishes. (ITS-808: JPM notification emails.)

**Cause:** Two settings gate external posting, one per level:

1. **Org level (Admin console):** *Groups for Business → Sharing settings → "Group owners can allow incoming email from outside the organization"* — **unchecked by default**. If off, group owners can't enable external posting at all, and inbound external mail sits in a moderation queue for owner approval.
2. **Group level (Google Groups):** the group's own *Who can post* doesn't include External.

**Fix:**

1. admin.google.com → **Apps → Google Workspace → Groups for Business → Sharing settings** → check **Group owners can allow incoming email from outside the organization** → Save (one-time, org-wide).
2. groups.google.com → open the group → **Group settings → General**:
   - Simple view: set **Who can post = Anyone on the web**.
   - Custom access matrix: check **External** on the **"Who can post"** row only.
3. Leave External **unchecked** for *Who can view conversations* and *Who can view members* — external senders only need to post; they shouldn't see the member list or archive.

**Gotchas:**

- If the External checkboxes are greyed out or missing in group settings, the org-level toggle is off — do step 1 first, then revisit the group.
- Posting by email ≠ membership: external **senders** do NOT need "Group owners can allow external members" — that setting is for adding outsiders as group members. Keep it off.
- Opening a high-traffic team alias to the whole web invites spam/phishing into everyone's inbox. Prefer a **dedicated vendor alias** (e.g. `jpm-notifications@helcim.com`) with external posting on, and keep the team alias internal-only.
- Group-level changes apply on Save; org-level sharing changes can take a few minutes to propagate.

**Helcim config (2026-09-24, ITS-808):** Org-level sharing toggle already on (External boxes editable in group settings). Payments team needed JPM settlement/notification emails delivered to the whole team — fix is checking **Who can post → External** for `dev-payments-team@helcim.com` (or spinning up a dedicated vendor alias if opening the team alias proves too spammy).

---

## Chrome Web Store publisher (fuzz@helcim.com)

The Workspace service account **`fuzz@helcim.com`** (Helcim Fuzz) is Helcim's Chrome Web Store publisher. It owns two private (domain-restricted) extensions used by Trust & Safety / Credit Risk: **Autogenerating EDD Note Builder** and **Credit Risk EDD Note Builder**.

Full details — item IDs, update procedure, packaging gotchas — live in **`runbooks/chrome-extensions/README.md`**.

Key reminders:

- Dashboard: https://chrome.google.com/webstore/devconsole (sign in as `fuzz@helcim.com`, publisher `fuzz`) — this is NOT Google Play.
- Uploads need `manifest.json` at the **zip root** (Drive folder downloads nest it — repackage) and a version **higher** than the published one.
- Last update: 2026-09-29, Autogenerating EDD Note Builder 0.0.0.1 → 0.0.2.

---

## Google Chat via GAM7 (set up 2026-11-06)

A Chat app named **GAM** (App ID / project number `604434694659`) is now configured on the `it-services-474319` GCP project — required before ANY Chat write/admin API call works. Config: not a Workspace add-on, all interactive features off (no 1:1, no join spaces, no commands), Cloud Pub/Sub topic `projects/it-services-474319/topics/no-topic` (inert, GAM doesn't listen), visibility limited (unchecked domain-wide), Markdown syntax, error logging on. Read-only Chat calls worked without this; writes (`delete chatmember`, `print chatspaces`, `info chatspace` bot-context) fail with "Google Chat app not found" until the app exists.

**Working commands:**
```bash
gam user <user> show chatsearchmessages keywords "<text>"     # find messages/space
gam user <user> info chatspace spaces/<id>                    # space details
gam user <user> info chatspacedm <otherUser@helcim.com>       # resolve a DM space
gam user <user> show chatmembers spaces/<id>                  # members
gam user <admin> delete chatmember asadmin spaces/<id> user <member>   # spaces only
```

**Platform limitation (verified 2026-11-06):** Chat API **cannot delete human memberships in 1:1 DIRECT_MESSAGE spaces** — error: "Can't delete human user memberships in direct messages between human users or with an app." This applies both as admin (`asadmin`) and as the member. Membership removal only works on named/group spaces. For cleanup of an unwanted 1:1 DM, the user must Hide conversation and/or Block the other account in the Chat UI. (Observed case: Valentyna Ryzha's DM `spaces/54yuXqAAAAE` with service account `design@helcim.com`/Frosty Design — could not be removed via API.)

---

## Calendar meeting-room delegation via GAM (2026-11-06)

Helcim has 15 Calendar resources (`gam print resources`): conference rooms Pepper/Glacier/Lemonade/Midnight/Grape, phone booths Cherry/Kiwi/Peach/Lime/Blueberry/Tangerine, meeting spaces (Common Couch, Dev Meeting Table, Blurple), plus the "Recruitment Event Calendar".

**Grant a coordinator (e.g. recruiter/EA managing interviews+onboardings) the power to edit/move room bookings:** add a calendar ACL on the resource calendars. Roles: `reader|writer|editor|owner` — `editor` and `writer` both map to "Make changes to events" (API emits Role: writer); `owner` = "Make changes and manage sharing" (grants sharing power too — only give if they must hand access to others).

```bash
gam resources "<resourceId1>,<resourceId2>,..." create|add acls editor user:<someone@helcim.com> sendnotifications false
gam resources "<ids>" print acls            # verify
gam resources "<ids>" delete acls user:<someone@helcim.com>   # revoke
```

Note: `gam resources all ...` is NOT valid — pass the comma-separated resourceId list. Use `sendnotifications false` or the grantee gets one email per room.

**Post-ABT timezone ghosting (found 2026-11-06):** Alberta switched to permanent ABT (UTC-6) Nov 1, 2026. Recurring events created pre-switch carry legacy offsets; moving an instance on a device with a stale tz database writes a **dangling exception** (originalStartTime mismatches the post-switch expansion), leaving the original occurrence alive — visible case: design's "Peer Review 1" biweekly 11:00 on Lemonade keeps the 11:00 hold even after its visible noon move, so the room still declines new 11:00 bookings (can't be force-accepted; rooms won't override "conflicted" responses). Separately observed `csanderson@helcim.com` test bookings that cross ~11:15 ABT on Fri 2026-11-13 being **declined by ALL conference rooms with zero visible occupants** — no blocker found in room calendars; track as unresolved tenant-level anomaly (something day-specific to Nov 13; Tue Nov 17 and 10:00/short bookings on Friday accepted fine). Don't trust zero-conflict declines during a tz transition; probe empirically with test bookings (`addevent` + delete with `sendupdates none doit`).

Granted 2026-11-06: **csanderson@helcim.com = editor ("Make changes to events") on all 15 resource calendars** (request: be able to shuffle rooms for interviews/onboardings). How she uses it: add the room calendars via Calendar → Other calendars → Browse resources; with editor rights she can open any booked room event, remove/swap the room, or create bookings directly on a room calendar.

**Cutting an account off Chat (verified 2026-11-06)** Chat service status is Admin-console only (Apps → Google Workspace → Google Chat → Service status), settable per OU — GAM cannot toggle it. Pattern used for `design@helcim.com`: created OU `/Helcim Service Accounts/Chat Disabled` ("Chat Disabled" = service accounts with Chat turned off; do NOT move humans there), moved the account with `gam create org` + `gam update user <user> ou ...`, then set Google Chat Service status = OFF for that OU in the console. Effect: account can't sign in to Chat, disappears from the Chat picker, and new messages to it are refused; existing DM history stays visible to the other party. The parent OU `/Helcim Service Accounts` has 46 accounts incl. functional shared inboxes (help@, success@, finance@) — do NOT turn Chat off OU-wide without confirming nobody signs into those mailboxes directly.
