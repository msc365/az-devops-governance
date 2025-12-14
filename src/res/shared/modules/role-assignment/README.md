<!-- markdownlint-disable no-duplicate-heading -->
<!-- omit from toc -->
# Role Assignment `[res\shared\modules\role-assignment\main.ps1]`

Create Azure Role Assignments.

<!-- omit from toc -->
## Navigation

- [Description](#description)
- [Parameters](#parameters)
- [Examples](#examples)
- [Outputs](#outputs)
- [Support](#support)

## Description

This script creates new Azure Role Assignments or removes existing ones based on the provided parameters.

## Parameters

| Parameter | Type | Required | Default | Description |
| :-- | :-- | :-- | :-- | :-- |
| `Force` | `SwitchParameter` | Yes | `-` | Optional. If specified during rollback, the script will not prompt for confirmation before removing the role assignment. |
| `ObjectId` | `String` | Yes | `-` | Required. The Object ID of the principal (user, group, or service principal) to assign the role to. |
| `roleDefinitionName` | `String` | Yes | `-` | Required. The name of the role definition to assign (e.g., 'Owner', 'Contributor', 'Reader', 'CustomRole'). |
| `scope` | `String` | Yes | `-` | Required. The scope at which the role assignment applies (e.g., subscription, resource group, resource). |
| `Rollback` | `SwitchParameter` | No | `-` | Optional. If specified, the script will remove the role assignment instead of creating it. |

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
`-ProgressAction`, `-Verbose`, `-WarningAction`, and `-WarningVariable`. For more information, see  
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

### SupportsShouldProcess

This script supports the `-WhatIf` and `-Confirm` parameters for safe execution:

- **`-WhatIf`**: Shows what would happen if the script runs without actually making any changes.
- **`-Confirm`**: Prompts for confirmation before performing each action.

