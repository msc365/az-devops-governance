<!-- markdownlint-disable no-duplicate-heading -->
<!-- omit from toc -->
# Team `[res\team\main.ps1]`

![Version](https://img.shields.io/badge/script--version-0.1.0-blue) [![License](https://img.shields.io/badge/license-MIT-purple)](https://github.com/msc365/az-devops-governance/blob/main/LICENSE)

Create, update or rollback an Azure DevOps Team within a specified project.

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

This script creates, updates or rolls back an Azure DevOps Team within a specified project. It allows you to set team properties such as name, description and team settings.

If the team already exists, it updates the properties and settings as needed.

## Parameters

| Parameter | Type | Required | Default | Description |
| :-- | :-- | :-- | :-- | :-- |
| `Project` | `String` | Yes | - | Required. The Azure DevOps project ID or Name where the environment will be created. |
| `TeamId` | `String` | Yes | - | Optional. The ID or Name of the Azure DevOps team to create, update or rollback. |
| `Description` | `String` | No | - | Optional. A description for the Azure DevOps team. |
| `Force` | `Switch` | No | - | Optional. Switch to force deletion without confirmation during rollback. |
| `GroupMembership` | `Object[]` | No | - | {{ Fill in the Description }} |
| `Rollback` | `Switch` | No | - | Optional. Switch to indicate if the operation should rollback (delete) the team and related resources. <br /> ⚠️ <b> WARNING! </b> <br /> Use with caution! Removing a team is irreversible and may affect teams relying on it. See [Notes](#notes) for more information. |
| `TeamSettings` | `Object` | No | - | Optional. A hashtable containing team settings to override the default settings. |

## Examples

### Example 1

#### PowerShell

```powershell
$deploySplat = @{
    TemplateFile          = 'main.ps1'
    TemplateParameterFile = 'params/main.parameters.json'
}

.\deploy.ps1 @deploySplat -Verbose
```

Deploys the team using the specified template and parameters.


### Example 2

#### PowerShell

```powershell
$customSplat = @{
    TemplateFile          = 'main.ps1'
    TemplateParameterFile = 'params\custom.parameters.json'
}

.\deploy.ps1 @customSplat -Verbose
```

Deploys the team using the specified template and custom parameters.


### Example 3

#### PowerShell

```powershell
$rollbackSplat = @{
    TemplateFile          = 'main.ps1'
    TemplateParameterFile = 'params/main.parameters.json'
}

.\deploy.ps1 @rollbackSplat -Rollback -Force -Verbose
```

Rolls back (deletes) the team and related resources without confirmation.


### Example 4

#### PowerShell

```powershell
$paramSplat = @{
    Project = 'e2egov-prjHb72x9'
    TeamId = 'Other Team'
    TeamSettings = @{
        BugsBehavior = "asRequirements"
        WorkingDays = @(
            "monday",
            "tuesday",
            "wednesday"
        )
    }
    Description = 'Other Team Description'
}

.\src\res\team\main.ps1 @paramSplat -Verbose
```

Deploys or updates a team in the specified Azure DevOps project using the provided parameters in code.


## Outputs

### `PSCustomObject`

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
- `Azure.DevOps.PSModule`

## Resources

- [deploy](deploy.ps1)

### Modules

- [nested_areaPaths](modules/nested_areaPaths.ps1)
- [nested_iterationPaths](modules/nested_iterationPaths.ps1)
- [nested_teamSettings](modules/nested_teamSettings.ps1)

### Tests

- [all](tests/e2e/all)
- [default](tests/e2e/default)
- [rollback](tests/e2e/rollback)
- [update](tests/e2e/update)


## Notes

- Operations are idempotent (safe to run multiple times).
- Ensure you are logged in to Azure using Connect-AzAccount before running this script.
- User confirmation is required for deletion unless `-Force` is specified.

> [!WARNING]
> Deleting a team removes all team configuration settings (dashboards, backlogs, boards). Work item data remains unchanged. Team configurations cannot be recovered once deleted. [Learn more about deleting teams](https://learn.microsoft.com/en-us/azure/devops/organizations/settings/rename-remove-team?view=azure-devops&tabs=preview-page#delete-a-team).
