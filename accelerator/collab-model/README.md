# Collaboration Model

## Scenario Overview

This accelerator follows the "One project, many teams" guidance from the [Azure DevOps organization planning](https://learn.microsoft.com/en-us/azure/devops/user-guide/plan-your-azure-devops-org-structure?view=azure-devops#project-decision-framework) article. A single Azure DevOps project anchors shared artifacts, while each feature or platform team keeps autonomy through its own repository, board area path, and security scope. This layout reduces the clutter of many small projects, centralizes governance, but still lets teams deploy independently.

### Reference Scenario - European Building Materials

The collaboration model mirrors the fictitious _European Building Materials_ organization described in the root README to keep technical decisions tied to business drivers:

- **OpCo-aligned permissions**  
  Each Operational Company (Portugal, Netherlands, etc.) runs independently but shares naming conventions. Every OpCo defines `*-admins`, `*-devs`, and `*-stakes` Microsoft Entra groups so that Azure and Azure DevOps RBAC stay in sync.

- **Environment split**  
  Every domain has Production (admins only) and Non-production (developers elevated). Stakeholders retain Reader rights in both for visibility without write access.

- **CI/CD mandate**  
  All applications must adopt Azure DevOps CI/CD so repo changes automatically flow through gated pipelines (see README branch strategy). Pipelines enforce branch policies and workload identity federation.

- **Cloud journey**  
  The org is consolidating formerly isolated OpCo projects into a shared `CCoE` project to reduce silos while still honoring local autonomy.

## Collaboration Topology

- **Single project boundary**  
  Keeps cross-team visibility for dashboards, boards, and reporting while simplifying governance.

- **Multiple teams per project**  
  Allows each team to own its backlog, repos, and pipelines without scattering policies across projects.

- **Targeted repositories**  
  Create a repo per product stream or shared service; teams can fork or branch as needed, but permissions stay scoped to their repo.

- **Environment alignment**  
  Dev/Test/Prod environments map to Azure resource groups (subscriptions) so approvals and service connections mirror real infrastructure.

- **Scoped security groups**  
  Entra groups control who can touch Azure resources; Azure DevOps groups govern work management and pipeline operations.

## Deployment Sequence

To avoid dependency errors, run the deployment in two stages. Complete the Azure foundations first (Bicep) so identities and scopes exist before Azure DevOps entities reference them. After Azure prerequisites finish, run the DevOps automation. Re-run a step only if its prerequisites are already present.

### Stage 1 - Azure foundation (Bicep)

1. **Custom Role Definition**  
   Publish least-privilege roles so subsequent identities can request the right permissions.

2. **Resource Groups**  
   Provision the landing zones that back environments and service connections.

3. **Managed Identities**  
   Create user-assigned identities that pipelines will later bind to service connections.

4. **Graph Security Groups**  
   Seed Entra groups representing platform, project admins, and readers.

5. **Role Assignments**  
   Tie the role definitions to identities and groups at the appropriate scope (resource group or subscription).

### Stage 2 - Azure DevOps layer (PowerShell)

1. **Project**  
   Instantiate the shared Azure DevOps project so downstream entities have a parent container.

2. **Teams (optional)**  
   Create feature teams; if you skip this, all work defaults to the project-level team.

3. **Group Memberships**  
   Sync Entra groups into Azure DevOps security groups for consistent permissions.

4. **Environments**  
   Define Azure DevOps environments and protection rules that mirror the Azure resource groups.

5. **Service Connections**  
   Bind the managed identities to the environments, completing the pipeline-to-Azure trust chain.

## Difference Between Azure and Azure DevOps Deployments

- **Scope**  
  Azure deployments create or configure cloud resources (resource groups, identities, RBAC). Azure DevOps deployments configure the developer platform (projects, teams, environments, service connections).

- **Tooling**  
  Azure steps run via Bicep/ARM against Azure Resource Manager. DevOps steps invoke PowerShell/REST against the Azure DevOps service.

- **Dependencies**  
  DevOps objects often reference Azure identities or resources (e.g., service connections need managed identities), so Azure must be provisioned first.

- **Lifecycle**  
  Azure resources follow cloud governance (policy, subscription limits), whereas DevOps assets follow project lifecycle (iteration cadence, boards, repos). Keep change control and auditing aligned with each platform.

