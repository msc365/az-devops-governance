<!-- markdownlint-disable no-duplicate-heading -->
<!-- omit from toc -->
# Team `[res\team\main.ps1]`

![Version](https://img.shields.io/badge/version-1.0-blue)

Create or update an Azure DevOps Team within a specified project.

<!-- omit from toc -->
## Navigation

- [Description](#description)
- [Parameters](#parameters)
- [Examples](#examples)
- [Outputs](#outputs)
- [Support](#support)
- [Dependencies](#dependencies)
- [Related Scripts](#related-scripts)
- [Notes](#notes)

## Description

This script creates or updates an Azure DevOps Team within a specified project. It allows you to set team properties such as name and description.

    If the team already exists, it updates the properties as needed.

## Parameters

| Parameter | Type | Required | Default | Description |
| :-- | :-- | :-- | :-- | :-- |
| `Organization` | `String` | Yes | `-` | Mandatory. The name of the Azure DevOps organization where the project is located. |
| `ProjectId` | `String` | Yes | `-` | Mandatory. The ID of the Azure DevOps project where the team will be created or updated |
| `TeamId` | `String` | Yes | `-` | Mandatory. The id or name of the Azure DevOps team to create or update. |
| `Description` | `String` | No | `-` | Optional. A description for the Azure DevOps team. |
| `Force` | `SwitchParameter` | No | `-` | No description provided. |
| `GroupMembership` | `Object[]` | No | `-` | No description provided. |
| `Name` | `String` | No | `-` | Optional. The display name of the Azure DevOps team. |
| `Remove` | `SwitchParameter` | No | `-` | No description provided. |
| `RemoveDeployment` | `Object` | No | `-` | Optional. If specified, the team will be removed instead of created or updated.      > [!WARNING]     > Use with caution! Removing a team is irreversible and may affect team members and their access to project resources. |
| `Settings` | `Hashtable` | No | `-` | Optional. A hashtable containing team settings to override the default settings. |

## Examples

### Example 1

#### PowerShell

```powershell
$paramSplat = @{
    Organization     = 'my-org'
    ProjectId        = 'my-project'
    TeamId           = 'my-other-team'
    Name             = 'my-other-team-updated'
    Description      = 'My team description'
}

..\src\res\team\main.ps1 @paramSplat -Verbose
```

This example creates or updates a team named 'my-team' in the 'my-project' project within the 'my-org' organization, setting its name and description.

## Outputs

Returns: `object`

## Support

### CommonParameters

This cmdlet supports the common parameters: `-Debug`, `-ErrorAction`, `-ErrorVariable`,  
`-InformationAction`, `-InformationVariable`, `-OutBuffer`, `-OutVariable`, `-PipelineVariable`,  
`-ProgressAction`, `-Verbose`, `-WarningAction`, and `-WarningVariable`. For more information, see  
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## Dependencies

This script requires the following PowerShell modules:

- `Az.Accounts`
- `Azure.DevOps.PSModule`

## Related Scripts

- [deploy](deploy.ps1)
- [tests/e2e/default](tests/e2e/default/main.tests.ps1)
- [tests/e2e/remove](tests/e2e/remove/main.tests.ps1)
- [tests/e2e/update](tests/e2e/update/main.tests.ps1)


## Notes

- The script uses `CmdletBinding()` and supports common parameters (`-Verbose`, `-Debug`, etc.)
- All operations are logged with `Write-Verbose` for debugging
- The script automatically imports the `Azure.DevOps.PSModule` if not already loaded
- Automatic connection to Azure DevOps organization if not already connected
- Team refresh operations occur after modifications to ensure data consistency
