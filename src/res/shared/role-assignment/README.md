<!-- markdownlint-disable no-duplicate-heading -->
<!-- omit from toc -->
# Role Assignment `[res\shared\role-assignment\main.ps1]`

![Version](https://img.shields.io/badge/script--version-0.1.0-blue) [![License](https://img.shields.io/badge/license-MIT-purple)](https://github.com/msc365/az-devops-governance/blob/main/LICENSE)

Create or rollback an Azure Role Assignment.

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

This script creates or rolls back an Azure Role Assignment based on the provided parameters.

## Parameters

| Parameter | Type | Required | Default | Description |
| :-- | :-- | :-- | :-- | :-- |
| `ObjectId` | `String` | Yes | - | Required. The Object ID of the principal (user, group, or service principal) to assign the role to. |
| `roleDefinitionName` | `String` | Yes | - | Required. The name of the role definition to assign e.g.: 'Owner', 'Contributor', 'Reader', or custom like 'Headless Owner (DevOps CI/CD)'. |
| `scope` | `String` | Yes | - | Required. The scope at which the role assignment applies (e.g., subscription, resource group, resource). |
| `Force` | `Switch` | No | - | Optional. If specified during rollback, the script will not prompt for confirmation before removing the role assignment. |
| `Rollback` | `Switch` | No | - | Optional. If specified, the script will remove the role assignment instead of creating it. |

## Examples

### Example 1

#### PowerShell

```powershell
$roleAssignmentParams = @{
    ObjectId           = '00000000-0000-0000-0000-000000000000'
    roleDefinitionName = 'Contributor'
    scope              = '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/MyResourceGroup'
    Verbose            = $true
}

.\main.ps1 @roleAssignmentParams
```

Creates a Contributor role assignment for the specified ObjectId at the given resource group scope.

### Example 2

#### PowerShell

```powershell
$roleAssignmentParams = @{
    ObjectId           = '00000000-0000-0000-0000-000000000000'
    roleDefinitionName = 'Contributor'
    scope              = '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/MyResourceGroup'
    Rollback           = $true
    Force              = $true
}

.\main.ps1 @roleAssignmentParams
```

Removes the Contributor role assignment for the specified ObjectId at the given resource group scope without confirmation.

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
