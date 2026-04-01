# Scratch Org Workflow Handover

## Scope
This handover describes a reusable workflow for starting from an existing Salesforce org, creating a scratch org for feature work, and keeping local folders, Git branches, and Salesforce targets aligned.

It is intentionally generic. It should be usable across projects, repos, sandboxes, dev orgs, and scratch-org feature streams.

## Core Rule
Never let one local source tree silently serve multiple orgs that have different source-alignment expectations.

If work is moving into a scratch org, assume by default that the scratch-org effort needs:
- its own local workspace
- its own branch
- its own explicit `target-org`
- a clear statement of which local folder is aligned to which org

## What "Aligned" Means
A local workspace is aligned to an org only when all of the following are true:
- the local source is intended to represent that org's metadata state
- the local Git branch is the branch being used for that org-specific work
- the local Salesforce CLI config points to that org as `target-org`
- the user is editing the correct local folder for that org

If any of those are false, there is drift risk and it must be called out explicitly before continuing.

## Standard Roles
Use these neutral terms when reasoning about the workflow:
- `source org`: the org the feature starts from
- `scratch org`: the isolated org created for feature work
- `source workspace`: the local folder aligned to the source org
- `scratch workspace`: the local folder aligned to the scratch org
- `source branch`: the branch used for source-org-aligned work
- `scratch branch`: the branch used for the scratch-org feature effort

## Recommended Flow
### 1. Identify the source org
Decide which org is the source of truth at the start of the work.

Typical examples:
- sandbox
- dev org
- existing scratch org

Do not create a scratch org before stating which org the current local source is aligned with.

### 2. Check source alignment first
Before creating the scratch workflow, verify:
- which local folder is open
- which Git branch is checked out
- which Salesforce org is the local `target-org`
- whether the local source is actually aligned with the chosen source org

If the local source is not aligned with the chosen source org, stop and say so before proceeding.

### 3. Create an isolated scratch workspace
If the user wants a scratch org for feature work, create:
- a separate local folder, clone, or worktree
- a clearly named scratch branch
- a local Salesforce config that points to the scratch org

The source workspace should continue to represent the source org.
The scratch workspace should represent the scratch org.

Do not keep using a source-org-aligned workspace as the implementation workspace for a scratch org unless the user explicitly approves that shared-source model after the risk is explained.

### 4. Copy guidance files into the new workspace
When creating the scratch workspace, copy:
- `AGENTS.md`
- any other project-level guidance or workflow documents that should follow the workspace

Do not assume a new clone or worktree already contains the intended working guidance state.

### 5. Create or connect the scratch org
Use the scratch workspace, not the source workspace, when setting up the scratch org.

Minimum checks:
- confirm the intended Dev Hub
- confirm the scratch-org alias
- confirm the scratch workspace `target-org`
- confirm the user knows which local folder is now tied to the scratch org

### 6. Stop for missing org dependencies
Before changing source, check whether the target org is missing:
- fields
- field-level security
- settings
- feature activations
- licenses
- app or page activation
- permission assignments

If a dependency is missing, stop and report the blocker instead of changing source to fit the org.

Examples of valid blockers:
- a required feature is not enabled
- a field exists but is not usable because FLS is missing
- a page exists but is not active for the intended app/profile

### 7. Build in local source first, then deploy to the scratch org
Normal order:
1. edit local source in the scratch workspace
2. deploy targeted metadata to the scratch org
3. verify runtime behavior in that same scratch org
4. retrieve back only if admin or UI changes were made directly in the org

Do not treat direct org edits as complete until they are represented in the aligned local source when that change is intended to persist.

### 8. Keep Git lightweight
Minimum useful Git for a scratch workflow:
- one isolated local workspace
- one scratch branch
- local commits at stable checkpoints
- push when backup, collaboration, or PR visibility is useful

A separate GitHub repository is not required by default.

### 9. Verify final alignment
At the end of setup, or after a major workflow shift, verify:
- source workspace points to the source org
- scratch workspace points to the scratch org
- branch names are explicit
- remotes are correct
- the user is in the intended folder in the editor
- each workspace is either clean or its remaining changes are clearly explained

## Practical Checks
### Check the current folder
```bash
pwd
```

### Check Git branch and cleanliness
```bash
git branch --show-current
git status --short
```

### Check Git remote
```bash
git remote -v
```

### Check local Salesforce targets
```bash
sf config list
```

### Check scratch org access
```bash
sf org display --target-org <scratch-org-alias>
```

### Check authenticated orgs
```bash
sf org list
```

## Common Failure Modes
### 1. Wrong local folder is open
Symptom:
- status bar shows the wrong org
- edits are happening in the wrong local workspace

Fix:
- open the intended folder explicitly
- re-check `pwd`, branch, and `sf config list`

### 2. Scratch branch exists locally but not remotely
Symptom:
- local branch is present
- remote hosting service does not show the branch

Fix:
- check whether the scratch workspace remote points to the real remote or to a local clone
- push the branch only after verifying the remote

### 3. Git push fails even though the SSH key is correct
Symptom:
- Git host accepts the key but the push still fails in automation or a different shell

Likely cause:
- the key is passphrase-protected and not loaded in the shell session being used

Fix:
```bash
ssh-add ~/.ssh/<your-key>
ssh-add -l
git push -u origin <scratch-branch>
```

### 4. Field exists in metadata but fails at runtime
Do not assume the field is missing.

Check:
- FLS
- object permissions
- runtime describe or SOQL
- whether the actual target user can access it

### 5. Metadata deployed but UI still does not show it
Check:
- activation
- app assignment
- tab visibility
- page assignment
- permission-set or profile access

## Handover Summary
If starting from a sandbox, dev org, or any other source org and moving into a scratch org for a feature:
1. identify the source org
2. verify the current local workspace is aligned to it
3. create a separate scratch workspace
4. copy `AGENTS.md` and other guidance files into it
5. create a scratch branch there
6. point that workspace to the scratch org
7. stop for missing settings, features, FLS, or activation instead of changing source
8. edit locally in the scratch workspace, deploy to the scratch org, and verify there
9. keep source and scratch workspaces separate until intentionally merged
