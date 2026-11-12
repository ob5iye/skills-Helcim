# Shared Drive Consolidation Tracker

Goal: every department drive ends up as **team newsletter group = Content manager** + **team lead = direct Manager**, and the `ac-*` tier groups get retired. Success team is the pilot (started 2026-11-12, review ~2026-12-12). If no complaints, work down this list.

Baselines scanned 2026-11-12 (pre-pilot). Drive IDs pulled from `gam print shareddrives` / `print shareddriveacls asadmin`.

## Status legend
- ✅ done
- 🔍 ready to flatten (group-based ACL exists, just needs swap)
- 🧹 needs mapping (users only today, decide which team group is the anchor)
- ⏸ on hold / not in scope (project, evidence, external-share drives)

## Department drives

| # | Shared drive / Story | Anchor group (Content manager) | Lead Manager (direct) | Current gate groups | Status |
|---|---|---|---|---|---|
| 1 | MX - Success | `mx-success-team@` | `mgonzaga@` | was `ac-mx-success-*`, removed | ✅ |
| 2 | Sales | ITSP-119 | `mx-sales-team@` | pmclellan (confirm) | `ac-mx-sales-{reporter,developer,maintainer}`, `ac-mx-owner` (organizer) | 🔍 |
| 3 | MX - Support | ITSP-120 | `mx-support-team@` | askosareva (confirm) | `mx-dept@`(fileOrganizer), `finance-dept@`(fileOrganizer) — odd, review | 🔍 |
| 4 | Product | ITSP-121 | `productteam@` (exclude `productbot`) | tbd (confirm with leads) | `ac-product-{owner,maintainer,developer,reporter,dept}` | 🔍 |
| 5 | Credit Risk Team | ITSP-122 | `ts-credit-team@` | tbd | `ac-ts-creditrisk-{reporter,developer,maintainer}` (owner tier feeds via Trust & Safety drive) | 🔍 |
| 6 | Trust and Safety | ITSP-122 | `trustandsafety-dept@` | tbd | `ac-tns-fraud-owner`, `ac-ts-dept`, `ac-ts-creditrisk-owner` (all organizers) | 🔍 |
| 7 | Design - Department | ITSP-123 | `design-dept@` | rferrocasagrande (confirm) | `ac-design-dept`(fileOrganizer), `ac-design-owner`(organizer) | 🔍 |
| 8 | Design - Asset Library | ITSP-123 | `design-dept@` | same | adds `ac-helcim-team@`(reader, = whole company?) — verify before touching | 🔍 |
| 9 | Development | ITSP-124 | `dev-dept@` | jnewfeld/bpopkey (confirm) | `ac-dev-dept`(fileOrganizer), `aobsiye-admin@`(writer) | 🔍 |
| 10 | Data & Analytics | ITSP-125 | `data-dept@` | mnar (confirm) | `data-dept@`(fileOrganizer) + 3 direct users | 🔍 nearly flat already |
| 11 | Marketing - Department | ITSP-126 | `marketing-dept@` | tbd | `ac-marketing-owner`(fileOrganizer), `ac-marketing-dept`(organizer) | 🔍 |
| 12 | Operations - Supply Chain | ITSP-127 | `operations-supchain-team@` | pwoods (confirm) | `ac-operations-dept`(fileOrganizer) | 🔍 |
| 13 | Operations - Project Team | ITSP-127 | `operations-project-team@` | ctennant (confirm) | `ac-operations-dept`(fileOrganizer) | 🔍 |
| 14 | Operations - Office Admin | ITSP-127 | `operations-admin-team@` | pwoods/schiang (confirm) | `ac-operations-dept`(fileOrganizer) | 🔍 |
| 15 | Cybersecurity | ITSP-128 | `cybersecurity_department_mailing_list@` | cfinnson (confirm) | already group-based + 3 direct users | 🔍 nearly flat |
| 16 | Infrastructure | ITSP-129 | `infrastructureteam@` | tbd | `ac-security-dept`, `ac-it-dept` (both fileOrganizer) — cross-team, review | 🔍 |
| 17 | Corporate IT | ITSP-129 | `it-dept@` | tbd | `it-dept@`(fileOrganizer) + `ac-it-support-reporter@`(organizer, suspicious) | 🔍 |
| 18 | Finance | ITSP-130 | `finance-dept@` | tbd | 15 direct users, no group | 🧹 |
| 19 | Legal | ITSP-131 | `legalteam@` | tbd | 6 direct users, no group | 🧹 |
| 20 | People and Culture | ITSP-132 | `people.n.culture-dept@` | tbd | 5 direct users, no group | 🧹 |
| 21 | Partnerships | ITSP-133 | `partnersteam@` | tbd | 11 direct users, no group | 🧹 |
| 22 | Machine Learning | ITSP-133 | `mlteam@` | tbd | 11 direct users, no group | 🧹 |
| 23 | DevOps | ITSP-133 | `devops@` | tbd | 6 direct users, no group | 🧹 |
| 24 | QA | ITSP-133 | part of `dev-dept@`? confirm | tbd | 3 direct users, no group | 🧹 |
| 25 | Compliance | ITSP-133 | `complianceteam@` | tbd | 12 direct users, no group | 🧹 |
| 26 | Information Security | ITSP-128 | `cybersecurity_department_mailing_list@`? confirm vs Compliance | tbd | `it-dept@`(writer, suspicious) + 11 direct | 🧹 |
| 27 | Training | ITSP-133 | training/onboarding owner? | tbd | 2 direct users | 🧹 |
| 28 | MX Leads | ITSP-133 | `mx-dept@`? or leads list | tbd | 2 direct users | 🧹 |
| 29 | Growth / Content / Brand Work | ITSP-126 | confirm owners | tbd | scattered users; `Content` has `ac-marketing-dept@`(organizer) | 🧹 |

## Explicitly out of scope for now
PCI evidence drives, Board/Legal-sensitive (Helcim Board Data, Series C Diligence), external-share drives (External User Drive, Helcim <> Neubreed, Switch & Google Team), call-recording archives, backups (Asana/Slite/Q10/G-Suite/Quickbooks), test drives (Cordell's test, Test RClone, Test Shared Drive), one-merchant drives.

## Procedure per drive (proven on MX - Success)
1. Backup current ACL: `gam print shareddriveacls` row + member list of every group on it into runbooks/google-workspace/backups/<thing>-<date>.csv`.
2. Add anchor group: `gam user aobsiye-admin@helcim.com add drivefileacl <driveId> group <group> role fileorganizer asadmin`.
3. Add/promote lead direct: `... add drivefileacl <driveId> user <lead> role organizer asadmin`.
4. Remove old group + duplicate user entries: `... delete drivefileacl <driveId> <email> asadmin`.
5. If pilot-pattern approved for that dept: strip users from the `ac-*` tier groups, keep nested group links, save pre-removal lists.
6. Verify: print ACL, then update this tracker, commit, push.

## Open questions to resolve before flatten
- `ac-design-owner@`, `ac-marketing-owner@`, `ac-mx-owner@` etc. still gate their drives AND sit inside reporter chains; deleting empty groups optional, keep shells until pilot proves out.
- Ghost ACLs (blank-name fileOrganizer entries from deleted accounts) exist on at least MX - Success; sweep them during each drive's flatten.
- `ac-helcim-team@` (reader on Design Asset Library): likely "everyone at Helcim" — replacing with `staff@` may be the cleanest equivalent.
