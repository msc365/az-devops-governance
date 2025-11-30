<!-- cSpell: ignore hashtable msc365 -->
<!-- omit from toc -->
# Azure Environment `[res]`

This PowerShell script (`main.ps1`) creates or updates an Environment within a specified subscription. It provides comprehensive environment management capabilities including configuration of resource groups and their properties. The script manages Environments with the following capabilities:

- Creates new resource groups with specified configuration
- Updates existing resource group properties (_tags_)
- Supports both subscription-level and resource group-level operations
- Supports environment soft delete (with caution)
- Maintains subscription context integrity

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
    Name           = 'my-project-prd'
    SubscriptionId = '00000000-0000-0000-0000-000000000000'
    ResourceGroup  = @{
        name     = 'rg-my-project-prd-weu'
        location = 'westeurope'
        tags     = @{
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

This creates an environment with:

- A resource group in the specified subscription
- All specified tags applied to the resource group
- Automatic context switching to target subscription

### Example 3: Create a development environment

```powershell
$paramSplat = @{
    Name           = 'my-webapp-dev'
    SubscriptionId = '11111111-1111-1111-1111-111111111111'
    ResourceGroup  = @{
        name     = 'rg-my-webapp-dev-weu'
        location = 'westeurope'
        tags     = @{
            'public'      = 'false'
            'service'     = 'my-webapp'
            'environment' = 'dev'
            'cost-center' = 'engineering'
        }
    }
}

.\src\res\environment\main.ps1 @paramSplat
```

### Example 4: Update an existing environment's tags

```powershell
$paramSplat = @{
    Name           = 'my-project-prd'
    SubscriptionId = '00000000-0000-0000-0000-000000000000'
    ResourceGroup  = @{
        name     = 'rg-my-project-prd-weu'
        location = 'westeurope'
        tags     = @{
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

### Example 5: Create a subscription-level environment (no resource group)

```powershell
$paramSplat = @{
    Name           = 'my-project-sub'
    SubscriptionId = '00000000-0000-0000-0000-000000000000'
}

.\src\res\environment\main.ps1 @paramSplat
```

This creates an environment at subscription level without creating a resource group.

### Example 6: Remove an environment (destructive operation)

```powershell
$paramSplat = @{
    Name           = 'old-environment'
    SubscriptionId = '00000000-0000-0000-0000-000000000000'
    ResourceGroup  = @{
        name = 'rg-old-environment-weu'
    }
    Remove         = $true
}

.\src\res\environment\main.ps1 @paramSplat
```

> [!WARNING]
> Using `-Remove` and `-Force` will permanently delete the resource group and all resources within it. This operation cannot be undone.

## Parameters

### Required parameters

| Parameter | Type | Description |
| --- | --- | --- |
| `Name` | string | The name of the Azure environment to create or update |
| `SubscriptionId` | string | The Azure subscription ID where the environment will be created |

### Optional parameters

| Parameter | Type | Default | Description |
| --- | --- | --- | --- |
| `ResourceGroup` | object | `$null` | A hashtable defining the resource group configuration (name, location, tags) |
| `Remove` | switch |  | If specified, removes the environment (resource group) instead of creating/updating it |
| `Force` | switch |  | If specified, removes the environment without user confirmation for automated processes |

Resource Group Object Structure:

```powershell
@{
    name     = 'string'    # Required: Resource group name
    location = 'string'    # Required for creation: Azure region
    tags     = @{          # Optional: Resource tags as key-value pairs
        'key1' = 'value1'
        'key2' = 'value2'
    }
}
```

## Outputs

| Scenario | Return Type | Description |
| --- | --- | --- |
| Environment created/updated (with resource group) | PSCustomObject | Returns environment object with name, subscriptionId, and resourceGroup details |
| Environment created (subscription-level only) | `$null` | Returns null when no resource group is specified |
| Environment removed successfully | PSCustomObject | Returns object with `removed = $true` and status message |
| Environment doesn't exist (when removing) | PSCustomObject | Returns object with `removed = $false` and status message |

Example output structure for resource group-based environment:

```powershell
@{
    name           = 'my-project-prd'
    subscriptionId = '00000000-0000-0000-0000-000000000000'
    resourceGroup  = @{
        name              = 'rg-my-project-prd-weu'
        location          = 'westeurope'
        resourceId        = '/subscriptions/.../resourceGroups/rg-my-project-prd-weu'
        tags              = @{ ... }
        provisioningState = 'Succeeded'
    }
}
```

## Notes

- The script uses `CmdletBinding()` and supports common parameters (`-Verbose`, `-Debug`, etc.)
- All operations are logged with `Write-Verbose` for debugging
- The script automatically checks for Azure context before proceeding
- If no Azure context is found, an error is thrown
- Context switching is handled automatically when targeting different subscriptions
- The original subscription context is restored after operations complete
- Resource group operations are idempotent (safe to run multiple times)
- Tags are compared and updated only when differences are detected
- User confirmation is required for deletion unless `-Force` is specified
