# Netskope IdP (SAML) Enrollment Mode — the new standard

## Why the switch

**Old (legacy):** `nsclientconfig.sh` in preference_email mode needed the user's email at install time → chain of stamp policy → `jamf recon -endUsername` → Jamf LDAP lookup (Okta) → `$EMAIL` → managed plist `/Library/Managed Preferences/com.netskope-client.plist` → script reads it. Five moving parts, racing the install on every new device → repeated failures (Carolina's Mac, Anna's wiped Mac).

**New (IdP mode):** client installs silently, then enrolls the user through an **Okta SAML sign-in at first launch**. Identity comes straight from Okta — no stamping, no LDAP, no $EMAIL. With FastPass enrolled (guaranteed by PSSO), the sign-in = one Touch ID tap. Netskope-side user records are **created at enrollment** (no SCIM needed for pilot; add SCIM later for deprovisioning at production).

Final parameter map (official Netskope Jamf doc layout; keyword= is mandatory — bare values are ignored):

| Param | Value | Notes |
|---|---|---|
| 4 | `idp` | lowercase, case-sensitive; script branches on `$4` |
| 5 | `goskope.com` | domain only |
| 6 | `helcim` | tenant name only |
| 7 | `0` | don't prompt for email (SAML provides identity) |
| 8 | `enrollencryptiontoken=<token>` | from MDM Distribution → Secure Enrollment |
| 9 | `ENFORCEENROLLSTEERINGPROFILEID=<UUID>` | restrictive pre-enrollment steering profile — anti-ignore enforcement |
| 10 | `ENFORCEENROLLFREQUENCY=<1min–24h>` | re-prompt interval until enrolled |
| 11 | `mode=scheme` | external-browser auth → real browser → FastPass/Touch ID works (v20+ scripts) |

**Script version caveat:** the nsclientconfig.sh copy in Jamf is v22.0 — it has no `ENFORCEENROLL*` handling. Download the latest `JAMFScripts` bundle from the Netskope docs/support page and replace the script body before relying on params 9/10. Params 4–8 + 11 work on v22.

## Jamf deployment pattern (self-healing remediation loop)

- **Smart group:** `Netskope - Not Installed` = `Application Title does not have "Netskope Client.app"` (type the value; placeholder text doesn't count)
- **Policy** = "Netskope – IdP Pilot" (rename to "Netskope Install (IdP)" at production):
  - Payloads: script (**Priority: Before**, params above) + NSClient.pkg (Install, Cloud Distribution Point)
  - Triggers: **Recurring Check-in** (+Login optional). `sudo jamf policy` only fires Recurring Check-in; Login-triggered policies need `sudo jamf policy -event login`
  - Frequency: **Ongoing** (safe because scope self-empties)
  - **Maintenance → Update Inventory ✓** — without it the Mac stays in the group and reinstalls at every check-in until daily recon
  - Scope: the smart group ONLY (targets union — remove direct computer/static-group targets)
- Flow: missing client → in group → install at check-in → recon → leaves group → never touched again. Failures self-retry next check-in.
- **Flush policy logs** after frequency/scope changes or "Completed"-with-no-payload runs.

## Pre-flight before production rollout

1. Okta "Netskope Client Enrollment - SAML Forward Proxy" app: **Assign to Groups → Everyone** (was 6 individuals — unassigned users get "app not assigned" at enrollment = Ana-class failure fleet-wide)
2. **Disable** the legacy email-mode install policy (do not delete = rollback path); otherwise two policies race the same pkg
3. Existing enrolled clients are unaffected — they never re-enter the "Not Installed" group
4. Users without FastPass complete enrollment via password + their normal MFA — works fine, FastPass just makes it a tap
5. Cleaning a previous half-install on a test device: Netskope `jamfuninstall.sh` (same scripts bundle)

## Verification

- Client menu bar = Protected/enabled; `/Library/Application Support/Netskope/STAgent/nsidpconfig.json` exists
- `systemextensionsctl list` → `[activated enabled]`
- Netskope console → Users: user record appears at enrollment with device attached
- Jamf policy log Details should show: "Installation is configured for Idp mode install" → token matched lines → package install:
  ```
  Running script nsclientconfig.sh...
  Installation is configured for Idp mode install
  matched enrollencryptiontoken / IDP browser mode
  IdP Service Provider Domain is goskope.com
  IdP Service Provider Tenant key is helcim
  Downloading NSClient.pkg... Successfully installed NSClient.
  ```
  Then the browser opens: "Sign in with your account to access Netskope Client Enrollment - SAML Forward Proxy" = expected enrollment sign-in, not an error.

## Straggler visibility (optional, build for scale)

Extension Attribute detecting "client installed but not enrolled" (check STAgent config / `nsdiag -o`) → smart group → optional recurring policy to relaunch enrollment UI. Nuclear option `fail-close` exists but is deliberately deferred (can brick onboarding if connectivity/IdP hiccups).
