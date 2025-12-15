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
| `Name` | `String` | Yes | - | Required. The name of the Resource Group. |
| `Force` | `Switch` | No | - | Optional. Skip confirmation prompt and proceed with operations immediately. |
| `Location` | `String` | No | `'westeurope'` | Optional. The Azure region where the Resource Group will be created. Defaults to 'westeurope'. |
| `Rollback` | `Switch` | No | - | Optional. If specified, the script will not delete or modify the Resource Group. |
| `Tags` | `Object` | No | - | Optional. A hashtable of tags to assign to the Resource Group. |

## Examples

### Example 1

#### PowerShell

```powershell
$rgParams = @{
    Name     = 'rg-my-resource-group'
    Location = 'westeurope'
    Tags     = @{
        'environment' = 'prd'
        'owner'       = 'e2egov'
    }
    Verbose  = $true
}
.\main.ps1 @rgParams
```

Creates or updates the Resource Group 'rg-my-resource-group' in the 'westeurope' region with the specified tags.


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
- Does not perform actual resource group deletion due to the current implementation focusing on creation and updating tags only.
