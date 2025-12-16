<!-- markdownlint-disable no-duplicate-heading -->
<!-- omit from toc -->
# Environment `[res\environment\main.ps1]`

![Version](https://img.shields.io/badge/script--version-0.1.0-blue) [![License](https://img.shields.io/badge/license-MIT-purple)](https://github.com/msc365/az-devops-governance/blob/main/LICENSE)

Creates or updates an Azure DevOps Environment.

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

This PowerShell script creates or updates an Azure DevOps Environment.

It provides comprehensive environment management capabilities including configuration of an optional resource group
and its properties as a scoped environment.

## Parameters

| Parameter | Type | Required | Default | Description |
| :-- | :-- | :-- | :-- | :-- |
| `Name` | `String` | Yes | - | Required. The name of the environment to create or update. |
| `Organization` | `String` | Yes | - | Required. The Azure DevOps organization name. |
| `ProjectId` | `String` | Yes | - | Required. The Azure DevOps project ID or Name where the environment will be created. |
| `Description` | `String` | No | - | Optional. A description for the environment. |
| `Force` | `Switch` | No | - | Optional. Switch to force deletion without confirmation during rollback. |
| `ResourceGroup` | `Object` | No | - | Optional. An optional object defining the resource group properties: `Name`, `Location`, `SubscriptionId`, `Tags`. |
| `Rollback` | `Switch` | No | - | Optional. Switch to indicate if the operation should rollback (delete) the environment and related resources. <br /> <b> WARNING! </b> <br /> Use with caution! Removing an environment is irreversible and may affect teams relying on it. |

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

Deploys the environment using the specified template and parameters.

### Example 2

#### PowerShell

```powershell
$customSplat = @{
    TemplateFile          = 'main.ps1'
    TemplateParameterFile = 'params\custom.parameters.json'
}

.\deploy.ps1 @customSplat -Verbose
```

Deploys the environment using the specified template and custom parameters.

### Example 3

#### PowerShell

```powershell
$rollbackSplat = @{
    TemplateFile          = 'main.ps1'
    TemplateParameterFile = 'params\main.parameters.json'
}

.\deploy.ps1 @rollbackSplat -Rollback -Force -Verbose
```

Rolls back (deletes) the environment and related resources without confirmation.

### Example 4

#### PowerShell

```powershell
$paramSplat = @{
    Organization   = 'e2egov-org'
    ProjectId      = 'e2egov-prjHb72x9'
    Name           = 'env-prjHb72x9-tst'
    Description    = 'Default e2e governance description'
    ResourceGroup  = @{
        Name           = 'rg-e2egov-prjHb72x9-tst-neu'
        Location       = 'northeurope'
        SubscriptionId = '00000000-0000-0000-0000-000000000000'
        Tags           = @{ environment = 'tst'; service = 'e2egov' }
    }
}
.\main.ps1 @paramSplat -Verbose
```

Deploys a new environment including the configuration of an optional resource group
and its properties as a (least privileged) scoped environment using the specified parameters in code.

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
- `Az.Resources`
- `Azure.DevOps.PSModule`

## Resources

- [deploy](deploy.ps1)

### Shared

- [resource-group](../shared/resource-group)

### Tests

- [default](tests/e2e/default)
- [resource-group](tests/e2e/resource-group)
- [rollback](tests/e2e/rollback)
- [update](tests/e2e/update)


## Notes

- Operations are idempotent (safe to run multiple times).
- Ensure you are logged in to Azure using Connect-AzAccount before running this script.
- Automatically imports the `Azure.DevOps.PSModule` if not already loaded.
- Automatic connection to Azure DevOps organization.
- User confirmation is required for deletion unless `-Force` is specified.
