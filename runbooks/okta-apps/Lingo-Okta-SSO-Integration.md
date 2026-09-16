# Okta SSO Integration — Lingo (Helcim)

**App:** Lingo · **Identity Provider:** Okta · **Protocol:** SAML 2.0
**Lingo space / org name:** `helcim` · **Owner:** Abdi Obsiye (aobsiye@helcim.com)
**Status:** Okta app fully configured; cutover email sent to Lingo Support (Brad Root) with IdP metadata — hard transition scheduled for Tuesday 2026-08-25 (PDT)
**Last updated:** 2026-08-24

---

## 0. Current state snapshot (2026-08-24)

- **Okta SAML app "Lingo" is created and fully configured** — all SP values confirmed by Brad Root (Lingo/Noun Project) via email; they match section 3 exactly.
- **Attribute statements are set** — `FirstName`, `LastName`, `Email` (see section 4 and the UI gotcha in 4.1).
- **IdP metadata URL:** `https://helcim.okta.com/app/exk26c4fn4jncR4Yr1d8/sso/saml/metadata` — sent to Brad.
- **Access model decided: ONE Okta group (`lingo-users`)** grants access to the app; roles are managed entirely inside Lingo. See section 8 for the reasoning.
- **Open item:** Lingo shows All Users (138) but Admins (3) + Content Managers (9) + Members (125) = 137. Find user #138 before cutover and make sure they're in the Okta group.
- **Open questions asked of Brad:** (a) does JIT auto-provisioning work the same on the Okta connection as it did with Google? (b) is SCIM or group-to-role mapping available?
- **Not live until Lingo flips the switch** — clicking the chiclet before Brad enables SSO will fail; that is expected, not a misconfiguration.

---

## 1. Overview / what we're doing

Lingo single sign-on is set up as a **SAML 2.0** application in Okta, with **Okta acting as the Identity Provider (IdP)** and **Lingo as the Service Provider (SP)**.

The key thing to understand about Lingo's SSO is that it is **support-driven**:

- There is **no self-serve ACS URL** exposed in the Lingo admin portal.
- The SP values (Audience URI, ACS URL) are **issued by Lingo Support** and are documented below.
- The **final connection is completed on Lingo's end** once you send them your Okta IdP metadata — Lingo flips the switch.

Users are matched to their Lingo accounts by **email address**. This email-matching is also what makes this the clean cutover path from the existing **Google SSO → Okta** (as long as Okta sends the same email addresses Google did, users keep their accounts, content, and roles).

---

## 2. Prerequisites

- **Okta admin access** — to create app integrations and assign users/groups.
- **Lingo admin access** for the `helcim` space.
- The **SP values issued by Lingo Support** (documented in section 3 below).
- A **Lingo Support contact** — support@lingoapp.com, or the in-app "Contact us" chat.

---

## 3. Service Provider (SP) values — from Lingo

These were provided by Lingo Support and are specific to the Helcim space.

| Field | Value |
|---|---|
| **Audience URI (SP Entity ID)** | `https://lingoapp.com` |
| **ACS URL (Single sign-on URL)** | `https://api.lingoapp.com/v4/saml/sso/44` |
| **Name ID format / SAML Subject** | Unspecified (any value — Lingo matches on the Email attribute) |

> **Note on the `/44`:** The `/44` at the end of the ACS URL is the **Helcim space identifier**. It is specific to our Lingo space, which is why it does not appear as a generic value anywhere in the portal — it had to come from Lingo Support.

---

## 4. SAML attribute statements — CASE-SENSITIVE

The attribute **Name** (left column) must match **exactly**, including capitalization. A wrong name or a single wrong letter case **will cause the integration to fail**.

| Name (case-sensitive) | Name format | Value (Okta expression) |
|---|---|---|
| `FirstName` | Unspecified | `user.firstName` |
| `LastName` | Unspecified | `user.lastName` |
| `Email` | Unspecified | `user.email` |

### 4.1 UI gotcha — attribute statements in the current Okta version (2026.08.x, OIE)

The current Okta admin UI can make this step painful. What actually works:

1. **The app-creation wizard may not show an Attribute Statements section at all.** If it's missing, just finish creating the app — attributes can be added afterwards.
2. On the app's **Sign On** tab there is an **Attribute statements** section with an **"Add expression"** dialog. **Do not use it** — its validator rejects standard expressions like `user.lastName` with "Invalid property lastName" (a known quirk of Okta's new unified-claims UI).
3. Instead, at the bottom of that section click **"Show legacy configuration"** — this reveals the classic Name / Name format / Value table. Add the three rows there. When the Value column offers a dropdown, **pick the attribute from the list** rather than typing it.
4. In the "Add expression" dialog (if ever used elsewhere), **Name and Expression are separate fields** — the Name is `FirstName`, the Expression is only `user.firstName`; do not paste combined text.

---

## 5. Okta configuration steps

1. In the Okta **Admin** console, go to **Applications → Applications → Create App Integration**.
2. Select **SAML 2.0**, then **Next**.
3. **General Settings:** set **App name = `Lingo`** (logo optional). Click **Next**.
4. **Configure SAML → General:**
   - **Single sign-on URL:** `https://api.lingoapp.com/v4/saml/sso/44` — keep **"Use this for Recipient URL and Destination URL"** checked.
   - **Audience URI (SP Entity ID):** `https://lingoapp.com`
   - **Default RelayState:** leave blank.
   - **Name ID format:** `Unspecified`
   - **Application username:** `Okta username` (default is fine — Lingo matches users on the Email attribute, not the subject).
5. **Attribute Statements:** add the three rows from section 4 above, **exactly** as written. This section is at the bottom of the "SAML Settings" card. If it's hard to find, click **Hide Advanced Settings** or search the page for "Attribute Statements". Attributes can also be added after creation via **Applications → Lingo → General → SAML Settings → Edit**.
6. Click **Next**, choose **"I'm an Okta customer adding an internal app"**, then **Finish**.

---

## 6. Assign users / groups

**Decided design (2026-08-24): a single access group.**

- **One Okta group, `lingo-users`, contains everyone who may sign in to Lingo.** Assign it via **Applications → Lingo → Assignments → Assign to Groups**.
- We originally created three role groups (`Lingo - Admins`, `Lingo - Content Managers`, `Lingo - Members`) but scrapped them: Okta groups **cannot push roles to Lingo** (no role attribute in the SAML payload), and promotions made inside the Lingo dashboard **do not sync back** to Okta — so role groups would drift out of date immediately and enforce nothing. One access group + roles managed in Lingo is the honest model.
- An earlier idea to include department in group names (`apps-department-role`) was also rejected: departments cut across apps and create naming explosions. Convention adopted: **app-role groups as `app-<app>-<role>` (lowercase, hyphens), department groups separately as `dept-<name>`, service accounts as `svc-<purpose>`** — but for Lingo specifically, only the single `lingo-users` access group exists.

**New-user onboarding flow (JIT):** add the person to `lingo-users` → they click the Lingo chiclet on their Okta dashboard → Lingo auto-creates their account on first login via email matching, with default Member access → only if they need more, promote them manually on the Lingo Users page. **No account creation or invite step in Lingo.** (Pending Brad's confirmation that JIT behaves the same on the Okta connection as it did with Google.)

---

## 7. Complete the connection with Lingo

Because the SP side is support-driven, the integration isn't live until Lingo enables it:

1. On the Lingo app's **Sign On** tab in Okta, copy the **Identity Provider metadata** URL: `https://helcim.okta.com/app/exk26c4fn4jncR4Yr1d8/sso/saml/metadata` ✅ **(sent to Brad Root on 2026-08-24, along with a cutover request for Tuesday 2026-08-25, PDT)**
2. Brad / Lingo Support enables the Okta connection for the `helcim` space and confirms.
3. **Until that confirmation, clicking the Lingo chiclet will fail — expected, not a misconfiguration.** Only test after Brad says it's enabled.

**Cutover-day runbook (2026-08-25):**
1. Brad flips the `helcim` space from Google to Okta and confirms.
2. Abdi clicks the Lingo chiclet on his Okta dashboard → should land signed in with correct first name, last name, and email on the profile.
3. Verify existing content and role survived (proves email matching worked).
4. Have one Content Manager and one Member do the same check.
5. Send the team a heads-up: Lingo login now goes through the Okta dashboard.

---

## 8. Roles (Admin / Content Manager / Member)

Lingo's SAML attributes are limited to `FirstName`, `LastName`, and `Email` — **there is no role attribute in the SSO payload**. Therefore:

- Roles are **managed inside Lingo**, not passed from Okta. Lingo's own Users page is the source of truth for who holds which role.
- New SSO users receive the space's **default access** (currently: added as **Members** with access to **6 portals**).
- Role changes are a manual step in the Lingo dashboard, and they do **not** sync back to Okta (one more reason the Okta side only has the single `lingo-users` access group — see section 6).
- **Do not add Group Attribute Statements** in the SAML settings — Lingo ignores them; there is nothing to gain.
- Current role counts (2026-08-24): Admins 3 · Content Managers 9 · Members 125 (= 137, but All Users shows 138 — one user to reconcile).
- If Brad confirms **SCIM provisioning** or **Okta-group-to-role mapping** exists (question sent 2026-08-24), revisit: at that point, recreating `app-lingo-admin` / `app-lingo-contentmanager` groups as a provisioning source becomes worthwhile.

---

## 9. Cutover from Google SSO → Okta (hard transition)

Because Lingo matches users by **email address**, users keep their existing Lingo accounts as long as Okta sends the same email addresses Google did.

1. **Build and verify the Okta app ahead of the transition** ✅ (app built, attributes verified in legacy configuration, Abdi assigned and chiclet visible on his dashboard — full login test only possible after Brad enables the connection).
2. On the **transition day (2026-08-25)**, Brad / Lingo switches the `helcim` space from the Google connection to the Okta connection (**Lingo controls this switch**).
3. **Verify** per the runbook in section 7, then the whole team is already covered — everyone is assigned through the `lingo-users` group ahead of time.

---

## 10. Verification checklist

- [ ] A test user assigned in Okta can launch Lingo from their Okta dashboard and land signed in. *(only testable after Brad enables the connection)*
- [ ] First name, last name, and email display correctly on the Lingo profile (confirms attributes).
- [ ] An existing user keeps their prior Lingo content and role after cutover (confirms email matching).
- [ ] One Content Manager and one Member spot-check their own login + role after cutover.
- [ ] User #138 reconciled (All Users count vs. 3+9+125) and included in `lingo-users`.

---

## 11. References & contacts

- **Lingo help article — Configuring SSO with Okta:** https://help.lingoapp.com/en/articles/13656263-configuring-sso-with-okta (per Brad: screenshots slightly out of date — Okta now tucks attributes behind extra clicks; see section 4.1)
- **Lingo Support:** support@lingoapp.com (or in-app "Contact us" chat)
- **Lingo contact for this cutover:** Brad Root (Noun Project) — same time zone (PDT); confirmed all SP values by email on 2026-08-24

---

*Source: "Okta SSO Integration Runbook — Lingo (Helcim)" project runbook. This file consolidates everything captured so far about the Helcim Okta setup and the Lingo SSO integration.*
