<!-- markdownlint-disable no-duplicate-heading -->
<!-- omit from toc -->
# Role Assignment `[res\shared\role-assignment\main.ps1]`

![Version](https://img.shields.io/badge/script%20version-0.1.0-blue) [![License](https://img.shields.io/badge/license-MIT-purple)](https://github.com/msc365/az-devops-governance/blob/main/LICENSE)

Manage Azure Role Assignments with Desired State Configuration.

<!-- omit from toc -->
## NAVIGATION

- [DESCRIPTION](#description)
- [PARAMETERS](#parameters)
- [EXAMPLES](#examples)
- [OUTPUTS](#outputs)
- [SUPPORT](#support)
- [DEPENDENCIES](#dependencies)
- [RESOURCES](#resources)
- [NOTES](#notes)

## DESCRIPTION

This script manages Azure Role Assignments using a desired state configuration approach.
It compares the current state of role assignments against the desired state and:

- Creates missing role assignments (additive only)
- Keeps existing assignments that match the desired state
- To remove assignments: use `-Rollback` with the same assignments, then deploy new desired state

This ensures safe, explicit operations and prevents accidental deletion of role assignments.

## PARAMETERS

| Parameter | Type | Required | Default | Description |
| :-- | :-- | :-- | :-- | :-- |
| `ObjectId` | `String` | Yes | - | Required. The Object ID of the principal (user, group, or service principal) to manage role assignments for. |
| `RoleAssignments` | `Array` | Yes | - | Required. An array of hashtables defining the desired role assignments. Each object should contain: <br> - roleDefinitionName: The name of the role (e.g.: 'Contributor', 'Reader') <br> - scope: The resource scope (e.g.: subscription or resource group) |
| `Rollback` | `Switch` | No | - | Optional. Switch to indicate if the operation should rollback (delete) the desired state. |

## EXAMPLES

### Example 1

#### PowerShell

```powershell
$roleAssignments = @(
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
    ObjectId        = '00000000-0000-0000-0000-000000000000'
    RoleAssignments = $roleAssignments
    Verbose         = $true
}

.\main.ps1 @params
```

Ensures the specified ObjectId has the two role assignments defined. Existing assignments are preserved.


### Example 2

#### PowerShell

```powershell
$params = @{
    ObjectId        = '00000000-0000-0000-0000-000000000000'
    RoleAssignments = $roleAssignments
    Rollback        = $true
}

.\main.ps1 @params -Confirm:$false
```

Removes all role assignments defined in the desired state without confirmation prompts.


## OUTPUTS

### `PSCustomObject[]`

## SUPPORT

### CommonParameters

This cmdlet supports the common parameters: `-Debug`, `-ErrorAction`, `-ErrorVariable`,  
`-InformationAction`, `-InformationVariable`, `-OutBuffer`, `-OutVariable`, `-PipelineVariable`,  
`-ProgressAction`, `-Verbose`, `-WarningAction`, and `-WarningVariable`.  
For more information, see [about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

### SupportsShouldProcess

This script supports the `-WhatIf` and `-Confirm` parameters for safe execution:

- **`-WhatIf`**: Shows what would happen if the script runs without actually making any changes.
- **`-Confirm`**: Prompts for confirmation before performing each action.

## DEPENDENCIES

This script requires the following PowerShell modules:

- `Az.Accounts`
- `Az.Resources`

## RESOURCES

- [deploy](deploy.ps1)

### Tests

- [default](tests/e2e/default)
- [rollback](tests/e2e/rollback)
- [unit](tests/unit)


## NOTES

> [!CAUTION]
> Use the `-Rollback` flag with caution.
>
> - Deployment mode is always additive - only creates missing assignments, never removes.
> - To remove assignments: first rollback with same RoleAssignments, then deploy new desired state.
> - Only manages assignments where ObjectId + Scope + Role match the RoleAssignments parameter.
> - Uses `SupportsShouldProcess` for confirmation prompts on destructive operations (Rollback).
> - Script is scoped to specific _objectId_ and assignments in _RoleAssignments_ only.
> - Does not affect other principals or assignments outside the defined scope.
>
> Always use `-WhatIf` first to preview changes before running with `-Rollback` in production.
