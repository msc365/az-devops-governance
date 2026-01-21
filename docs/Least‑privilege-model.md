# Least‑privilege model Azure DevOps

This is a clear, moderately detailed explanation of how **Azure DevOps uses a least‑permissions (least‑privilege) model**, written from the perspective of a Senior Azure DevOps Engineer:

***

# 🔐 Azure DevOps and the Least Permissions Model

Azure DevOps follows a **least‑permissions** (or **least‑privilege**) security approach, meaning **users and service principals only receive the minimum level of access required to perform their tasks—nothing more**. This reduces the attack surface, prevents accidental misuse, and keeps project boundaries tight.

Below is a practical breakdown of how this model works across Azure DevOps.

***

## 🧩 1. Access is Denied by Default

In Azure DevOps, **permissions start at “Not set / Denied”**.  
This applies to:

* Organization level
* Project level
* Repos
* Pipelines
* Artifacts
* Boards *areas/iterations*

Unless someone is explicitly added to a group or permission rule, they won’t be able to interact with resources. This makes access **intentional**, not accidental.

***

## 👥 2. Group‑Based Access is the Standard

The least‑permissions model is enforced through structured groups:

| Scope        | Typical Groups                                      |
| ------------ | --------------------------------------------------- |
| Organization | Project Collection Administrators, Service Accounts |
| Project      | Contributors, Readers, Project Administrators       |
| Repo         | Repo Administrators, Contributors                   |
| Pipelines    | Build Administrators, Release Administrators        |

The principle:

> **You assign someone to the lowest‑privileged group that still lets them work effectively.**

Avoid granting permissions directly to individuals. **Group inheritance** makes auditing and scaling easier.

***

## 🔑 3. Permission Inheritance and Overriding

Azure DevOps permissions are hierarchical:

* Org → Project → Repo/Pipeline → Specific object

You can override permissions at a lower level if someone needs a narrow exception—e.g.:

* A developer has read‑only access to most repos
* But they require **Contribute** only on a specific repo
* You override just that repo’s permission

This keeps privilege creep under control.

***

## 🛡️ 4. Security in Pipelines (YAML or Classic)

Pipelines also follow least privilege:

* Build agents run under restricted service accounts
* Access tokens are **scoped to the pipeline**
* System.AccessToken is limited to the necessary repos/feeds
* Service connections use **fine‑grained permissions** (Azure RBAC scopes)

A good practice is:

> “Grant the pipeline service identity only the resources it needs—typically at the resource group level, not subscription.”

***

## 📦 5. Repos and Branch Policies

Azure Repos enforces least privilege through:

* Branch protection rules
* Restrict push and force‑push
* Limit who can approve PRs
* Require reviewers or checks before merging

This ensures developers can work but **cannot bypass governance**.

***

## 🛠️ 6. Service Connections & PATs

Service connections and personal access tokens (PATs) follow the same principle:

* PATs require selecting only the scopes needed (e.g., “Code (Read)” instead of “Full Access”)
* Service connections can be limited to:
  * One resource group
  * One Key Vault
  * One Storage Account
  * One Kubernetes Namespace

Avoid using **overprivileged** tokens like subscription‑wide contributor access.

***

## 🔍 7. Auditing & Visibility

Azure DevOps provides:

* Security audits
* Permission reports
* “View permissions” at every level
* Logging of permission changes

This helps validate that least privilege is maintained over time.

***

# 🧠 Why Least Permissions Matter in Azure DevOps

* Reduces risk of accidental damage (e.g., deleting repos, modifying pipelines)
* Limits blast radius in case of leaked tokens or compromised accounts
* Prevents privilege creep as teams change
* Supports compliance frameworks like ISO, NIST, SOC2, and Zero Trust
