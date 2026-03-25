# AGENTS.md

## Purpose
This file defines the default working rules for this repository.
These instructions are always in effect unless the user gives a more specific instruction for the current task.

## Core Principles
- Be direct, concise, and factual.
- Do the work when the request is actionable.
- Prefer small, reversible changes over broad speculative edits.
- Do not guess when a fact can be checked.
- Treat verified behavior as more important than assumptions.

## Scope Control
- Only change what is required to complete the requested task.
- Do not modify existing behavior outside the requested scope unless the user explicitly approves it.
- If a broader fix seems necessary, stop and explain the reason before making unrelated changes.
- Do not introduce refactors, cleanup, renames, or style-only edits unless they are required for the requested outcome.
- When a request is ambiguous, choose the most conservative valid implementation.

## Salesforce Environment
- Always remember this project runs on Salesforce platform rules and constraints.
- Do not assume that behavior from JavaScript, Java, SQL, HTML, or other ecosystems applies the same way in Salesforce.
- When documentation is needed, prefer current official Salesforce documentation as the source of truth.
- Treat the org as the source of truth for runtime behavior.
- If deployed metadata and runtime behavior disagree, verify with SOQL, describe, Apex, debug logs, or UI validation before concluding anything.
- Preserve valid Salesforce metadata structure and ordering when editing XML.

## Security And Access
- Treat security and visibility as part of the definition of done for every new tab, field, object, app item, page, flow entry point, Apex endpoint, and UI surface.
- Do not assume new metadata is visible or usable just because it deploys successfully.
- When creating or changing tabs, verify tab visibility, app navigation inclusion, and user/profile/permission-set access in the target org.
- When creating or changing objects or fields, verify object permissions, field-level security, record type impact, layout visibility, and any permission set or profile updates required for the intended users.
- When creating or changing LWCs, Aura components, flows, or Apex-backed UI, verify CRUD/FLS implications, runtime access, and whether additional permission metadata is required.
- If a change needs new access, prefer the narrowest safe permission set or targeted security update instead of broad profile changes unless the user explicitly wants profile-based configuration.
- Never stop at metadata creation when access is likely required; either apply the needed security change or explicitly report that access remains to be configured.

## Working Method
- Check the repo state before making assumptions.
- Check the org state before making assumptions when the task depends on runtime or deployed behavior.
- Never guess which Salesforce org, alias, or environment to use; resolve it explicitly before running org actions.
- Prefer targeted changes over large sweeping updates.
- Identify the exact failure or requirement first, then fix that exact issue.
- Do not leave related broken references behind.

## Related Component Review
- When editing an LWC, inspect its HTML, JS, CSS, XML meta file, tests, labels, and any directly connected Apex or message/channel usage.
- When editing an Apex class, inspect related tests, callers, selectors, triggers, queueables, flows, and metadata dependencies.
- When editing a Flow, inspect entry criteria, trigger conditions, formulas, field dependencies, and risks of re-entry or duplicate execution.
- When a change is made, review related code and metadata to identify anything that also needs to be updated, anything that became inconsistent, and anything that became obsolete.
- Remove code or configuration only when it is clearly obsolete because of the requested change; if it may be obsolete but is not certain, flag it explicitly before deleting it.

## Documentation And Facts
- Do not guess platform behavior, governor limits, metadata syntax, LWC support, security behavior, or deployment rules.
- Verify uncertain facts in current official documentation before acting.
- If documentation is unclear or conflicting, say so explicitly and choose the safest implementation.
- If a known fact cannot be verified during the task, state that limitation instead of presenting assumptions as truth.

## Safety
- Do not make destructive git changes unless explicitly requested.
- Do not delete files, metadata, records, org configuration, or tests unless the user asked for that outcome.
- Do not mass-edit profiles, permission sets, or security metadata unless necessary for the request.
- Prefer the minimum valid deployment scope.
- Never claim something is deployed, tested, or created unless it was actually verified.

## Verification
- After each deploy, perform the smallest useful runtime verification.
- When deployment is performed, verify in the same target org that received the change.
- For Apex changes, run the most relevant tests available.
- For LWC or UI changes, verify in the org whenever feasible.
- For Flow changes, validate the trigger path and check for unintended repeat execution.
- If a test was not run, say so explicitly.
- If deployment was not done, say so explicitly.
- If verification was blocked, explain the exact blocker and the next useful step.

## Communication
- Do not pretend work was done if it was not verified.
- If unsure, say exactly what is known and what is not known.
- Answer literally when asked whether something was created, deployed, or tested.
- Call out mistakes clearly instead of defending them.
- Keep final answers short unless more detail is requested.

## Preferences
- Prefer `sf` CLI commands in Salesforce projects.
- Prefer targeted deploys over whole-directory deploys.
- Prefer practical and compact UI over decorative UI.
- Prefer predictable custom layouts over default Salesforce component behavior when the default behavior creates usability problems.
- For Home pages, optimize the first visible viewport and avoid layouts that require scrolling to reach the main content.

## If Unsure
- Ask one short clarifying question only when a wrong assumption would be costly.
- Otherwise proceed with the safest conservative implementation and explain the assumption afterward.
