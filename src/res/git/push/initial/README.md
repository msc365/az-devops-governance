<!-- markdownlint-disable no-duplicate-heading -->
<!-- omit from toc -->
# Initial `[res\git\push\initial\main.ps1]`

![Version](https://img.shields.io/badge/script%20version-0.1.0-blue) [![License](https://img.shields.io/badge/license-MIT-purple)](https://github.com/msc365/az-devops-governance/blob/main/LICENSE)

Creates a new initial commit in a specified Azure DevOps repository including specified files.

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

This cmdlet allows you to create an initial commit in a specified Azure DevOps repository.
You can specify the content of the commit, the commit message, and the branch to which the commit will be pushed.

## PARAMETERS

| Parameter | Type | Required | Default | Description |
| :-- | :-- | :-- | :-- | :-- |
| `RepositoryName` | `String` | Yes | - | Required. The name of the Azure DevOps repository to which the initial commit will be pushed. |
| `BranchName` | `String` | No | `'main'` | Optional. The name of the branch to which the initial commit will be pushed. Default is 'main'. |
| `CollectionUri` | `String` | No | `$env:DefaultAdoCollectionUri` | Optional. The collection URI of the Azure DevOps collection/organization, e.g., `https://dev.azure.com/my-org`. |
| `Files` | `Object[]` | No | `@()` | Optional. An array of file objects to be included in the initial commit. Each file object should have the following properties: <br> - `path`: The file path in the repository (e.g., 'src/index.js'). <br> - `content`: The content of the file as a string. This can be either raw text or a base64 encoded string. <br> - `contentType`: A string indicating the content type, either 'rawtext' or 'base64encoded'. |
| `Message` | `String` | No | `'Initial commit'` | Optional. The commit message for the initial commit. Default is 'Initial commit'. |
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
$params = @{
    CollectionUri  = 'https://dev.azure.com/my-org'
    ProjectName    = 'my-project-1'
    RepositoryName = 'my-repository-1'
    BranchName     = 'main'
    Message        = 'Initial commit'
    Files          = @(
        @{
            path        = '/README.md'
            content     = (Get-Content -Path 'assets/README.md' -Raw)
            contentType = 'rawtext'
        },
        @{
            path        = '/devops/pipeline/ci.yml'
            content     = (Get-Content -Path 'assets/ci.yml' -Raw)
            contentType = 'rawtext'
        },
        @{
            path        = '/.assets/tools.zip'
            content     = [Convert]::ToBase64String([IO.File]::ReadAllBytes('assets/tools.zip'))
            contentType = 'base64encoded'
        }
    )
}
```

New-AdoPushInitialCommit @params
Creates a new initial commit with the specified content in the specified repository and branch.

## OUTPUTS

```text
PSCustomObject representing the result of the push operation.

[PSCustomObject]@{
    pushId         = The ID of the push operation.
    commits        = The commits included in the push.
    refUpdates     = The reference updates for the push.
    pushedBy       = The user who initiated the push.
    date           = The date and time of the push.
    repositoryName = The name of the repository.
    projectName    = The name of the project.
    collectionUri  = The URI of the Azure DevOps collection.
    status         = The status of the push operation.
                     Possible values: 'Pushed', 'Failed', 'WouldPush', 'NotImplemented'
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

