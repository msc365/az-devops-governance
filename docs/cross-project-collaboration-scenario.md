# A limited cross‑project collaboration scenario

This article describes a **clean, practical, Azure DevOps design** for a limited cross‑project collaboration scenario:

> Project `portugal` owns a repo, and needs to invite only a small subset of users from project `netherlands` to collaborate on _one_ repository; without granting them full access to project `portugal`.

This is a classic **limited cross‑project collaboration** scenario. Azure DevOps doesn't provide repo‑level isolation natively, but with proper permission scoping you can achieve a "least‑privileged collaboration bubble".

## Recommended Architecture

## 1. Keep the repository in project `portugal`

- Do **not** mirror/duplicate it
- Do **not** move the other team into project `portugal`

Instead:

- project `portugal` keeps ownership
- project `netherlands` users get **repo-scoped permissions only**
- All other project `portugal` content remains invisible

## 2. Create a Dedicated Security Group _inside project `portugal`_

In **Project Settings → Permissions** (project `portugal`):

1. Create a group called something like:  
   `Repo X Collaborators from Project Netherlands`
2. Add only the specific users from project `netherlands` (not the entire team, not the project).

Why a DevOps group?

- Easier auditing
- Easier removal
- Consistent least privilege
- No individual direct assignments

## 3. Break Inheritance Only on the Target Repository

Inside **project `portugal` → Repos → Repo X → Security**:

1. Give the new group **Contribute** and **Read** permission
2. Explicitly set `Deny` or `Not set` for anything unnecessary, such as:
    - Delete repository
    - Manage permissions
    - Force push
    - Create branch
    - Create tag  
      (unless required)

With this, project `netherlands` users only see:

    ✓ This repo  
    ✕ No pipelines  
    ✕ No other repos  
    ✕ No Boards  
    ✕ No Artifacts  
    ✕ No wiki  
    ✕ No dashboards  
    ✕ No environment secrets

## 4. Use Branch Policies to Prevent Unwanted Actions

Since project `netherlands` collaborators are external to the owning team, enforce:

- Require pull requests for `main`/`release` branches
- Require at least one reviewer from project `portugal`
- Restrict who can approve PRs
- Disable direct push to protected branches

This prevents accidental or unauthorized changes.

## 5. If CI/CD Pipelines Involve That Repo

If the repository is part of build/release pipelines:

- Create pipeline‑specific service (managed) identities
- Restrict pipeline permissions to **reader** for this repo
- Do _not_ grant project `netherlands` users access to Pipelines unless needed

Often, project `netherlands` doesn't need pipeline access to contribute code.

## Why This Model Works

### Least privilege

    ✓ Project `netherlands` users get access to exactly **one repo**, nothing else.

### Simple to maintain

    ✓ A single group encapsulates all permissions. Add/remove users easily.

### No pollution of project structures

    ✓ You don't move users across projects, avoiding unnecessary visibility.

### Alignment with Azure DevOps security model

    ✓ Azure DevOps starts with "deny by default," so repo‑level granting is safe.

## Example Final Permission Structure

### Project `portugal` – Project Level

| Group | Permission |
| :-- | :-- |
| `Repo X Collaborators from Project Netherlands` | Reader (minimal visibility) |

### Project `portugal` – Repo Level

| Repo | Permission |
| :-- | :-- |
| Repo X | Contribute, Read |
| Other repos | No access / inherit deny |

### Project `portugal` – Branch‑Level

| Branch | Policy |
| :-- | :-- |
| main | Require PR, require review |
| release/\* | Restricted merge |
| feature/\* | Optional restrictions |

## Summary

> The cleanest, most secure way to allow one team to collaborate on a single repo from another project is:

1. Keep the repo inside project `portugal`
2. Create a dedicated security group in project `portugal`
3. Assign project `netherlands` users into that group
4. Break repo security inheritance and assign only repo‑specific rights
5. Use branch policies to protect the codebase

This achieves "limited collaboration" with strong "least privilege" enforcement.
