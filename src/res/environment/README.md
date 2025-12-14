<!-- markdownlint-disable no-duplicate-heading -->
<!-- omit from toc -->
# Environment `[res\environment\main.ps1]`

![Version](https://img.shields.io/badge/script--version-1.0-blue) [![License](https://img.shields.io/badge/license-MIT-purple)](https://github.com/msc365/az-devops-governance/blob/main/LICENSE)

Creates or updates an Azure Environment within a specified subscription.

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

This PowerShell script creates or updates an Azure Environment within a specified subscription.
It provides comprehensive environment management capabilities including configuration of resource groups and their properties.

## Parameters

| Parameter | Type | Required | Default | Description |
| :-- | :-- | :-- | :-- | :-- |
| `Name` | `String` | Yes | - | Mandatory. The name of the environment to create or update. |
| `Organization` | `String` | Yes | - | No description provided. |
| `ProjectId` | `String` | Yes | - | No description provided. |
| `Description` | `String` | No | - | Optional. A description for the environment. |
| `Force` | `Switch` | No | - | Optional. A switch to force removal without confirmation. |
| `Remove` | `Switch` | No | - | Optional. A switch indicating whether to remove the specified environment. |
| `ResourceGroup` | `Object` | No | - | Optional. An optional hashtable defining the resource group properties: Name, Location, Tags. |
| `SubscriptionId` | `Object` | No | - | Mandatory. The Azure Subscription ID where the environment will be created or updated. |

## Examples

### Example 1

#### PowerShell

```powershell
$params = @{
    Name           = 'my-environment'
    SubscriptionId = '00000000-0000-0000-0000-000000000000'
    ResourceGroup  = @{
        Name     = 'rg-my-environment'
        Location = 'westeurope'
        Tags     = @{ environment = 'dev' }
    }
}
.\main.ps1 @params
```

Creates or updates the 'my-environment' environment in the specified subscription with the given resource group configuration.

## Outputs

Returns: `pscustomobject`

## Support

### CommonParameters

This cmdlet supports the common parameters: `-Debug`, `-ErrorAction`, `-ErrorVariable`,  
`-InformationAction`, `-InformationVariable`, `-OutBuffer`, `-OutVariable`, `-PipelineVariable`,  
`-ProgressAction`, `-Verbose`, `-WarningAction`, and `-WarningVariable`.  
For more information, see [about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## Dependencies

This script requires the following PowerShell modules:

- `Az.Accounts`
- `Azure.DevOps.PSModule`

## Resources

- [deploy](deploy.ps1)

### Tests

- [default](tests/e2e/default/main.tests.ps1)
- [remove-all](tests/e2e/remove-all/main.tests.ps1)
- [remove](tests/e2e/remove/main.tests.ps1)
- [resource-group](tests/e2e/resource-group/main.tests.ps1)
- [update](tests/e2e/update/main.tests.ps1)


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
