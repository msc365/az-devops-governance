<!-- markdownlint-disable no-duplicate-heading -->
<!-- omit from toc -->
# Resource Group `[res\shared\resource-group\main.ps1]`

![Version](https://img.shields.io/badge/script--version-0.1.0-blue) [![License](https://img.shields.io/badge/license-MIT-purple)](https://github.com/msc365/az-devops-governance/blob/main/LICENSE)

Create or update an Azure Resource Group.

<!-- omit from toc -->
## Navigation

- [Description](#description)
- [Parameters](#parameters)
- [Examples](#examples)
- [Outputs](#outputs)
- [Support](#support)
- [Dependencies](#dependencies)
- [Notes](#notes)

## Description

This script creates a new Azure Resource Group or updates an existing one with specified tags.

## Parameters

| Parameter | Type | Required | Default | Description |
| :-- | :-- | :-- | :-- | :-- |
| `Location` | `String` | Yes | - | Required. The Azure region where the Resource Group will be created e.g.: 'westeurope', 'northeurope'. |
| `Name` | `String` | Yes | - | Required. The name of the Resource Group. |
| `Force` | `Switch` | No | - | Optional. Skip confirmation prompt and proceed with operations immediately. |
| `Rollback` | `Switch` | No | - | See [Notes](#notes) for detailed information. |
| `Tags` | `Object` | No | - | Optional. A hashtable of tags to assign to the Resource Group. |

## Examples

### Example 1

#### PowerShell

```powershell
$rgParams = @{
    Name     = 'rg-e2egov-prjHb72x9-tst-neu'
    Location = 'northeurope'
    Tags     = @{
        'environment' = 'tst'
        'owner'       = 'e2egov'
    }
    Verbose  = $true
}
.\main.ps1 @rgParams
```

Creates or updates the Resource Group 'rg-e2egov-prjHb72x9-tst-neu' in the 'northeurope' region with the specified tags.

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


## Notes

- Operations are idempotent (safe to run multiple times).
- User confirmation is required for deletion unless `-Force` is specified.

> [!IMPORTANT]
> Rollback does not perform actual Resource group deletion. Resource groups may contain shared resources that are not part of this implementation but could be deployed by other systems or requirements over time. Deleting the Resource group could impact other services and operations relying on those resources.
