<!-- markdownlint-disable no-duplicate-heading -->
<!-- omit from toc -->
# Service Connection `[res\service-connection\main.ps1]`

![Version](https://img.shields.io/badge/script--version-0.1.0-blue) [![License](https://img.shields.io/badge/license-MIT-purple)](https://github.com/msc365/az-devops-governance/blob/main/LICENSE)

Deploys an Azure DevOps Service Connection with Managed Service Identity and Role Assignment.

<!-- omit from toc -->
## Navigation

- [Description](#description)
- [Parameters](#parameters)
- [Examples](#examples)
- [Outputs](#outputs)
- [Support](#support)
- [Dependencies](#dependencies)
- [Resources](#resources)
- [Notes](#notes)

## Description

This script deploys an Azure DevOps Service Connection using a Managed Service Identity (MSI) for authentication.
It also creates the necessary role assignments for the MSI to access Azure resources aka _Azure DevOps Workload Identity Federation_.

## Parameters

| Parameter | Type | Required | Default | Description |
| :-- | :-- | :-- | :-- | :-- |
| `ManagedServiceIdentity` | `Object` | Yes | - | Required. An object containing details of the Managed Service Identity to be used. |
| `Organization` | `String` | Yes | - | Required. The Azure DevOps organization name. |
| `ProjectId` | `String` | Yes | - | Required. The Azure DevOps project ID or Name where the service connection will be created. |
| `Scope` | `String` | Yes | - | Required. The scope for the service connection (e.g., /subscriptions/00000000-0000-0000-0000-000000000000). |
| `ServiceEndpointName` | `String` | Yes | - | Required. The name of the service connection to be created. |
| `Force` | `Switch` | No | - | Optional. Switch to force deletion without confirmation during rollback. |
| `Rollback` | `Switch` | No | - | Optional. Switch to indicate if the operation should rollback (delete) the service connection and related resources. |

## Examples

### Example 1

#### PowerShell

```powershell
$deploySplat = @{
    TemplateFile          = 'main.ps1'
    TemplateParameterFile = 'params\main.parameters.json'
}

.\deploy.ps1 @deploySplat -Verbose
```

Deploys the service connection using the specified template and parameters.


### Example 2

#### PowerShell

```powershell
$customSplat = @{
    TemplateFile          = 'main.ps1'
    TemplateParameterFile = 'params\custom.parameters.json'
}

.\deploy.ps1 @customSplat -Verbose
```

Deploys the service connection using the specified template and custom parameters.


### Example 3

#### PowerShell

```powershell
$rollbackSplat = @{
    TemplateFile          = 'main.ps1'
    TemplateParameterFile = 'params\main.parameters.json'
}

.\deploy.ps1 @rollbackSplat -Rollback -Force -Verbose
```

Rolls back (deletes) the service connection and related resources without confirmation.


### Example 4

#### PowerShell

```powershell
$paramSplat = @{
    Organization           = 'my-org'
    ProjectId              = 'my-project'
    ServiceEndpointName    = 'sc-my-project'
    Scope                  = '/subscriptions/00000000-0000-0000-0000-000000000000'
    ManagedServiceIdentity = @{
        name               = 'msi-my-project'
        resourceGroupName  = 'rg-my-project'
        subscriptionId     = '00000000-0000-0000-0000-000000000000'
        location           = 'westeurope'
        tags               = @{ 'environment' = 'prd'; 'owner' = 'e2egov' }
        roleAssignment     = @{
            roleDefinitionName = 'Contributor'
            scope              = '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-my-project'
        }
    }
}

.\main.ps1 @paramSplat -Verbose
```

Deploys a service connection using the specified parameters in code.

## Outputs

Returns: `pscustomobject`

## Support

### CommonParameters

This cmdlet supports the common parameters: `-Debug`, `-ErrorAction`, `-ErrorVariable`,  
`-InformationAction`, `-InformationVariable`, `-OutBuffer`, `-OutVariable`, `-PipelineVariable`,  
`-ProgressAction`, `-Verbose`, `-WarningAction`, and `-WarningVariable`.  
For more information, see [about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

### SupportsShouldProcess

This script supports the `-WhatIf` and `-Confirm` parameters for safe execution:

- **`-WhatIf`**: Shows what would happen if the script runs without actually making any changes.
- **`-Confirm`**: Prompts for confirmation before performing each action.

## Dependencies

This script requires the following PowerShell modules:

- `Az.Accounts`
- `Az.ManagedServiceIdentity`
- `Az.Resources`
- `Azure.DevOps.PSModule`

## Resources

- [deploy](deploy.ps1)

### Modules

- [dependencies](modules/dependencies.ps1)

### Shared

- [resource-group](../shared/resource-group)
- [role-assignment](../shared/role-assignment)

### Tests

- [default](tests/e2e/default)
- [rollback](tests/e2e/rollback)

## Notes

- Operations are idempotent (safe to run multiple times).
- Ensure you are logged in to Azure using Connect-AzAccount before running this script.
- Automatically imports the `Azure.DevOps.PSModule` if not already loaded.
- Automatic connection to Azure DevOps organization.
- User confirmation is required for deletion unless `-Force` is specified.
