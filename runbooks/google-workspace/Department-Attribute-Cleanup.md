# Department Attribute Cleanup — Google Workspace

**Snapshot:** 2026-10-16, generated with GAM7 (`~/bin/gam7/gam`) against the Helcim tenant (customer `C02twm3z6`, Google Workspace Enterprise Standard, 245 licensed users).
**Owner:** Abdi Obsiye. **Status:** list compiled, **no attributes changed yet** — every edit below needs HiBob confirmation first.

## Why this list exists

Goal: replace hand-maintained team email lists + `ac-*` Shared Drive security groups with **one dynamic group per department** (email address + Shared Drive member + optional Security label). Pilot = Product team.

Dynamic groups are only as correct as the `organizations[].department` attribute on each user, and today that attribute is **hand-edited** in Google (users are created manually by `nstewart-admin@`; departments are edited manually — audit log shows e.g. `smacisaac` department changed from `Product` to `VP of Product` by `aobsiye-admin@`). Okta does **not** push profile attributes to Google (it only pushes the `gcp_*` groups).

Google Workspace **already has 10 dynamic groups** (convention: `dg-<department>@`, Security label on, query `department=='X' && suspended==false && is_guest_user==false`), so the pattern is proven in-tenant. See the groups-landscape section in `skills/google-workspace/SKILL.md`.

**Live proof of the risk:** `jatwal@` and `mbaculi@` have department `Data` instead of `Data and Analytics`. They are in the static `data-dept@` but are **silently excluded** from the existing dynamic `dg-data-and-analytics@` (9 members instead of 11).

## Department attribute values today (active humans only)

| Count | Value | Note |
|---|---|---|
| 56 | Software Development | has `dg-software-development@` |
| 25 | Merchant Experience | |
| 13 | Marketing | |
| 11 | Sales | org question D1 — department or MX sub-team? |
| 10 | Product | pilot |
| 9 | Data and Analytics | has `dg-data-and-analytics@` |
| 8 | Finance | |
| 8 | Trust and Safety | |
| 8 | Design | |
| 5 | IT Infrastructure | has `dg-infrastructure@` |
| 5 | Operations | |
| 3 | Cybersecurity | has `dg-cybersecurity@` |
| 3 | Channel Partnerships | has `dg-channelpartnerships@` |
| 2 | People and Culture | |
| 2 | Credit Risk | org question D2 |
| 2 | Compliance & Legal | |
| 2 | **Data** | variant → B |
| 1 | **People & Culture** | variant → B |
| 1 | **Compliance and Legal** | variant → B |
| 1 | **VP of Product** | title in department field → B |
| 1 | Special Projects | Operations sub-team → C |
| 8 | **(blank)** — humans | → A |
| 57 | (blank) — service accounts, bots, `*-admin` accounts, kiosk/test | expected, leave blank |

---

## A. Humans with a blank department (8)

| User | Name | Evidence (department-type groups they are in) | Proposed value | Confidence |
|---|---|---|---|---|
| `jnadal@` | John Nadal | `productteam`, `ac-product-developer` | **Product** | high |
| `jtaylor@` | Jeff (JT) Taylor | `productteam`, `ac-design-product-reporter`, `slt` | **Product** (SLT member — confirm title) | high |
| `tpham@` | Tran Pham | `design-product-team`, `ac-design-product-developer/-reporter` | **Design** | high |
| `tsingh@` | Tarun Singh | `dev-mobile-team`, `ac-dev-core`, `ac-developers`, `ac-dev-mh`, `gcp_software_development` | **Software Development** | high |
| `hbeare@` | Hailey Beare | `mx-sales-team`, `ac-mx-sales-developer/-reporter` | **Sales** or **Merchant Experience** — depends on D1 | high |
| `psingh@` | Prashant Singh | `cybersecurity_department_mailing_list`, `gcp_cybersecurity`, `ac-security-analyst-reporter` | **Cybersecurity** | high |
| `edeacon@` | Eleni Deacon | **no department groups at all** (only company-wide lists) | unknown — check HiBob (new hire / contractor?) | low |
| `nbeique@` | Nicolas Beique (CEO) | `ac-exec.suite-ceo`, `executiveteam`, + visibility seats on `finance-dept`, `legalteam`, `trustandsafety-dept` … | decision: `Executive` or intentionally blank (`staff@`/`townhall@` match him by name, not department) | n/a |

## B. Spelling variants that split a department (4 values, 5 users)

| Current value | Users | Canonical value | Why |
|---|---|---|---|
| `Data` | `jatwal@` (Jasmeen Atwal), `mbaculi@` (Mary Baculi) | **Data and Analytics** | 9 others use it; `dg-data-and-analytics@` queries this exact string — these two are excluded today |
| `People & Culture` | `rallan@` (Richard Allan, title Contractor) | **People and Culture** | 2 others use it |
| `Compliance and Legal` | `sdavis@` (Stephanie Davis) | **Compliance & Legal** | 2 others use it |
| `VP of Product` | `smacisaac@` (Seamus MacIsaac) | department **Product**, title **VP of Product** | title was written into the department field (audit log, `aobsiye-admin@`) |

## C. Attribute contradicts group membership — confirm with HiBob (8)

| User | Name | Attribute says | Groups say | Likely resolution |
|---|---|---|---|---|
| `tdriscoll@` | Theresa Driscoll | Merchant Experience | `finance-report-team`, `ac-finance-reporting-*`, `gcp_finance_department`; **not** in `mx-dept` | **attribute wrong → Finance** |
| `oklymas@` | Olha Klymas | Marketing | `design-systems-team`, `ac-design-brand-*`, `ac-design-systems-*`, `gcp_marketing_ops`, `gcp_software_development`; **not** in `marketing-dept` | **probably Design** — HiBob decides |
| `ctennant@` | Connor Tennant | Special Projects | `ac-operations-sp-*`, `operations-project-team`, `equipmentteam`, `mx-dept`; OU `/Payment Extension Development` | **Operations** (Special Projects is an Operations sub-team) |
| `nadams@` | Noah Adams | IT Infrastructure | `ac-dev-owner`, `ac-dev-leaders`, `devops`, `platformengineering`, `gcp_devops_engineer`, `dg-infrastructure` | ambiguous — DevOps/Platform Eng under IT Infra or Software Dev? HR call |
| `mrussell@` | Miranda Russell | Operations | `gcp_vp_of_ops`, `ac-operations-owner`, `ac-exec.suite-cos`; also owner of `ac-marketing`, member of `marketing-dept` | **attribute correct**; Marketing seats are exec visibility → exception case, not a fix |
| `mparker@` | Maximilian Parker | Software Development | all dev groups + `design-systems-team` | **attribute correct**; `design-systems-team` is cross-functional |
| `vzhyhula@` | Viktoriia Zhyhula | Design | `design-product-*` + `dev-nova-team`; OU `/Payment Extension Development` | **attribute correct**; `dev-nova-team` is cross-functional |
| `sdavis@` | Stephanie Davis | Compliance and Legal | compliance/legal groups + `mx-dept`, `mxleaders` | **attribute correct** (fix spelling, B); MX seats are cross-functional |

Net: **3 real corrections** (`tdriscoll`, `oklymas`, `ctennant`); the other 5 are cross-functional memberships that a department-only query cannot express (see "Exceptions" below).

## D. Org-structure decisions needed before building `dg-*` groups (3)

| # | Question | Today | Options |
|---|---|---|---|
| D1 | Is **Sales** (11 users, incl. `pmclellan` Head of Sales) its own department or a Merchant Experience sub-team? | `mx-dept@` / `ac-mx-dept@` contain both Sales and MX people | (a) separate dept → create `dg-sales@`, MX groups become MX-only; (b) sub-team → set department = `Merchant Experience`, carry `Sales` in title or a team attribute |
| D2 | Is **Credit Risk** (`jraza`, `rfournier`) inside Trust and Safety? | `ts-credit-team@` exists as a T&S sub-team; `trustandsafety-dept@` does not include them | likely department = `Trust and Safety`, team = Credit Risk |
| D3 | Is **Channel Partnerships** (`jwynn`, `ldeleon`, `tedworthy`) inside Marketing? | has its own `dg-channelpartnerships@` **and** all three sit in `marketing-dept@` | keep separate dept; if Marketing wants them on its list, make `dg-marketing@` query `Marketing \|\| Channel Partnerships` |

## E. Suspended accounts still sitting in groups (4)

Dynamic groups remove these automatically (`suspended == false`). Static groups need manual removal.

| Account | Name | Still in |
|---|---|---|
| `phunter@` | Paula Hunter | `productteam`, `ac-product-dept`, `ac-product-maintainer`, `mx-dept` — **and still a Manager (organizer) on the Product Shared Drive** |
| `cyates@` | Callum Yates | `ac-mx-dept` |
| `smastrovito@` | Sandra Mastrovito | `trustandsafety-dept`, `ac-ts-dept`, `ts-credit-team` |
| `tcruz@` | Tim Cruz | `data-dept`, `ac-data-dept` |

## F. People missing from their own department's lists (the manual-add failure)

Across 14 departments / 41 lists: **77 "department says yes, list says no"** and **56 "in list, department says otherwise"**. Humans only; role-tier groups (`ac-dev-core`, `ac-developers`) and sub-team lists excluded.

| Department | List | Missing (attribute says they belong) |
|---|---|---|
| Product | `ac-product-dept@` | `bmattas`, `mkissinger` — **tested: neither can see the Product Shared Drive** |
| Software Development | `dev-dept@` | `dcardinal-ext` |
| Software Development | `ac-dev-dept@` | `bgupta`, `czheng`, `dcardinal-ext`, `dwilkinson`, `eboulanger`, `psadlon`, `ssingh` |
| Merchant Experience | `mx-dept@` | `gasejo` (+ `tdriscoll`, see C) |
| Marketing | `marketing-dept@`, `ac-marketing-dept@` | `eilnicki`, `tfraser` (+ `oklymas`, see C) |
| Trust and Safety | `trustandsafety-dept@` | `jhoward` |
| IT Infrastructure | `it-dept@`, `ac-it-dept@` | `nadams`, `pthadakamalla`, `zudoumoren` (3 of 5) |
| Operations | `operations-dept@` | `htanade`, `mrussell`, `ssandhu` (3 of 6) |
| People and Culture | all three P&C groups | `rallan` |
| Compliance & Legal | `ac-compliance@`, `complianceteam@` | `pveilleux` |
| Compliance & Legal | `legalteam@` | `rlavendermead`, `sdavis` |

**Onboarding pattern:** of the 7 users created in the last 120 days (`tfraser`, `eilnicki`, `arazzini`, `gasejo`, `dwilkinson`, `arahman`, `htanade`), **5 are missing from at least one of their department's groups**. The user gets created; the group adds get forgotten.

---

## Exceptions a department-only dynamic group cannot express

Found in this audit — these must be designed for, not "fixed":

- **Exec visibility seats:** `nbeique` on `finance-dept`/`legalteam`/`trustandsafety-dept`; `mjunioread` on `ac-data-dept`/`complianceteam`/`legalteam`; `mrussell` on `marketing-dept`.
- **Cross-functional members:** `mparker` → design-systems; `vzhyhula` → dev-nova; `sdavis` → MX; `ctennant` → MX/equipment.
- **Service accounts:** `productbot@` (in `productteam@`), `aurora@` (in `ac-dev-dept@`), `aobsiye-admin@` (in `ac-it-dept@`).

Options: (1) a multi-value custom-schema attribute (the tenant already has `Flex_Details.Roles`, used by the dynamic `app-hubspot@`) OR'd into the query; (2) for Shared Drives, add the odd bot/exec directly as an individual member; (3) for bots, set `department` on the bot's admin-controlled profile. Dynamic groups **cannot** take manual members and **cannot** be nested, so "dynamic group + a static wrapper for exceptions" is not possible.

## Proposed fix commands (dry-run — do NOT run until HiBob confirms)

GAM replaces the whole `organizations` list on update, so always pass the existing `title` along with `department`. Syntax verified against the GAM7 wiki: `organization [type work] [title <String>] [department <String>] primary`.

```bash
GAM=~/bin/gam7/gam
# A — blanks (high confidence)
$GAM update user jnadal@helcim.com   organization type work department "Product" primary
$GAM update user jtaylor@helcim.com  organization type work department "Product" primary
$GAM update user tpham@helcim.com    organization type work department "Design" primary
$GAM update user tsingh@helcim.com   organization type work department "Software Development" primary
$GAM update user psingh@helcim.com   organization type work department "Cybersecurity" primary
# hbeare — after D1:  department "Sales"  or  "Merchant Experience"
# edeacon, nbeique — after HiBob / decision

# B — variants (titles preserved)
$GAM update user jatwal@helcim.com    organization type work department "Data and Analytics" primary
$GAM update user mbaculi@helcim.com   organization type work department "Data and Analytics" primary
$GAM update user rallan@helcim.com    organization type work department "People and Culture" title "Contractor" primary
$GAM update user sdavis@helcim.com    organization type work department "Compliance & Legal" primary
$GAM update user smacisaac@helcim.com organization type work department "Product" title "VP of Product" primary

# C — after HiBob confirmation
$GAM update user tdriscoll@helcim.com organization type work department "Finance" primary
$GAM update user ctennant@helcim.com  organization type work department "Operations" primary
# oklymas — Design or Marketing per HiBob
```

**Ordering warning:** if Okta → Google *Update User Attributes* is switched on later, Okta will overwrite these values with whatever HiBob/Okta holds. Either fix the values in HiBob first, or make the GAM edits and the Okta mapping change in the same window — otherwise the first push can revert this work.

## How to regenerate this audit

```bash
GAM=~/bin/gam7/gam
$GAM print users fields primaryemail,name,organizations,suspended,archived,orgunitpath > /tmp/users.csv
$GAM print groups fields email,name,description,directmemberscount > /tmp/groups.csv
$GAM print cigroups fields groupkey,displayname,labels,dynamicgroupmetadata > /tmp/cigroups.csv   # dynamic/security labels + queries
$GAM print users query "orgDepartment=Product" fields primaryemail,organizations                  # one department
$GAM print group-members group <list>@helcim.com recursive noduplicates                            # flattened list membership
$GAM print shareddriveacls oneitemperrow fields emailaddress,role,type                            # which groups sit on which drives
$GAM user <email> info shareddrive <driveId>                                                       # "Shared drive not found" = no access
$GAM report admin start -120d event CHANGE_USER_ORGANIZATION                                       # who edits departments
```

Then diff `department` sets against flattened list membership per department (humans = not in `/Helcim Service Accounts`, `/Helcim Bot`, `/Super Admin`, `/Chrome OS Kiosk`, `/Helcim MOBILE MANAGEMENT TEST`; not suspended/archived). Keep raw output local; it is employee data.

## Change log

- **2026-10-16** — Audit run, list compiled, saved here. No attributes or groups changed. Full per-list diff also saved locally at `~/Downloads/dept-attribute-vs-DL-diff.txt` (not in Git).
