<!-- markdownlint-disable no-duplicate-heading -->
<!-- omit from toc -->
# Team `[res\team\main.ps1]`

![Version](https://img.shields.io/badge/script--version-0.1.0-blue) [![License](https://img.shields.io/badge/license-MIT-purple)](https://github.com/msc365/az-devops-governance/blob/main/LICENSE)

Create or update an Azure DevOps Team within a specified project.

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

This script creates or updates an Azure DevOps Team within a specified project. It allows you to set team properties such as name and description.

If the team already exists, it updates the properties as needed.

## Parameters

| Parameter | Type | Required | Default | Description |
| :-- | :-- | :-- | :-- | :-- |
| `Organization` | `String` | Yes | - | Required.  The name of the Azure DevOps organization where the project is located. |
| `ProjectId` | `String` | Yes | - | Required.  The ID of the Azure DevOps project where the team will be created or updated |
| `TeamId` | `String` | Yes | - | Required.  The id or name of the Azure DevOps team to create or update. |
| `Description` | `String` | No | - | Optional. A description for the Azure DevOps team. |
| `Force` | `Switch` | No | - | Optional. If specified, the removal of the team will proceed without user confirmation. |
| `GroupMembership` | `Object[]` | No | - | No description provided. |
| `Name` | `String` | No | - | Optional. The display name of the Azure DevOps team. |
| `Remove` | `Switch` | No | - | Optional. If specified, the team will be removed instead of created or updated. <br /> <b> WARNING! </b> <br /> Use with caution! Removing a team is irreversible and may affect team members and their access to project resources. |
| `Settings` | `Hashtable` | No | - | Optional. A hashtable containing team settings to override the default settings. |

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
`-ProgressAction`, `-Verbose`, `-WarningAction`, and `-WarningVariable`.  
For more information, see [about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## Dependencies

This script requires the following PowerShell modules:

- `Az.Accounts`
- `Azure.DevOps.PSModule`

## Resources

- [deploy](deploy.ps1)

### Tests

- [default](tests/e2e/default)
- [remove](tests/e2e/remove)
- [update](tests/e2e/update)


## Notes

- The script uses `CmdletBinding()` and supports common parameters (`-Verbose`, `-Debug`, etc.)
- All operations are logged with `Write-Verbose` for debugging
- The script automatically imports the `Azure.DevOps.PSModule` if not already loaded
- Automatic connection to Azure DevOps organization if not already connected
- Team refresh operations occur after modifications to ensure data consistency
