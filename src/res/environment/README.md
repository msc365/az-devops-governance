<!-- markdownlint-disable no-duplicate-heading -->
<!-- omit from toc -->
# Environment `[res\environment\main.ps1]`

![Version](https://img.shields.io/badge/script%20version-0.1.0-blue) [![License](https://img.shields.io/badge/license-MIT-purple)](https://github.com/msc365/az-devops-governance/blob/main/LICENSE)

Create, update or rollback an Azure DevOps Environment.

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

This PowerShell script creates, updates or rolls back an Azure DevOps Environment.

It provides comprehensive environment management capabilities including configuration of an optional resource group
and its properties as a scoped environment.

## PARAMETERS

| Parameter | Type | Required | Default | Description |
| :-- | :-- | :-- | :-- | :-- |
| `Name` | `String` | Yes | - | Required. The name of the environment to create, update, or remove. |
| `CollectionUri` | `String` | No | `$env:DefaultAdoCollectionUri` | Optional. The collection URI of the Azure DevOps collection/organization, e.g., `https://dev.azure.com/my-org`. |
| `Description` | `String` | No | - | Optional. A description for the environment. |
| `ProjectName` | `String` | No | `$env:DefaultAdoProjectName` | Optional. The Azure DevOps project ID or Name where the environment will be created. |
| `Rollback` | `Switch` | No | - | Optional. Switch to indicate if the operation should rollback (remove) the environment and related resources. <br> ⚠️ WARNING: Use with caution! Removing an environment is irreversible and may affect teams relying on it. |

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

Deploys the environment using the specified template and parameters.

### Example 2

#### PowerShell

```powershell
$customSplat = @{
    TemplateFile          = 'main.ps1'
    TemplateParameterFile = 'params\custom.parameters.json'
}

.\deploy.ps1 @customSplat -Verbose
```

Deploys the environment using the specified template and custom parameters.

### Example 3

#### PowerShell

```powershell
$rollbackSplat = @{
    TemplateFile          = 'main.ps1'
    TemplateParameterFile = 'params/main.parameters.json'
}

.\deploy.ps1 @rollbackSplat -Rollback -Confirm:$false -Verbose
```

Rolls back (removes) the environment and related resources without confirmation.

### Example 4

#### PowerShell

```powershell
$paramSplat = @{
    CollectionUri  = 'https://dev.azure.com/e2egov-org'
    ProjectName    = 'e2egov-prjHb72x9'
    Name           = 'env-e2egov-prjHb72x9-tst'
    Description    = 'Default environment description'
}
.\main.ps1 @paramSplat -Verbose
```

Deploys a new environment with the specified parameters.

## OUTPUTS

```text
[PSCustomObject]@{
    id             = Environment ID
    name           = Environment Name
    description    = Environment Description
    createdBy      = User who created the environment
    createdOn      = Timestamp of environment creation
    lastModifiedBy = User who last modified the environment
    lastModifiedOn = Timestamp of last modification
    projectName    = Azure DevOps Project Name
    collectionUri  = Azure DevOps Collection URI
    status         = Operation Status (Created, Updated, NoChange, Removed, NotFound, Skipped)
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
- `Az.Resources`
- `Azure.DevOps.PSModule`

## RESOURCES

- [deploy](deploy.ps1)

### Tests

- [all](tests/e2e/all)
- [default](tests/e2e/default)
- [rollback](tests/e2e/rollback)
- [update](tests/e2e/update)
- [unit](tests/unit)


## NOTES

- Operations are idempotent (safe to run multiple times).
- Ensure you are logged in to Azure using Connect-AzAccount before running this script.
- User confirmation is required unless `-Confirm:$false` is specified.
