# Okta Platform SSO on macOS via Jamf — Build Checklist

**Org:** helcim.okta.com
**Goal:** Let Macs sign in with Okta and sync the local password with Okta (Platform SSO / PSSO), deployed by Jamf Pro.

> "Platform" = **macOS**. The iOS/Android screen under *Endpoint management* is unrelated — ignore it.
> Do the phases **in order**. Phases 1–3 are the same for everyone; only Phase 4 depends on your Mac's OS version.

---

## Decide one thing first: your loaner's macOS version

- **macOS 26 (Tahoe)** → you can use **Simplified Setup** (creates the first user right at Setup Assistant). Use **Phase 4B**. Needs Jamf 11.20+.
- **macOS 14 or 15** → **standard PSSO**: enroll normally, user signs in to register. Use **Phase 4A**.

---

## Phase 1 — Okta admin console

1. [ ] Confirm **Okta Device Access** is enabled. *(You already have an active SCEP config, so this is done.)*
2. [ ] Add the app integration: **Applications → Browse App Catalog → "Platform Single Sign-On for macOS"** (a.k.a. Desktop Password Sync) → Add.
3. [ ] Open that app → **General / Sign On** tab → copy the **Client ID**. You'll paste it into Jamf in Phase 3.
4. [ ] **Security → Device Integrations → Device Access tab →** your **Dynamic SCEP URL – Generic** config. Record four values:
   - SCEP URL
   - Challenge URL
   - Username (`okta-PYGYN4`)
   - Password *(shows once; if you don't have it, use **Actions → regenerate** — but only if it's not already deployed, or you'll break existing devices)*

## Phase 2 — Okta Verify (MDM build)

5. [ ] In the Okta admin console, download the **MDM-deployable Okta Verify 9.5.2 for macOS**. **Do NOT use the App Store version.**
6. [ ] Jamf Pro → **Settings → Computer Management → Packages** → upload the Okta Verify `.pkg`.

## Phase 3 — Build two configuration profiles (Computers → Configuration Profiles)

### Profile A — "Okta SCEP" (Computer level)

7. [ ] **General:** name it; Level = **Computer Level**.
8. [ ] **SCEP payload:**
   - URL = *(SCEP URL from Okta)*
   - Redistribute profile = **30 days** before expiry *(Okta can't auto-renew — this is your renewal)*
   - Challenge type = **Dynamic – Microsoft CA**
   - Challenge URL = *(Challenge URL from Okta)*
   - Username / Password = *(from Okta)*
   - Subject = `CN=$COMPUTERNAME ODA $UDID`
   - Key Size = **2048**
   - Check **Use as digital signature**
   - Uncheck **Allow export from keychain**; check **Allow all apps access**
9. [ ] **Scope** = loaner group. Save.

### Profile B — "Okta Platform SSO" (Computer level)

10. [ ] **General:** Level = **Computer Level**.
11. [ ] **Single Sign-On Extensions payload:**
    - Payload type = **SSO**
    - Extension identifier = `com.okta.mobile.auth-service-extension`
    - Team identifier = `B7F62B65BN`
    - Sign-on type = **Redirect**  *(not Credential)*
    - **URLs:**
      - `https://helcim.okta.com/device-access/api/v1/nonce`
      - `https://helcim.okta.com/oauth2/v1/token`
    - Use Platform SSO = **Enabled**; Authentication Method = **Password**
    - Registration Token = *any random string* (required but unused — the SCEP cert stands in)
    - Enable: registration during setup, create first user during setup, Use Shared Device Keys, Identity Provider Authorization
    - User mapping: AccountName = `macOSAccountUsername`; FullName = `macOSAccountFullName`
12. [ ] **Associated Domains payload:**
    - `B7F62B65BN.com.okta.mobile.auth-service-extension`
    - `B7F62B65BN.com.okta.mobile`
    - `authsrv:helcim.okta.com`  *(the `authsrv:` prefix is required)*
13. [ ] **Application & Custom Settings** — add two preference domains:

    **`com.okta.mobile`**
    ```xml
    <plist version="1.0">
    <dict>
      <key>OktaVerify.OrgUrl</key>
      <string>https://helcim.okta.com</string>
      <key>OktaVerify.UserPrincipalName</key>
      <string>$USERNAME</string>
      <key>OktaVerify.PasswordSyncClientID</key>
      <string>CLIENTID</string>
    </dict>
    </plist>
    ```

    **`com.okta.mobile.auth-service-extension`** (same keys **plus** ProtocolVersion)
    ```xml
    <plist version="1.0">
    <dict>
      <key>OktaVerify.OrgUrl</key>
      <string>https://helcim.okta.com</string>
      <key>OktaVerify.UserPrincipalName</key>
      <string>$USERNAME</string>
      <key>OktaVerify.PasswordSyncClientID</key>
      <string>CLIENTID</string>
      <key>PlatformSSO.ProtocolVersion</key>
      <string>2.0</string>
    </dict>
    </plist>
    ```
    → Replace `CLIENTID` with the Client ID from Phase 1, step 3.
14. [ ] **Scope** = loaner group. Save.

## Phase 4 — Deploy to the loaner & test

### 4A — macOS 14 / 15 (standard)

15. [ ] Make sure the loaner is enrolled in Jamf and in the loaner group.
16. [ ] Confirm delivery: Okta Verify installed, SCEP cert in **Keychain Access → System**, both profiles show *Installed*.
17. [ ] Open Okta Verify → sign in → follow the prompt to enable Platform SSO / register.
18. [ ] Lock/log out → log back in with the Okta password to confirm PSSO + password sync.

### 4B — macOS 26 (Simplified Setup — first user at Setup Assistant; needs Jamf 11.20+)

15. [ ] **PreStage Enrollment:** check **Enable Simplified Setup for Platform Single Sign-on**; set **Platform SSO App Bundle ID = `com.okta.mobile`**.
16. [ ] Add **Okta Verify as an Enrollment Package** on the PreStage. *(Critical — Setup Assistant won't reach the PSSO screen until it's installed.)*
17. [ ] Attach **Profile A + Profile B** to the PreStage's Configuration Profiles.
18. [ ] **Erase/wipe** the loaner and re-enroll via ADE. At Setup Assistant it should prompt for Okta sign-in and create the first local account from the Okta identity.

## Verify (both paths)

- [ ] SCEP cert present in System keychain
- [ ] Login / unlock works with the Okta password
- [ ] Changing the Okta password syncs to the Mac login

## Notes / gotchas

- **No auto-renewal:** Okta-as-CA doesn't renew certs — the redistribute window is what replaces them.
- **Redirect vs Credential:** PSSO uses **Redirect + URLs**. A **Credential** type with a **Realm** (e.g. "Okta Device") is the *separate device-trust extension* — don't mix them into this profile.
- Confirm the Redirect/URL field names against Okta's current PSSO doc before you roll past the loaner (field labels shift a little by Jamf version).
