<!-- omit from toc -->
# Deploy this Demo

How to deploy this example in your own Azure account(s) and Azure DevOps organization. This demo uses the fictitious _European Building Materials_ organization described in the root [README](../../README.md) to illustrate end-to-end governance patterns across Azure and Azure DevOps.

> [!WARNING]
> **Disclaimer - Not for Production**  
> This code is NOT meant to be used for production. While great efforts were taken for code quality and best practices, certain decisions were made for convenience. For example, this demo uses resource groups to separate environments. In practice, however, [Azure subscriptions are a better choice](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/govern/guides/standard/#governance-best-practices) per Microsoft's [Cloud Adoption Framework (CAF)](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework).

> [!NOTE]
> **Local Deployment**  
> This guide describes a local deployment process using PowerShell scripts. To automate this process, a pipeline-based deployment will be available soon.

<!-- omit from toc -->
## Table of Contents
- [Prerequisites](#prerequisites)
- [Configuration](#configuration)
- [Deployment - Stage 1 (Azure)](#deployment---stage-1-azure)
- [Deployment - Stage 2 (Azure DevOps)](#deployment---stage-2-azure-devops)
- [Just the Commands](#just-the-commands)
- [What Gets Deployed](#what-gets-deployed)

## Prerequisites

This demo requires the following resources and permissions. If you have a [Visual Studio subscription](https://visualstudio.microsoft.com/subscriptions/), use that for this demo so that the elevated permissions required have NO access to your actual production Azure environments.

### 1. Azure Subscription

- **Azure Subscription**  
  An active Azure subscription where you will deploy resources.

- **Permissions**  
  User or Service Principal with `Owner` permissions on the subscription (or resource group scope) to:
  - Create resource groups, managed identities, and role assignments
  - Configure RBAC at subscription or resource group level
  - Create custom role definitions

### 2. Microsoft Entra ID (formerly Azure AD)

> [!CAUTION]
> Please consider carefully which Microsoft Entra ID tenant you will use. If possible, use a **non-production tenant** for this demo because the deployment requires elevated privileges to manage Entra ID groups.

- **Entra ID Tenant**  
  A Microsoft Entra ID tenant (preferably non-production) with permissions to create security groups.

- **Required Permissions**  
  User or Service Principal with one of the following:
  - **Directory Role**: `Groups Administrator` or higher (recommended)
  - **API Permissions**: Microsoft Graph API with `Group.ReadWrite.All` permission

### 3. Azure DevOps Organization

- **DevOps Organization**  
  Create a [new organization](https://learn.microsoft.com/en-us/azure/devops/organizations/accounts/create-organization) just for this demo or use an existing test organization.

- **Permissions**  
  User must be a **Project Collection Administrator** or have equivalent permissions to:
  - Create projects
  - Configure service connections
  - Manage project-level security groups
  - Create environments

- **Authentication**  
  The deployment uses the [Azure.DevOps.PSModule](https://www.powershellgallery.com/packages/Azure.DevOps.PSModule) from PowerShell Gallery, which authenticates automatically using your Azure credentials (no PAT required).

### 4. Tools

- **PowerShell 7+**  
  [Install PowerShell](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell) for running deployment scripts.

- **Az.Accounts PowerShell Module**  
  [Install Az.Accounts](https://learn.microsoft.com/en-us/powershell/azure/install-azure-powershell) for Azure authentication:
  ```powershell
  Install-Module -Name Az.Accounts -Scope CurrentUser
  ```

- **Azure.DevOps.PSModule**  
  Install the custom PowerShell module from PSGallery:
  ```powershell
  Install-Module -Name Azure.DevOps.PSModule -Scope CurrentUser
  ```

## Configuration

Before deploying, configure the demo parameters to match your environment.

### 1. Update Configuration File

Edit [`config/main.config.json`](config/main.config.json) with your values:

```json
{
    "$schema": "../../../schemas/config.schema.json",
    "uniqueId": "2vk6",
    "prefix": "demo",
    "service": "e2egov",
    "location": "westeurope",
    "subscriptionId": "00000000-0000-0000-0000-000000000000",
    "collectionUri": "https://dev.azure.com/your-org"
}
```

### 2. Set Azure Environment Variables

Set environment variables for Bicep deployments. These provide default values for deployment script parameters:

```powershell
$env:LOCATION = 'westeurope'
$env:SUBSCRIPTION_ID = '00000000-0000-0000-0000-000000000000'  # Your subscription ID
$env:CUSTOM_ROLE_DEFINITION_ID = '11111111-1111-1111-1111-111111111111'  # Optional: custom role ID
```

### 3. Install Azure.DevOps.PSModule

Install the custom PowerShell module that handles Azure DevOps authentication:

```powershell
Install-Module -Name Azure.DevOps.PSModule -Scope CurrentUser
```

The module authenticates to Azure DevOps automatically using your Azure credentials established via `Connect-AzAccount`, eliminating the need for Personal Access Tokens (PATs).

### 4. Login to Azure

Authenticate to Azure with the subscription you'll use for deployment. This authentication will be used for both Azure resources and Azure DevOps operations:

```powershell
Connect-AzAccount
Set-AzContext -SubscriptionId <SUBSCRIPTION_ID>
```

> [!NOTE]
> The Azure.DevOps.PSModule automatically uses your Azure authentication context, so no separate Azure DevOps login is required.

## Deployment - Stage 1 (Azure)

Deploy Azure infrastructure using PowerShell scripts that wrap Bicep templates. These resources must be created before Azure DevOps configuration because service connections and environments reference these Azure resources.

Navigate to the pipeline scripts directory:
```powershell
cd accelerator/demo/pipeline-scripts
```

### 1. Custom Role Definition (Optional)

Deploy a custom RBAC role that prevents managed identities from removing management locks:

```powershell
# Navigate to role definition template
cd ../../iac/ptn/authorization/role-definition

# Deploy using the included script
./deploy.ps1
```

### 2. Resource Groups

Create resource groups for each environment and OpCo:

```powershell
# From accelerator/demo/pipeline-scripts directory
cd pipeline-scripts
./Deploy-ResourceGroups.ps1
```

### 3. Managed Identities

Create user-assigned managed identities for workload identity federation:

```powershell
./Deploy-ManagedIndentities.ps1
```

### 4. Entra Security Groups

Create Microsoft Entra security groups for admins, developers, and stakeholders:

```powershell
./Deploy-SecurityGroups.ps1
```

### 5. Role Assignments

Assign RBAC roles to managed identities and Entra groups:

```powershell
./Deploy-RoleAssignments.ps1
```

## Deployment - Stage 2 (Azure DevOps)

Configure Azure DevOps resources using PowerShell scripts. Run these in order as they have dependencies on each other.

> [!NOTE]
> Continue from the same `pipeline-scripts` directory used in Stage 1.

### 1. Projects

Create Azure DevOps projects:

```powershell
./Deploy-Projects.ps1
```

### 2. Teams (Optional)

Create additional teams within projects:

```powershell
./Deploy-Teams.ps1
```

### 3. Group Memberships

Sync Microsoft Entra groups into Azure DevOps project security groups:

```powershell
./Deploy-Memberships.ps1
```

### 4. Environments

Create Azure DevOps environments for deployment approvals and checks:

```powershell
./Deploy-Environments.ps1
```

### 5. Service Connections

Create service connections using workload identity federation:

```powershell
./Deploy-ServiceConnections.ps1
```

## Just the Commands

Once you've completed the prerequisites and configuration, deploying is straightforward. Here's the complete sequence:

**PowerShell:**
```powershell
# Install required modules (one-time setup)
Install-Module -Name Az.Accounts -Scope CurrentUser
Install-Module -Name Azure.DevOps.PSModule -Scope CurrentUser

# Set environment variables for Bicep deployments
$env:LOCATION = 'westeurope'
$env:SUBSCRIPTION_ID = '00000000-0000-0000-0000-000000000000'
$env:CUSTOM_ROLE_DEFINITION_ID = '11111111-1111-1111-1111-111111111111'

# Set global configuration
{
    "$schema": "../../../schemas/config.schema.json",
    "uniqueId": "2vk6",
    "prefix": "demo",
    "service": "e2egov",
    "location": "westeurope",
    "subscriptionId": "00000000-0000-0000-0000-000000000000",
    "collectionUri": "https://dev.azure.com/your-org"
}

# Login to Azure (authenticates both Azure and Azure DevOps)
Connect-AzAccount
Set-AzContext -SubscriptionId $env:SUBSCRIPTION_ID

# Navigate to pipeline scripts directory
cd accelerator/demo/pipeline-scripts

# Stage 1 - Azure Infrastructure
./Deploy-ResourceGroups.ps1
./Deploy-ManagedIndentities.ps1
./Deploy-SecurityGroups.ps1
./Deploy-RoleAssignments.ps1

# Stage 2 - Azure DevOps
./Deploy-Projects.ps1
./Deploy-Teams.ps1
./Deploy-Memberships.ps1
./Deploy-Environments.ps1
./Deploy-ServiceConnections.ps1
```

## What Gets Deployed

After successful deployment, you will have the following resources:

### Azure Resources

- **Resource Groups**  
  Multiple resource groups representing different OpCos and environments, for example:
  - `rg-demo-portugal-2vk6-dev-weu`
  - `rg-demo-portugal-2vk6-prd-weu`

- **Managed Identities**  
  User-assigned identities for workload identity federation, for example:
  - `id-demo-portugal-2vk6-dev-weu`
  - `id-demo-portugal-2vk6-prd-weu`

- **Entra Security Groups**  
  Groups for access control, for example:
  - `demo-portugal-2vk6-admins`
  - `demo-portugal-2vk6-devs`
  - `demo-portugal-2vk6-stakes`

- **Role Assignments**  
  RBAC assignments linking groups and identities to resource scopes

### Azure DevOps Resources

- **Projects**  
  One project per OpCo, for example:
  - `projects-CCoE`
  - `projects-Portugal`
  - `projects-Netherlands`
  - `shared-Collaboration`
  - `shared-Services`

- **Teams**  
  Additional teams within projects for specialized workloads

- **Environments**  
  Deployment environments with approval gates, for example:
  - `env-demo-portugal-2vk6-dev`
  - `env-demo-portugal-2vk6-prd`

- **Service Connections**  
  Workload identity federation connections to Azure subscriptions

- **Security Groups**  
  Entra groups synchronized into project-level permissions

### Naming Convention

All resources follow a structured naming pattern defined in [`config/main.abbreviations.json`](../../config/main.abbreviations.json):

- `rg-*`: Resource groups
- `id-*`: User-assigned managed identities
- `env-*`: Environments
- Pattern:
  - `{type}-${config.prefix}-{opco}-${config.uniqueId}-{environment}-{location}`
- Example:
  - `rg-demo-portugal-2vk6-dev-weu`  
    Resource Group with prefix 'demo' for Portugal OpCo, unique ID '2vk6', Dev environment, in West Europe.

---

For detailed architecture and governance patterns, see:

- [README](../../README.md) - Complete governance model overview
- [Architecture Diagram](../../README.md#architecture) - End-to-end governance architecture
- [Deployment Sequence](../../docs/deployment-sequence.md) - Detailed deployment order
- [Cross-Project Collaboration](../../docs/cross-project-collaboration-scenario.md) - Multi-project scenarios

