# Google Workspace Hacks

A running collection of fixes and tips for Gmail, Groups, Calendar, and other Workspace tools.

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
