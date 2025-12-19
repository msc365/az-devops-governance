<!-- markdownlint-disable no-duplicate-heading -->
<!-- omit from toc -->
# Role Assignment `[res\shared\role-assignment\main.ps1]`

![Version](https://img.shields.io/badge/script--version-0.1.0-blue) [![License](https://img.shields.io/badge/license-MIT-purple)](https://github.com/msc365/az-devops-governance/blob/main/LICENSE)

Manage Azure Role Assignments with Desired State Configuration.

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

This script manages Azure Role Assignments using a desired state configuration approach.
It compares the current state of role assignments against the desired state and:

- Creates missing role assignments
- Removes extra role assignments (when Enforce is enabled)
- Keeps existing assignments that match the desired state

This ensures idempotent deployments and prevents configuration drift.

## Parameters

| Parameter | Type | Required | Default | Description |
| :-- | :-- | :-- | :-- | :-- |
| `ObjectId` | `String` | Yes | - | Required. The Object ID of the principal (user, group, or service principal) to manage role assignments for. |
| `RoleAssignments` | `Array` | Yes | - | Required. An array of PSCustomObjects defining the desired role assignments. Each object should contain: `roleDefinitionName`, `scope` See [Examples](#examples) for more information. |
| `EnforceDesiredState` | `Switch` | No | - | Optional. When specified, removes role assignments that exist but are not in the desired state. <br /> Without this flag, the script only ensures desired assignments exist (additive only). |
| `Force` | `Switch` | No | - | Optional. Switch to force deletion without confirmation during rollback. |
| `Rollback` | `Switch` | No | - | Optional. Switch to indicate if the operation should rollback (delete) the desired state. <br /> ⚠️ <b> WARNING! </b> <br /> Use with caution! Removing a role assignment is irreversible and may affect teams relying on it. |

## Examples

### Example 1

#### PowerShell

```powershell
$RoleAssignments = @(
    @{
        roleDefinitionName = 'Contributor'
        scope              = '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-e2egov-prjHb72x9-tst-weu'
    },
    @{
        roleDefinitionName = 'Reader'
        scope              = '/subscriptions/00000000-0000-0000-0000-000000000000'
    }
)

$params = @{
    ObjectId                = '00000000-0000-0000-0000-000000000000'
    DesiredRoleAssignments  = $RoleAssignments
    EnforceDesiredState     = $true
    Verbose                 = $true
}

.\main2.ps1 @params
```

Ensures the specified ObjectId has exactly the two role assignments defined, removing any others.

### Example 2

#### PowerShell

```powershell
$params = @{
    ObjectId                = '00000000-0000-0000-0000-000000000000'
    DesiredRoleAssignments  = $RoleAssignments
    Rollback                = $true
    Force                   = $true
}

.\main2.ps1 @params
```

Removes all role assignments defined in the desired state without confirmation.

## Outputs

### `System.Collections.ArrayList`

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
- When `EnforceDesiredState` is not specified, only missing assignments are created (safe mode).
- When `EnforceDesiredState` is specified, extra assignments are removed (full enforcement).
