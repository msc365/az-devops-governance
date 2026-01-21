<!-- markdownlint-disable no-duplicate-heading -->
<!-- omit from toc -->
# Group `[res\group\main.ps1]`

![Version](https://img.shields.io/badge/script--version-0.1.0-blue) [![License](https://img.shields.io/badge/license-MIT-purple)](https://github.com/msc365/az-devops-governance/blob/main/LICENSE)

<!-- omit from toc -->
## Navigation

- [Description](#description)
- [Parameters](#parameters)
- [Outputs](#outputs)
- [Support](#support)
- [Dependencies](#dependencies)
- [Resources](#resources)
- [Notes](#notes)

## Description

{{ Fill in the Description }}

## Parameters

| Parameter | Type | Required | Default | Description |
| :-- | :-- | :-- | :-- | :-- |
| `Description` | `String` | Yes | - | {{ Fill in the Description }} |
| `DisplayName` | `String` | Yes | - | {{ Fill in the Description }} |
| `MailNickname` | `String` | Yes | - | {{ Fill in the Description }} |
| `Organization` | `String` | Yes | - | {{ Fill in the Description }} |
| `Project` | `String` | Yes | - | {{ Fill in the Description }} |
| `Force` | `Switch` | No | - | {{ Fill in the Description }} |
| `GroupMembership` | `String[]` | No | `@()` | {{ Fill in the Description }} |
| `IsAssignableToRole` | `Boolean` | No | `$true` | {{ Fill in the Description }} |
| `MailEnabled` | `Boolean` | No | `$false` | {{ Fill in the Description }} |
| `ManagedIdentity` | `Object` | No | - | {{ Fill in the Description }} |
| `Remove` | `Switch` | No | - | {{ Fill in the Description }} |
| `RoleAssignments` | `Object[]` | No | `@()` | {{ Fill in the Description }} |
| `SecurityEnabled` | `Boolean` | No | `$true` | {{ Fill in the Description }} |
| `ServiceConnection` | `Object` | No | - | {{ Fill in the Description }} |
| `Visibility` | `String` | No | `'Private'` | {{ Fill in the Description }} |

## Outputs

{{ Fill in the Outputs }}

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
- `Microsoft.Graph.Groups`

## Resources

- [deploy](deploy.ps1)

### Modules

- [nested_groupMembership](modules/nested_groupMembership.ps1)
- [nested_roleAssignment](modules/nested_roleAssignment.ps1)
- [nested_serviceConnection](modules/nested_serviceConnection.ps1)

### Tests

- [default](tests/e2e/default)


## Notes

- Operations are idempotent (safe to run multiple times).
- Ensure you are logged in to Azure using Connect-AzAccount before running this script.
- Automatically imports the `Azure.DevOps.PSModule` if not already loaded.
- Automatic connection to Azure DevOps organization.
- User confirmation is required for deletion unless `-Force` is specified.
