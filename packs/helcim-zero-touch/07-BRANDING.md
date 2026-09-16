# Corporate Branding — Okta (Helcim design system, Sep 2026)

## What was applied (live on the default brand)

Settings: **Customizations → Brands** → theme + Pages tab.

| Slot | Value |
|---|---|
| Primary color (buttons) | `#4F1B86` **Plum** |
| Secondary color | `#1A0F4C` **Navy** |
| Logo | Helcim round gradient logomark (`logo-round@2x.png`) — debate: wordmark reads better in the dashboard's fixed WHITE header strip; logomark sharper on the white sign-in card. Currently logomark |
| Favicon | `helcim-bimi-round-smaller` (48px export: `okta/favicon-48.png`) |
| Background | `okta/bg-plum-radial-punchy-1920.jpg` (website-style radial glow). Alternates generated: `bg-plum-radial-1920.jpg` (strict-palette), `bg-plum-1920.jpg`/`bg-navy-1920.jpg` (diagonal family gradients) |
| Heading | "Sign in to Helcim" |
| Username label → "Email" + info tip "Your Helcim email address" | Apparent save issue — verify in Brands → Pages → Sign-in page → Labels |
| Third-generation Sign-In Widget | Enabled (better a11y; lightens primary for disabled/hover states — washed-out button = disabled state, not a bug) |
| Scope of effect | Sign-in/verify/error pages, PSSO registration pages (inherits), dashboard (violet sidebar), email templates |

## Official Helcim palette (from "HEL-Colour palette-010926-154941.pdf", design director)

**Primaries (the only background colors):** Plum `#4F1B86` · Navy `#1A0F4C` · Punch `#F33574`
**Adjacents (gradient blend stops ONLY, inside their own family):** Plum L-1 `#6121A4`, L-2 `#7227C1`, L-3 `#8436D6` · Punch D-1 `#EA2566`, D-2 `#D40D4F`, D-3 `#B20B42` · Navy L-1 `#1E166A`, L-2 `#1F1C89`, L-3 `#242CA6`
**Secondaries (accents only, on dark primary fields, never backgrounds):** Cosmic `#E39EFF` · Electric `#93D5FF` · Zest `#F6F889` (the "h" lime)
**Neutrals (Midnight scale 100–1100):** `#F9F8FE` → `#EEEDF6` → `#D7D5E4` → `#B1AFC5` → `#9A98AF` → `#828098` → `#6D6B7E` → `#575568` → `#413F51` → `#2C2B38` → `#1C1A25`

**Rules that matter:** never blend across color families (my first violet→salmon gradient was non-compliant — replaced); secondaries only on dark fields; keep accents off Punch backgrounds; one accent per headline.

Note: `bg-plum-radial-punchy-1920.jpg` uses two stretch stops (`#9A4FE8` core, `#38125F` corner) to match helcim.com's hero — flagged to design; use `bg-plum-radial-1920.jpg` for strict compliance.

## Assets

- Source kit: `~/Downloads/Helcim-Brand/` (from Lingo: logomarks, poster). Missing: standalone **Logotype PNGs** (Lingo → Logotype section: dark variant for white surfaces + white variant for dark/gradient)
- Generated Okta assets: `~/Downloads/Helcim-Brand/okta/` (favicon-48.png, bg-*.jpg/png)
- Generators: `tools/gen_brand*.swift` in this pack (Swift + AppKit/NSGradient; re-run to regenerate at any size)

## Not done / ceiling

- **Custom URL domain** (`login.helcim.com`) — needs a DNS CNAME; unlocks full sign-in page code editor + removes "Powered by Okta" + vanity URL. Decision pending DNS access. New brand would be created (default brand on the okta.com subdomain can't use custom code)
- Dashboard: "End-User Dashboard layout" sections not yet built (suggested: "New hire essentials" for Everyone; "IT & Security" targeted to IT); Recently used/Favorites rows
- No code editor exists for the dashboard even with a custom domain
