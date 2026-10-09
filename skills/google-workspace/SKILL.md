---
name: google-workspace
description: Helcim Google Workspace administration via GAM7, especially Shared Drive inventory, access audits, nested group membership, limited-access folders, and safe Drive permission cleanup. Use before changing Google Drive sharing or diagnosing Workspace access.
---

# Google Workspace — Helcim

Use this skill for Google Workspace admin and Drive permission tasks. Read `runbooks/google-workspace/Google Workspace Hacks.md` for the local GAM setup and related procedures. Treat Shared Drive and payroll data as sensitive: inspect metadata and ACLs only unless the user explicitly asks for content review.

## GAM7 environment

- GAM7 is installed at `~/bin/gam7/gam`; the configuration and credentials are in `~/.gam/`. Never copy or commit that directory, OAuth files, service-account keys, tokens, or credential JSON.
- GAM uses GCP project `it-services-474319` (IT Services), client OAuth as `aobsiye@helcim.com`, and a service account with Workspace domain-wide delegation. Health check: `gam user aobsiye@helcim.com check serviceaccount`.
- The delegated setup has broad scopes, including write-capable scopes. Use read-only commands for investigation; treat write commands as production changes and verify before/after.
- Current Workspace customer ID and inventory counts are time-sensitive; retrieve them live with `gam info domain` and `gam print shareddrives` rather than relying on old counts.

## Safe Shared Drive permission cleanup

### 1. Confirm the request and exact scope

Before changing anything, identify the exact Shared Drive or folder, the principals to remove, the intended keepers, and whether the request is folder-only or drive-wide. A Shared Drive membership change affects the whole drive. Do not remove a person or group from the entire drive to solve a folder-specific request.

Payroll and employee-compensation data require extra care. Confirm the requester/owner's intent and expected keepers before editing access. Never assume the request means the requester cannot see the folder; read the actual form text and attachment if available.

### 2. Inventory and trace access paths

GAM7's current command names use `shareddrives`, not the older `teamdrives` aliases:

```bash
gam print shareddrives matchname "^Accounting$"
gam print shareddriveacls matchname "^Accounting$"
gam user <member@helcim.com> info teamdrive <sharedDriveId>
gam user <member@helcim.com> show drivefileacls <folderId>
gam user <member@helcim.com> print drivefileacls <folderId>
gam user <member@helcim.com> print fileparenttree <fileId>
gam print group-members group <group@helcim.com>
```

- `organizer` = Manager; `fileOrganizer` = Content manager. Confirm the actual role names in the API output, not just the UI label.
- For every target's access, distinguish direct file/folder grants from inherited Shared Drive membership. `permissionDetails.inherited` and `inheritedFrom` identify inheritance when returned.
- Expand group membership recursively. A group can contain nested groups, so check each nested group until all user paths are known. There is no per-user deny rule that overrides access inherited through a group.
- Use `gam user <known member> print filelist select <folderId> depth 1 fields id,name,mimetype,modifiedtime` to enumerate a folder tree as a member. Use `print fileparenttree <fileId>` to establish the full path of a found item.
- Avoid treating a zero-result Drive search as proof that a file/folder is absent. Search queries can miss nested or otherwise non-returned items. For an absence check, enumerate the relevant drive tree with an authorized member, filter the local metadata listing, and verify the scope/coverage. Large drive inventories can take time and contain sensitive filenames; keep temporary reports local and remove them when done. Never put payroll listings into Git.

### 3. Choose a folder-only isolation pattern when needed

If the intent is to remove one person from one folder while preserving the rest of the drive:

1. Save a baseline of the folder ACL and drive membership locally (do not commit sensitive reports).
2. Confirm who must retain access, including service accounts/integrations and every user inherited via groups.
3. Use Google Drive limited access on that folder, which GAM exposes as:
   ```bash
   gam user <driveManager@helcim.com> update drivefile <folderId> inheritedpermissionsdisabled true
   ```
4. Expect inherited Shared Drive permissions to stop providing normal content access to the limited folder. In the observed Helcim case, inherited non-organizer members appeared as reader/shadow ACL entries and could not list contents. Existing direct grants/organizer behavior may differ; inspect the effective ACL after the change.
5. Re-add the keepers explicitly at their required roles. If a broad group contains the excluded person, do **not** grant that group back. Instead grant an approved narrower subgroup and/or the known individual members who should retain access, excluding the target. Keep service accounts only if the data owner confirms they need this folder.
6. Do not disable limited access again until all group paths to the excluded user are understood; restoring inheritance can silently restore their access.

Example ACL commands (verify GAM help/syntax and principal IDs before use):

```bash
gam user <folderManager@helcim.com> create drivefileacl <folderId> user <keeper@helcim.com> role fileOrganizer
gam user <folderManager@helcim.com> create drivefileacl <folderId> group <approved-group@helcim.com> role fileOrganizer
gam user <folderManager@helcim.com> delete drivefileacl <folderId> <principalEmail>
```

A folder-only allowlist is an operational trade-off: future Shared Drive members do not automatically gain normal access to the limited folder. Assign an owner to maintain the allowlist and review it when staff/groups change.

### 4. Verify effective access, not just the ACL display

After changes:

- Re-read folder ACLs and confirm the limited-access flag and each intended principal/role.
- Test as the excluded user: their folder listing should return no items (or otherwise show no content access).
- Test as representative intended keepers—including one member who previously got access through a group, and any relevant service account—to confirm expected folder contents remain available.
- Recheck nested groups after any group change. A direct allowlist that accidentally re-adds a broad group can restore the excluded user's access.
- Record the exact before/after state and any trade-offs in the ticket; do not resolve the ticket until the requester confirms the outcome when the requested access model is ambiguous.

## Case study — ITS-838 payroll folder (2026-10-09)

This is a cautionary example and current-state breadcrumb, not a universal policy:

- Gelo Perante's request was to remove `jjariwala@helcim.com`, `finance-dept@helcim.com`, and `finance@helcim.com` from the Payroll folder, not to report that he could not find it.
- The resource was `Accounting` Shared Drive (`0AGmh4Kam0MMCUk9PVA`) → `07_Payroll` folder (`1qepxBNYod9lmf422Z4BAaQorz-EW4RAx`). Payroll content was nested inside Accounting. A drive-root-only or search-only check falsely suggested there was no Payroll folder; an authorized recursive listing found it and current payroll register files.
- The original folder permissions were inherited from the Accounting Shared Drive. Disabling inheritance exposed role changes; keepers had to be explicitly restored to Manager/Content manager roles.
- `jjariwala@helcim.com` was in `finance-ops-team@helcim.com`, nested under `finance-dept@helcim.com`. Re-adding `finance-dept` to the folder restored Jaivik's access. The final folder configuration therefore kept limited access, did not grant the broad `finance-dept` group normal content access, and explicitly restored the approved Finance/reporting members/groups instead. Jaivik was tested and returned zero folder items; Gelo and approved keepers were tested for visibility.
- Re-linking `finance@helcim.com` was specifically requested by Gelo because it is Finance Reporting's functional address. Future admins should verify the service account's workflow ownership with the data owner; do not remove or retain it based only on the email name.
- When Gelo clarified that he wanted the original setup except Jaivik, the group nesting meant literal inheritance could not satisfy that requirement. The solution approximated the original effective access with a scoped allowlist. Explain that future members will require explicit folder grants.
- The user later said the Payroll access change should be specific to the Payroll folder and wanted `finance@helcim.com` linked back. Preserve that scope; do not remove members from the whole Accounting drive.

Do not assume ITS-838 was commented on or resolved: the work in this session changed Drive permissions, but no Jira comment/transition was performed.
