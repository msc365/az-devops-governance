<!-- markdownlint-disable no-duplicate-heading -->
<!-- omit from toc -->
# Group Membership `[res\group-membership\main.ps1]`

![Version](https://img.shields.io/badge/script%20version-0.1.0-blue) [![License](https://img.shields.io/badge/license-MIT-purple)](https://github.com/msc365/az-devops-governance/blob/main/LICENSE)

Manage Azure DevOps group memberships based on Entra ID security groups.

<!-- omit from toc -->
## NAVIGATION

- [DESCRIPTION](#description)
- [PARAMETERS](#parameters)
- [EXAMPLES](#examples)
- [OUTPUTS](#outputs)
- [SUPPORT](#support)
- [DEPENDENCIES](#dependencies)
- [RESOURCES](#resources)

## DESCRIPTION

This script manages Azure DevOps group memberships by adding specified Entra ID security groups to built-in Azure DevOps groups within a given project.

## PARAMETERS

| Parameter | Type | Required | Default | Description |
| :-- | :-- | :-- | :-- | :-- |
| `GroupMembership` | `String` | Yes | - | Mandatory. The name of the Azure DevOps built-in group to which the Entra ID security group will be added, e.g., `Readers`, `Contributors`, `Project Administrators`. |
| `UniqueName` | `String` | Yes | - | Mandatory. The UniqueName (MailNickname) of the Entra ID security group to be added to Azure DevOps groups. |
| `CollectionUri` | `String` | No | `$env:DefaultAdoCollectionUri` | Optional. The collection URI of the Azure DevOps collection/organization, e.g., `https://dev.azure.com/my-org`. |
| `ProjectName` | `String` | No | `$env:DefaultAdoProjectName` | Optional. The Azure DevOps project ID or Name where the environment will be created. |
| `Rollback` | `Switch` | No | - | Optional. Switch to indicate if the operation should be rolled back (i.e., remove the specified group memberships). <br> ⚠️ Note: Rollback functionality is not yet implemented. |

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

Deploys the group membership using the specified template and parameters.

### Example 2

#### PowerShell

```powershell
$customSplat = @{
    TemplateFile          = 'main.ps1'
    TemplateParameterFile = 'params\custom.parameters.json'
}

.\deploy.ps1 @customSplat -Verbose
```

Deploys the group membership using the specified template and custom parameters.

### Example 3

#### PowerShell

```powershell
$rollbackSplat = @{
    TemplateFile          = 'main.ps1'
    TemplateParameterFile = 'params/main.parameters.json'
}

.\deploy.ps1 @rollbackSplat -Rollback -Confirm:$false -Verbose
```

Rolls back (removes) the group membership and related resources without confirmation.

### Example 4

#### PowerShell

```powershell
$params = @{
    CollectionUri   = 'https://dev.azure.com/e2egov-org'
    ProjectName     = 'e2egov-prjHb72x9'
    UniqueName      = 'e2egov-prjHb72x9-devs'
    GroupMembership = 'Contributors'
}
.\main.ps1 @params -Verbose
```

Deploys a new group membership with the specified parameters.

## OUTPUTS

```text
[PSCustomObject]@{
    memberDescriptor    = The descriptor of the member (Entra ID security group)
    containerDescriptor = The descriptor of the container (Azure DevOps built-in group)
    uniqueName          = Entra ID Group UniqueName (MailNickname)
    originId            = Entra ID Group Object ID
    groupMembership     = Azure DevOps Built-in Group Name
    projectName         = Azure DevOps Project Name
    collectionUri       = Azure DevOps Collection URI
    status              = Operation Status (Created, Updated, NoChange, Removed, NotFound)
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
- `Microsoft.Graph.Groups`

## RESOURCES

- [deploy](deploy.ps1)

### Tests

- [default](tests/e2e/default)
- [rollback](tests/e2e/rollback)
- [unit](tests/unit)

