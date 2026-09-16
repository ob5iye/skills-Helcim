# Okta LDAP → Jamf Pro user/email lookup → Netskope fix — Runbook

**Goal:** Make Okta the source of user identity in Jamf so that when a Mac enrolls (your zero-touch PSSO flow), Jamf auto-fills the user's **name + email** onto the computer record — no manual entry — and that `$EMAIL` feeds the **Netskope** install (which currently fails because its script was built for Active Directory, which Helcim doesn't have).

**What this is / isn't:** Jamf's Okta LDAP link is a **lookup, not a sync** — it does *not* pre-load your whole Okta directory. It fills a computer's User/Location (incl. email) *when that device enrolls and its username matches an Okta user*. That's exactly what Netskope needs. Users show up in Jamf as their devices enroll, not before.

---

## Helcim values (confirm the ⟨blanks⟩ against your own screens)
| Item | Value |
|---|---|
| Okta org | `https://helcim.okta.com` |
| Okta LDAP host / port | `helcim.ldap.okta.com` : `636` (LDAPS / SSL) |
| Base DN | `dc=helcim,dc=okta,dc=com` |
| Users search base | `ou=users,dc=helcim,dc=okta,dc=com` |
| Groups search base | `ou=groups,dc=helcim,dc=okta,dc=com` |
| Bind (service) account | `jamf-ldap@helcim.com` — dedicated, read-only admin, **MFA-exempt** |
| Bind DN | `uid=jamf-ldap@helcim.com,dc=helcim,dc=okta,dc=com` |
| Test user | `sdoe@helcim.com` (local acct `sdoe`), loaner `C7RQFYWHYG` |
| Netskope tenant URL | ⟨addon-<tenant>.goskope.com⟩ |
| Netskope Org Key | ⟨from Netskope admin⟩ |
| Netskope pref domain/file | `com.helcim.netskope` → `/Library/Managed Preferences/com.helcim.netskope.plist` |

---

## Phase 1 — Okta: enable the LDAP Interface (+ MFA-exempt bind account)
1. Okta Admin → **Directory → Directory Integrations → Add Directory → Add LDAP Interface.** (If it's not offered, the LDAP Interface feature must be enabled for the org — self-service in most orgs; otherwise raise with Okta.)
2. Open the LDAP Interface and **record the real values it displays** — Host (`helcim.ldap.okta.com`), Base DN, user/group DNs. Confirm they match the table above.
3. Create a dedicated **service account**, e.g. `jamf-ldap@helcim.com` — active, strong *static* password. This is Jamf's read-only bind account.
4. **Exempt the bind account from MFA** — LDAPS simple bind can't answer an MFA prompt, so with MFA on the bind just fails:
   - Okta → **Security → Networks → Add Network Zone** → add the **Jamf Cloud IP ranges for your instance's AWS region** (pull the current list from Jamf's Cloud-hosted IP documentation for your region).
   - Okta → the **authentication/sign-on policy** that applies to the service account → **exempt that network zone from MFA** (or put the account in a group governed by a password-only policy from that zone).
5. *(Optional, enables shortname matching in Phase 3)* Add a custom Okta attribute `mailNickName` = `String.substringBefore(appuser.userName,"@")`.

## Phase 2 — Jamf Pro: add the Okta LDAP server + mappings
Settings → **System → LDAP Servers → New → Configure manually.**

**Connection**
- Server `helcim.ldap.okta.com` · Port `636` · **Use SSL: ON**
- Authentication type **Simple**
- Distinguished username (bind DN) `uid=jamf-ldap@helcim.com,dc=helcim,dc=okta,dc=com` · password = the service account's

**User Mappings**
- Object Class `inetOrgPerson` · Search Base `ou=users,dc=helcim,dc=okta,dc=com` · Scope **All Subtrees**
- User ID → `uid` · Username → `uid` · Real Name → `cn` · **Email Address → `mail`** (if the Test shows `mail` empty, use `uid`) · Department → `department` · Building → `o` · Position → `title` · UUID → `entryUUID`

**Group Mappings**
- Object Class `groupOfUniqueNames` · Search Base `ou=groups,dc=helcim,dc=okta,dc=com`
- Group ID → `uniqueIdentifier` · Group Name → `cn` · UUID → `entryUUID` · Membership stored in **Group** object, member attr `uniqueMember`, **Use DNs: ON**

**Test tab:** look up `sdoe` (and `sdoe@helcim.com`) → confirm it returns the **email**, and note the exact value the **Username** field returns — you match the computer record to that in Phase 3.

## Phase 3 — Make the computer's username match Okta (the make-or-break step)
Jamf's "collect user & location from LDAP" matches the computer record's **Username** against your LDAP **Username** mapping. In zero-touch PSSO with Require Auth OFF, the record often has **no username** → nothing matches → email stays blank. Fix: stamp the console user onto the record.

**Recommended (match on email = `uid`):** create a **policy** — Trigger **Login**, Frequency **Ongoing** — running:
```bash
#!/bin/bash
u=$(/usr/bin/stat -f%Su /dev/console)
[ "$u" = "root" ] && exit 0
/usr/local/bin/jamf recon -endUsername "${u}@helcim.com"
```
This stamps `sdoe@helcim.com` (= Okta `uid`), so the LDAP match succeeds. Scope to the loaner group first.

**Alternative (match on shortname):** map Jamf **Username → `mailNickName`** (Phase 1.5) and stamp bare `-endUsername "$u"` (`sdoe`). Either works — just keep the record value and the mapped attribute in the *same* form.

## Phase 4 — Turn on LDAP inventory collection + verify
1. Settings → **Computer Management → Inventory Collection → enable "Collect user and location information from LDAP."**
2. On the loaner: run **`sudo jamf recon`** (or just log in, if the Phase 3 policy is scoped).
3. Jamf → the computer → **User and Location** → confirm **Full Name + Email** now populate from Okta. ✅ Manual entry solved, `$EMAIL` ready.

## Phase 5 — Wire Netskope to $EMAIL (drop the AD modes)
1. **Config Profile** → **Application & Custom Settings** → Preference Domain `com.helcim.netskope` → plist with one key:
   - `email` = `$EMAIL`  (lands at `/Library/Managed Preferences/com.helcim.netskope.plist`)
2. **Gate on email present.** Smart Computer Group **"Email populated"**: criteria **Email Address** — *like* — `@`. Scope **both** the config profile **and** the Netskope policy to this group, so they apply only after recon has the email.
3. **Netskope policy** — run `nsclientconfig.sh` in **preference_email** mode (Jamf auto-passes $1–$3):
   - Param 4 = ⟨tenant URL⟩ · Param 5 = ⟨Org Key⟩ · Param 6 = `com.helcim.netskope.plist` · Param 7 = `preference_email` · (Param 8 = `silent_mode` optional)
   - Script then reads `/Library/Managed Preferences/com.helcim.netskope.plist` → `email` and writes Netskope's `nsinstparams.json` — **no dscl/AD calls.**
4. Order at runtime: profile installs → recon → device enters "Email populated" group → Netskope policy runs → install succeeds.

---

## Validation (loaner C7RQFYWHYG / sdoe)
- Jamf computer record shows Full Name + Email from Okta. ✅
- `defaults read "/Library/Managed Preferences/com.helcim.netskope.plist" email` → `sdoe@helcim.com`. ✅
- Netskope policy log: `nsinstparams.json created successfully`; client installs and steers. ✅
- No `dscl /Active Directory` errors in the policy log. ✅

## Gotchas
- **Bind fails / times out** → almost always the MFA-on-bind-account issue; confirm the Jamf Cloud IP zone is exempted (Phase 1.4).
- **Email blank after recon** → the record's Username doesn't match the LDAP Username mapping (Phase 3); check the form (email vs shortname) matches on both sides. Usernames are case-sensitive.
- **`$EMAIL` empty in the plist** → the profile mapped before the email populated; the "Email populated" smart-group gating (5.2) prevents this — re-push after recon.
- **Netskope still tries AD** → a leftover arg is triggering `upn`/`email`/`cli` mode; ensure Param 7 is exactly `preference_email` and you pass no `upn`/`idp`.
- **Okta LDAP is lookup-only** → users appear in Jamf as their devices enroll, not before.

## Sources
- Jamf LDAP mappings for Okta: github.com/cleavenworth gist
- Okta LDAP Interface + MFA-exempt bind (network zone): support.datajar.co.uk
- Okta Device Access OOBE w/ Jamf (username-only without LDAP): iamse.blog
- Netskope email-not-populating & preference_email: community.jamf.com
