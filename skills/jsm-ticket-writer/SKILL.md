---
name: jsm-ticket-writer
description: Turn a raw pasted issue into a Helcim JSM (ITS) ticket via the Atlassian MCP. Ticket text rules — never use colons, hyphens/dashes, or semicolons; minimal wording; always assigned to Abdi Obsiye.
---

# JSM Ticket Writer — Helcim ITS

Use when the user pastes a raw issue or request and wants it filed as a ticket
in the Helcim JSM service desk (project **ITS**). Rewrite, create, report back.
No preview or confirmation round-trip — the flow is paste → ticket.

## Banned characters (Summary and Description)

These three characters must NEVER appear anywhere in the ticket text:

- `:` colon
- `-` hyphen or dash (also the long forms `–` `—`)
- `;` semicolon

Scan the final summary and description for them before every create call.
If any are found, rewrite. No exceptions, even if the pasted issue uses them.

## Wording rules

- Minimal wording. Trim filler, courtesy, and repetition.
- No "please", "thanks", "can someone", "as soon as possible".
- Summary is one line, under 10 words, states the problem plain.
- Description is 1 to 3 short lines, one fact per line.
- Never invent facts. Trim and reword only what the user gave.

## Rewrite cheatsheet

| Pasted | Write instead |
|---|---|
| `Summary: X` | just `X` |
| `zero-touch` | `zero touch` |
| `floor 4 - west side` | `floor 4 west side` |
| `one; two` | two lines or `one then two` |
| `Mon-Fri` | `Mon to Fri` |
| `re: printer` | drop it |

## Template shape

Description uses plain lines, no labels, no bullets (bullet markers are hyphens):

```
<what is broken or being requested>
<who or what is affected, include reporter name if given>
<what should happen next, if the user stated one>
```

Example.

Raw paste: "Hey can you make a ticket: the boardroom A projector keeps
cutting out mid-call - Marisela from finance flagged it, been happening
since Monday; probably needs a new cable or repair"

Summary: `Boardroom A projector cuts out during calls`

Description:

```
Boardroom A projector cuts out during calls
Flagged by Marisela in finance, happening since Monday
Check cable and signal connection, arrange repair if needed
```

## Create call

MCP server `devin/atlassian-mcp-server`, tool `createJiraIssue`:

| Field | Value |
|---|---|
| cloudId | `5b0727ab-0d7a-42ea-8f77-6d56032fab31` |
| projectKey | `ITS` |
| issueTypeName | `Task` (default) |
| summary | rewritten summary |
| description | rewritten lines (default markdown format is fine) |
| assignee_account_id | `712020:1150c54c-3917-4790-8189-1aa953c50e12` (Abdi Obsiye) |

Other ITS types if the user names them: IT Incident Report, IT Request Type
No Approval, IT Request +1 Manager Approval, Employee onboarding, Employee
offboarding, Return to Work, Re-Hire. Stick to Task unless told otherwise.

## Report back

Keep the chat reply short as well:

1. Ticket key and URL `https://helcim.atlassian.net/browse/ITS-NNN`
2. The exact summary text used

If the create call fails, say why and retry once with simpler description text.
