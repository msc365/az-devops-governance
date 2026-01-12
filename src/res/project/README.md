<!-- markdownlint-disable no-duplicate-heading -->
<!-- omit from toc -->
# Project `[res\project\main.ps1]`

![Version](https://img.shields.io/badge/script%20version-0.1.0-blue) [![License](https://img.shields.io/badge/license-MIT-purple)](https://github.com/msc365/az-devops-governance/blob/main/LICENSE)

Create, update or rollback an Azure DevOps Project.

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

This script creates, updates or rolls back an Azure DevOps Project within a specified organization.

It provides options to configure project properties such as description, default team, process template, source control type, visibility, and feature states.

## PARAMETERS

| Parameter | Type | Required | Default | Description |
| :-- | :-- | :-- | :-- | :-- |
| `Name` | `String` | Yes | - | Required. The name of the Azure DevOps project to create, update or delete. |
| `CollectionUri` | `String` | No | `$env:DefaultAdoCollectionUri` | Optional. The collection URI of the Azure DevOps collection/organization, e.g. : `https://dev.azure.com/my-org`, `https://vssps.dev.azure.com/my-org`. |
| `DefaultTeam` | `String` | No | - | Optional. The name of the default team for the project. Defaults to '\<Project Name> Team'. |
| `Description` | `String` | No | - | Optional. A description for the Azure DevOps project. |
| `Features` | `Hashtable` | No | - | Optional. A hashtable defining the feature states for the project. Valid features are 'boards', 'repos', 'pipelines', 'testPlans', and 'artifacts' with states 'enabled' or 'disabled'. |
| `Process` | `String` | No | - | Optional. The process template to use for the project. Valid values are 'Agile', 'Scrum', 'CMMI', and 'Basic'. Defaults to the organization's default process. |
| `Rollback` | `Switch` | No | - | Optional. Switch to indicate if the operation should rollback (soft delete) the project and related resources. <br /> ⚠️ <b> WARNING! </b> <br /> Use with caution! Removing a project may affect teams relying on it. See [Notes](#notes) for more information. |
| `SourceControl` | `String` | No | - | Optional. The type of source control to use for the project. Valid values are 'Git' and 'Tfvc'. Defaults to 'Git'. |
| `Visibility` | `String` | No | - | Optional. The visibility of the project. Valid values are 'Private' and 'Public'. Defaults to 'Private'. |

## EXAMPLES

### Example 1

#### PowerShell

```powershell
$deploySplat = @{
    TemplateFile          = 'main.ps1'
    TemplateParameterFile = 'params\main.parameters.json'
}

.\deploy.ps1 @deploySplat -Verbose
```

Deploys the project using the specified template and parameters.


### Example 2

#### PowerShell

```powershell
$customSplat = @{
    TemplateFile          = 'main.ps1'
    TemplateParameterFile = 'params\custom.parameters.json'
}

.\deploy.ps1 @customSplat -Verbose
```

Deploys the project using the specified template and custom parameters.


### Example 3

#### PowerShell

```powershell
$rollbackSplat = @{
    TemplateFile          = 'main.ps1'
    TemplateParameterFile = 'params\main.parameters.json'
}

.\deploy.ps1 @rollbackSplat -Rollback -Confirm:$false -Verbose
```

Rolls back (removes) the project and related resources without confirmation.


### Example 4

#### PowerShell

```powershell
$paramSplat = @{
    CollectionUri = 'https://dev.azure.com/e2egov-org'
    Name          = 'e2egov-prjHb72x9'
    Description   = 'Default project description'
    DefaultTeam   = 'Default Team'
    SourceControl = 'Git'
    Process       = 'Agile'
    Visibility    = 'Private'
    Features      = @{
        boards    = 'enabled'
        repos     = 'enabled'
        pipelines = 'enabled'
        artifacts = 'enabled'
        testPlans = 'disabled'
    }
}

.\src\res\project\main.ps1 @paramSplat
```

Deploys or updates a project in the specified Azure DevOps organization using the provided parameters in code.


## OUTPUTS

```text
[PSCustomObject]@{
    id            = Project ID
    name          = Project Name
    description   = Project Description
    visibility    = Project Visibility
    defaultTeam   = Default Team Object
    featureStates = Array of Feature State Objects
    resourceType  = 'Project'
    collectionUri = Collection URI
    status        = Operation Status (Created, Updated, UnChanged, Removed, NotFound, Skipped)
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

### Tests

- [all](tests/e2e/all)
- [default](tests/e2e/default)
- [rollback](tests/e2e/rollback)
- [update](tests/e2e/update)


## NOTES

- Operations are idempotent (safe to run multiple times).
- Ensure you are logged in to Azure using Connect-AzAccount before running this script.
- User confirmation is required for deletion unless `-Confirm:$false` is specified.

> [!WARNING]
> You will have up to 28 days to recover this project. After, this project will be deleted resulting in a loss of all project artifacts including work items, repos, teams, and builds. [Learn more about deleting projects](https://aka.ms/az-delete-project).
