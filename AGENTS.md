# AGENTS Template

## Purpose
This file is a reusable master template for project-level `AGENTS.md` files.
Copy it into a repo root as `AGENTS.md` when you want these instructions to apply to that project.

## Working Style
- Be direct, concise, and factual.
- Do the work instead of stopping at suggestions when the request is actionable.
- Check the repo and org state before making assumptions.
- Prefer small, reversible changes over broad speculative edits.
- When something fails, identify the concrete failure and fix that exact issue.

## Communication
- Do not pretend work was done if it was not verified.
- If you are unsure, say exactly what is known and what is not known.
- When a user asks whether something was created, deployed, or tested, answer literally.
- Call out mistakes clearly instead of defending them.
- Keep final answers short unless more depth is requested.

## Salesforce Rules
- Treat the org as the source of truth for runtime behavior.
- If metadata deploy succeeds but runtime behavior disagrees, verify with SOQL, describe, or Apex before concluding anything.
- For UI work, test in the org after deploy whenever feasible.
- For Flow work, validate trigger conditions carefully and avoid accidental re-entry or over-triggering.
- For Home page components, optimize for the first visible viewport and avoid layouts that require page scrolling to reach the main content.
- For maps and lists, prefer predictable layout behavior over default Salesforce component behavior when the default behavior is poor.

## Safety
- Do not make destructive org or git changes unless explicitly requested.
- Do not delete files, metadata, or records unless the user asked for that outcome.
- Do not mass-edit profiles or security metadata unless necessary; prefer the minimum valid deployment scope.
- When editing metadata XML, preserve valid Salesforce metadata ordering.

## Verification
- After each deploy, verify the result with the smallest useful runtime check.
- If a test was not run, say so explicitly.
- If an org constraint blocks the requested change, explain the actual blocker and the next useful step.

## Preferences
- Prefer `sf` CLI commands in Salesforce projects.
- Prefer targeted deploys over whole-directory deploys.
- Prefer custom LWC layout over default `lightning-map` list behavior when the built-in list causes usability problems.
- Keep the UI practical and compact rather than decorative.

## If Unsure
- Ask one short clarifying question only when a wrong assumption would be costly.
- Otherwise choose the most conservative reasonable implementation and proceed.
