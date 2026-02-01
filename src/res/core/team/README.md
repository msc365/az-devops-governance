<!-- markdownlint-disable no-duplicate-heading -->
<!-- omit from toc -->
# Team `[res\team\main.ps1]`

![Version](https://img.shields.io/badge/script%20version-0.1.0-blue) [![License](https://img.shields.io/badge/license-MIT-purple)](https://github.com/msc365/az-devops-governance/blob/main/LICENSE)

Manage an Azure DevOps team within a project.

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

This script creates, updates, or removes an Azure DevOps team within a specified project,
including configuration of team settings, iteration paths, and area paths.

## PARAMETERS

| Parameter | Type | Required | Default | Description |
| :-- | :-- | :-- | :-- | :-- |
| `TeamName` | `String` | Yes | - | Mandatory. The name of the Azure DevOps team to manage. |
| `CollectionUri` | `String` | No | `$env:DefaultAdoCollectionUri` | Optional. The collection URI of the Azure DevOps collection/organization, e.g., `https://dev.azure.com/my-org`. |
| `Description` | `String` | No | - | Optional. The description of the Azure DevOps team. |
| `ProjectName` | `String` | No | `$env:DefaultAdoProjectName` | Optional. The Azure DevOps project ID or Name where the team will be managed. |
| `Rollback` | `Switch` | No | - | Optional. Switch to indicate if the operation should rollback (remove) the specified team. |
| `TeamSettings` | `Object` | No | - | Optional. A hashtable or PSCustomObject containing team settings to configure. |

## EXAMPLES

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

.\deploy.ps1 @rollbackSplat -Rollback -Confirm:$false -Verbose
```

Rolls back (removes) the team and related resources without confirmation.

### Example 4

#### PowerShell

```powershell
$params = @{
    CollectionUri = 'https://dev.azure.com/my-org'
    ProjectName   = 'e2egov-prjHb72x9'
    TeamName      = 'Another Team'
    Description   = 'Another team description'
    TeamSettings  = @{
        backlogVisibilities   = @{
            'Microsoft.EpicCategory'        = false
            'Microsoft.FeatureCategory'     = true
            'Microsoft.RequirementCategory' = true
        }
        bugsBehavior          = 'asRequirements'
        defaultIterationMacro = '@currentIteration'
        workingDays           = @(
            'monday'
            'tuesday'
            'wednesday'
            'thursday'
            'friday'
        )
    }
}
.\main.ps1 @params
```

Creates or updates the specified team within the given project.

## OUTPUTS

```text
[PSCustomObject]@{
    id            = Team ID
    name          = Team Name
    description   = Team Description
    teamSettings  = Configured Team Settings
    projectName   = Azure DevOps Project Name
    collectionUri = Azure DevOps Collection URI
    status        = Operation Status (Created, Updated, Added, NoChange, Removed, NotFound)
}
```

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
- `Azure.DevOps.PSModule`

## RESOURCES

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


## NOTES

- Operations are idempotent (safe to run multiple times).
- Ensure you are logged in to Azure using Connect-AzAccount before running this script.
- User confirmation is required for deletion unless `-Force` is specified.

> [!WARNING]
> Deleting a team removes all team configuration settings (dashboards, backlogs, boards). Work item data remains unchanged. Team configurations cannot be recovered once deleted. [Learn more about deleting teams](https://learn.microsoft.com/en-us/azure/devops/organizations/settings/rename-remove-team?view=azure-devops&tabs=preview-page#delete-a-team).
