# A limited cross‑project collaboration scenario

Below is a **clean, practical, Senior‑level Azure DevOps design** for your scenario:

> **Project A owns a repo, and needs to invite only a small subset of users from Project B to collaborate on *one* repository—without granting them full access to Project A.**

This is a classic **limited cross‑project collaboration** scenario. Azure DevOps doesn’t provide repo‑level isolation natively, but with proper permission scoping you can achieve a “least‑privileged collaboration bubble.”

***

# ✅ Recommended Architecture

## **1. Keep the repository in Project A**

Do **not** mirror/duplicate it.  
Do **not** move the other team into Project A wholesale.

Instead:

* Project A keeps ownership
* Project B users get **repo-scoped permissions only**
* All other Project A content remains invisible

***

# ✅ 2. Create a Dedicated Security Group *inside Project A*

In **Project Settings → Permissions** (Project A):

1. Create a group called something like:  
    **`RepoA-Collaborators-From-ProjectB`**
2. Add only the specific users from Project B (not the entire team, not the project).

Why a group?

* Easier auditing
* Easier removal
* Consistent least privilege
* No individual direct assignments

***

# ✅ 3. Break Inheritance Only on the Target Repository

Inside **Project A → Repos → \[Target Repo] → Security**:

1. Give the new group **Contribute** and **Read** permission
2. Explicitly set “Deny” or “Not set” for anything unnecessary, such as:
    * Delete repository
    * Manage permissions
    * Force push
    * Create branch
    * Create tag  
        (unless required)

With this, Project B users only see:

✔ This repo  
❌ No pipelines  
❌ No other repos  
❌ No Boards  
❌ No Artifacts  
❌ No wiki  
❌ No dashboards  
❌ No environment secrets

***

# ✅ 4. Use Branch Policies to Prevent Unwanted Actions

Since Project B collaborators are external to the owning team, enforce:

* Require pull requests for `main`/`release` branches
* Require at least one reviewer from Project A
* Restrict who can approve PRs
* Disable direct push to protected branches

This prevents accidental or unauthorized changes.

***

# ✅ 5. If CI/CD Pipelines Involve That Repo

If the repository is part of build/release pipelines:

* Create pipeline‑specific service identities
* Restrict pipeline permissions to **reader** for this repo
* Do *not* grant Project B users access to Pipelines unless needed

Often, Project B doesn't need pipeline access to contribute code.

***

# 🧩 Why This Model Works

### **✔ Least privilege**

Project B users get access to exactly **one repo**, nothing else.

### **✔ Simple to maintain**

A single group encapsulates all permissions. Add/remove users easily.

### **✔ No pollution of project structures**

You don’t move users across projects, avoiding unnecessary visibility.

### **✔ Alignment with Azure DevOps security model**

Azure DevOps starts with "deny by default," so repo‑level granting is safe.

***

# 🔐 Example Final Permission Structure

### **Project A – Project Level**

| Group                             | Permission                  |
| --------------------------------- | --------------------------- |
| RepoA‑Collaborators‑From‑ProjectB | Reader (minimal visibility) |

### **Project A – Repo Level**

| Repo        | Permission               |
| ----------- | ------------------------ |
| TargetRepo  | Contribute, Read         |
| Other repos | No access / inherit deny |

### **Branch‑Level**

| Branch     | Policy                     |
| ---------- | -------------------------- |
| main       | Require PR, require review |
| release/\* | Restricted merge           |
| feature/\* | Optional restrictions      |

***

# 🏁 Summary

**The cleanest, most secure way to allow one team to collaborate on a single repo from another project is:**

1. Keep the repo inside Project A
2. Create a dedicated security group in Project A
3. Assign Project B users into that group
4. Break repo security inheritance and assign only repo‑specific rights
5. Use branch policies to protect the codebase

This achieves “limited collaboration” with strong “least privilege” enforcement.
