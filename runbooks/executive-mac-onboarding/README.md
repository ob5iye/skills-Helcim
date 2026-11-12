# Executive Mac Onboarding (Windows -> macOS switcher)

Created 2026-11-12 for the CEO's move from Windows to MacBook. Goal: a
white-glove first week so the Mac feels *better* than Windows, not just
different. Reusable for any senior Windows switcher.

Companion docs: `CRASH-COURSE.md` (hand to the user), the zero-touch SOP
(`hacks/helcim-zero-touch/04-SOP-NEW-USER-DEVICE.md`) for the enrollment itself.

---

## 1. Before handover (IT, ~45 min)

Standard chain first — run the zero-touch SOP top to bottom (Okta handover
password via `psso-setpass.sh`, ABM -> PSSO-Sandbox PreStage, PSSO-Pilot
group). Then the exec-specific extras:

| Step | Why |
|---|---|
| Pre-stage in Jamf: Chrome, Slack, Zoom, Google Drive for desktop, 1Password, Okta Verify, Netskope, Microsoft 365 (Word/Excel/PowerPoint/Outlook) | Zero downloads on day one. Execs will not open Self Service unprompted. |
| Put Chrome, Gmail/Calendar web apps, Slack, Zoom, Drive, 1Password, Excel/Word, System Settings in the Dock **in that order**; remove the Apple defaults he will never use (Music, TV, Podcasts, Freeform, News, Stocks) | A clean Dock is the single biggest "this feels made for me" moment. |
| Install Chrome as default browser and let him confirm the prompt during the walkthrough (macOS 26 requires user confirmation) | Matches fleet standard; Okta EA "SSO extension for Chrome" needs Chrome 146+. |
| Enable Touch ID for unlock + Apple Pay off (unless he wants it) + Stage Manager off | Keep the window model simple for a Windows user. |
| System Settings -> Trackpad: **Tap to click ON**, **Secondary click = bottom-right corner**, Tracking speed up one notch | Right-click confusion is the #1 switcher complaint. |
| System Settings -> Desktop & Dock: **Click wallpaper to reveal desktop = Only in Stage Manager**; Minimize windows into application icon ON | Stops accidental "where did my windows go" moments. |
| Keyboard -> Keyboard Shortcuts -> Modifier Keys: leave default. Do NOT swap Cmd/Ctrl — it breaks muscle memory on every other Mac he touches | Teach `Cmd` = old `Ctrl` instead (covered in course). |
| Set up Mail/Calendar via Chrome web apps (Gmail/Calendar "Install as app") rather than Apple Mail unless he insists | Google Workspace is the system of record; Apple Mail with Google labels confuses people. |
| 1Password: install browser extension, sign him in, turn on Touch ID unlock | Password friction kills adoption. |
| Migrate Windows data: Chrome profile sync (bookmarks/passwords already follow him), Downloads + Desktop + Documents into Google Drive **before** he leaves the PC, OneDrive content moved to Drive | Do not use Migration Assistant from a corp Windows PC — it drags junk and breaks the clean PSSO enrollment. |
| Pair AirPods / Bluetooth mouse if he uses one; test external monitor + dongle he actually owns | Monitor plug-in failures on day one are fatal to goodwill. |
| Test: Touch ID unlock, Okta FastPass sign-in with no password, Zoom camera/mic, screen share permission in Privacy & Security granted for Zoom + Slack + Chrome | Screen-recording permission prompts mid-board-meeting look terrible. |
| Printer added (if he prints), AirPrint tested | Execs print. |

## 2. Recommended app stack

**Already deployed by Jamf (fleet standard)**
- Okta Verify (Platform SSO / Touch ID / FastPass), Netskope client, Google Chrome

**Core work apps (push via Jamf App Installers / Self Service)**
- Slack, Zoom, Google Drive for desktop, 1Password 8 + browser extension
- Microsoft 365 for Mac (Excel is what he will actually open from board decks)
- Keynote / Numbers / Pages are preinstalled — mention Keynote can open PowerPoint

**Windows-comfort utilities (free or cheap; approve + push via Self Service)**
| App | What it replaces | Note |
|---|---|---|
| **Rectangle** (free) | Windows Snap (drag window to edge, Win+Arrow) | macOS 15+ has native tiling too, but Rectangle's shortcuts are closer to Windows. Pick one; do not install both. |
| **AltTab** (free) | True Alt-Tab across *windows*, not apps | macOS Cmd-Tab switches apps only. This is the fix most switchers want. |
| **Raycast** (free tier) | Windows Start search / PowerToys Run | Optional; Spotlight is fine for most. Skip unless he is a power user. |
| **Maccy** (free) | Windows clipboard history (Win+V) | macOS has no native clipboard history. |
| **Scroll Reverser** (free) | Windows scroll direction for an external mouse | Only if he uses a mouse; the "Natural scrolling" toggle flips the trackpad too. |
| **Microsoft Remote Desktop / Windows App** | Any legacy Windows-only tool | Keep as a parachute. |

Everything above should be in a **"Switching from Windows"** category in Jamf
Self Service so he (or his EA) can add them later without a ticket.

## 3. Handover session (30 min, in person, IT + CEO)

1. Power on, Wi-Fi, Okta sign-in with handover password (the only time he types it), Touch ID enrollment. Let him watch FastPass bind.
2. Walk the Dock left to right; open each app once so permission prompts fire while you are there.
3. Live demo of the five gestures (course section 2) and the Cmd-not-Ctrl rule.
4. Show Spotlight (`Cmd-Space`) -- "this is your Start menu."
5. Show how to AirDrop/Universal Clipboard from his iPhone if he has one -- this is the "wow" that Windows cannot do.
6. Leave the printed one-page cheat sheet (section 9 of the crash course).
7. Book a 15-min check-in on day 3 and day 10. Day 3 fixes friction; day 10 is when habits form.

## 4. Week-one support plan

- Dedicated Slack DM or channel `#ceo-mac` with IT; response SLA same-hour during the first two weeks.
- IT walks past his desk once a day for the first week (no ticket needed).
- Keep the old Windows laptop powered off but **not wiped** for 30 days as a safety net; wipe after sign-off.

## 5. Things NOT to do

- Do not swap Cmd/Ctrl modifier keys.
- Do not enable Stage Manager, Hot Corners, or Mission Control gestures beyond defaults on day one.
- Do not install Rectangle *and* Magnet *and* native tiling -- pick one.
- Do not use Apple Migration Assistant from a managed Windows PC.
- Do not leave Apple default apps (Music/TV/News) in the Dock.

## Change history

- 2026-11-12 -- created for CEO Windows->Mac migration.
