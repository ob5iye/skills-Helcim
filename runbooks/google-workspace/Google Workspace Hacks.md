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
