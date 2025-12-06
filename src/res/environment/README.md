<!-- cSpell: ignore hashtable msc365 -->
<!-- omit from toc -->
# Azure DevOps Environment `[res]`

This PowerShell script (`main.ps1`) creates or updates an Azure DevOps Environment within a specified project. It provides comprehensive environment management capabilities including configuration of Azure resource groups and their properties. The script manages Environments with the following capabilities:

- Creates new Azure DevOps environments with optional Azure resource groups
- Updates existing environment properties (name, description)
- Updates existing resource group properties (_tags_)
- Supports both Azure DevOps-only and Azure resource group-backed operations
- Supports environment soft delete (with caution)
- Maintains Azure subscription context integrity

<!-- omit from toc -->
## Navigation

- [PowerShell Functions](#powershell-functions)
- [Usage examples](#usage-examples)
- [Parameters](#parameters)
- [Outputs](#outputs)
- [Notes](#notes)

## PowerShell Functions

The `Az.Accounts` module is required for the following Azure operations:

| Function | Description |
| --- | --- |
| `Get-AzContext` | Retrieves current Azure context |
| `Set-AzContext` | Sets the active Azure subscription context |

The `Az.Resources` module is required for the following Azure operations:

| Function | Description |
| --- | --- |
| `Get-AzResourceGroup` | Retrieves resource group information |
| `New-AzResourceGroup` | Creates new resource groups |
| `Set-AzResourceGroup` | Updates resource group properties |
| `Remove-AzResourceGroup` | Deletes resource groups |

The `Azure.DevOps.PSModule` module is required for the following Azure DevOps operations:

| Function | Description |
| --- | --- |
| `Get-AdoContext` | Retrieves current Azure DevOps context |
| `Connect-AdoOrganization` | Connects to Azure DevOps organization |
| `Get-AdoProject` | Retrieves Azure DevOps project information |
| `Get-AdoEnvironmentList` | Lists Azure DevOps environments |
| `New-AdoEnvironment` | Creates new Azure DevOps environments |
| `Set-AdoEnvironment` | Updates Azure DevOps environment properties |
| `Remove-AdoEnvironment` | Deletes Azure DevOps environments |

## Usage examples

### Example 1: Deploy using the deploy script with parameter file

```powershell
.\src\res\environment\deploy.ps1
```

This uses the `deploy.ps1` script which:

- Reads configuration from `params\main.parameters.json`
- Executes `main.ps1` with the parameters from the JSON file
- Simplifies deployment by separating configuration from execution

You can also specify custom parameter files:

```powershell
.\src\res\environment\deploy.ps1 -templateParameterFile 'params\custom.parameters.json'
```

To remove an environment using the deploy script:

```powershell
.\src\res\environment\deploy.ps1 -Remove -Force
```

### Example 2: Create a new environment with resource group

```powershell
$paramSplat = @{
    Organization   = 'msc365'
    ProjectId      = 'my-project'
    Name           = 'my-project-prd'
    Description    = 'Production environment for my project'
    ResourceGroup  = @{
        name           = 'rg-my-project-prd-weu'
        location       = 'westeurope'
        subscriptionId = '00000000-0000-0000-0000-000000000000'
        tags           = @{
            'public'      = 'false'
            'service'     = 'my-project'
            'environment' = 'prd'
            'security'    = 'rbac'
            'iac'         = 'bicep'
            'ci'          = 'azure-pipelines'
        }
    }
}

.\src\res\environment\main.ps1 @paramSplat
```

This creates an Azure DevOps environment with:

- An Azure DevOps environment in the specified project
- An Azure resource group in the specified subscription
- All specified tags applied to the resource group
- Automatic context switching to target subscription

### Example 3: Create a development environment

```powershell
$paramSplat = @{
    Organization   = 'msc365'
    ProjectId      = 'my-webapp'
    Name           = 'my-webapp-dev'
    Description    = 'Development environment for my webapp'
    ResourceGroup  = @{
        name           = 'rg-my-webapp-dev-weu'
        location       = 'westeurope'
        subscriptionId = '11111111-1111-1111-1111-111111111111'
        tags           = @{
            'public'      = 'false'
            'service'     = 'my-webapp'
            'environment' = 'dev'
            'cost-center' = 'engineering'
        }
    }
}

.\src\res\environment\main.ps1 @paramSplat
```

### Example 4: Update an existing environment's description and tags

```powershell
$paramSplat = @{
    Organization   = 'msc365'
    ProjectId      = 'my-project'
    Name           = 'my-project-prd'
    Description    = 'Updated production environment description'
    ResourceGroup  = @{
        name           = 'rg-my-project-prd-weu'
        location       = 'westeurope'
        subscriptionId = '00000000-0000-0000-0000-000000000000'
        tags           = @{
            'public'      = 'false'
            'service'     = 'my-project'
            'environment' = 'prd'
            'security'    = 'rbac'
            'iac'         = 'bicep'
            'ci'          = 'azure-pipelines'
            'updated'     = 'true'
        }
    }
}

.\src\res\environment\main.ps1 @paramSplat
```

> [!NOTE]
> Only tags can be updated for existing resource groups. Location cannot be changed after creation.

### Example 5: Create an Azure DevOps-only environment (no resource group)

```powershell
$paramSplat = @{
    Organization = 'msc365'
    ProjectId    = 'my-project'
    Name         = 'my-project-devops-only'
    Description  = 'Azure DevOps environment without Azure resources'
}

.\src\res\environment\main.ps1 @paramSplat
```

This creates an Azure DevOps environment without creating an Azure resource group.

### Example 6: Remove an environment (destructive operation)

```powershell
$paramSplat = @{
    Organization  = 'msc365'
    ProjectId     = 'my-project'
    Name          = 'old-environment'
    ResourceGroup = @{
        name           = 'rg-old-environment-weu'
        subscriptionId = '00000000-0000-0000-0000-000000000000'
    }
    Remove        = $true
}

.\src\res\environment\main.ps1 @paramSplat
```

> [!WARNING]
> Using `-Remove` and `-Force` will permanently delete both the Azure DevOps environment and the Azure resource group with all resources within it. This operation cannot be undone.

## Parameters

### Required parameters

| Parameter | Type | Description |
| --- | --- | --- |
| `Organization` | string | The Azure DevOps organization name |
| `ProjectId` | string | The Azure DevOps project ID or name |
| `Name` | string | The name of the Azure DevOps environment to create or update |

### Optional parameters

| Parameter | Type | Default | Description |
| --- | --- | --- | --- |
| `Description` | string | `$null` | A description for the Azure DevOps environment |
| `ResourceGroup` | object | `$null` | A hashtable defining the Azure resource group configuration (name, location, subscriptionId, tags) |
| `Remove` | switch |  | If specified, removes both the Azure DevOps environment and Azure resource group instead of creating/updating |
| `Force` | switch |  | If specified, removes the environment without user confirmation for automated processes |

Resource Group Object Structure:

```powershell
@{
    name           = 'string'    # Required: Resource group name
    location       = 'string'    # Required for creation: Azure region
    subscriptionId = 'string'    # Required: Azure subscription ID
    tags           = @{          # Optional: Resource tags as key-value pairs
        'key1' = 'value1'
        'key2' = 'value2'
    }
}
```

## Outputs

| Scenario | Return Type | Description |
| --- | --- | --- |
| Environment created/updated (with resource group) | PSCustomObject | Returns environment object with name, description, environmentId, and resourceGroup details |
| Environment created/updated (DevOps only) | PSCustomObject | Returns environment object with name, description, and environmentId |
| `-WhatIf` mode | `$null` | Returns null when running in WhatIf mode |
| Environment removed successfully | `$null` | Returns nothing when removal completes |

Example output structure for resource group-based environment:

```powershell
@{
    name          = 'my-project-prd'
    description   = 'Production environment for my project'
    environmentId = 123
    resourceGroup = @{
        ResourceGroupName = 'rg-my-project-prd-weu'
        Location          = 'westeurope'
        ResourceId        = '/subscriptions/.../resourceGroups/rg-my-project-prd-weu'
    }
}
```

## Notes

- The script uses `CmdletBinding()` and supports common parameters (`-Verbose`, `-Debug`, `-WhatIf`, etc.)
- All operations are logged with `Write-Verbose` for debugging
- The script automatically checks for Azure context before proceeding when ResourceGroup is specified
- If no Azure context is found (when needed), an error is thrown
- The script connects to Azure DevOps organization if not already connected
- Context switching is handled automatically when targeting different Azure subscriptions
- The original Azure subscription context is restored after operations complete
- Both Azure DevOps environment and Azure resource group operations are idempotent (safe to run multiple times)
- Environment name and description are compared and updated only when differences are detected
- Resource group tags are compared and updated only when differences are detected
- User confirmation is required for deletion unless `-Force` is specified
- Requires both `Az.Accounts`, `Az.Resources`, and `Azure.DevOps.PSModule` modules
