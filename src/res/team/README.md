<!-- cSpell: ignore hashtable msc365 -->
<!-- omit from toc -->
# Azure DevOps Team `[res]`

This PowerShell script (`main.ps1`) creates or updates an Azure DevOps Team within a specified project. It provides comprehensive team management capabilities including configuration of team properties, settings, iteration paths, and area paths. The script manages Azure DevOps Teams with the following capabilities:

- Creates new teams with specified configuration
- Updates existing team properties (_name_, _description_)
- Configures team settings (_backlog visibilities_, _bugs behavior_, _working days_)
- Manages iteration path assignments
- Creates and assigns area paths
- Supports team removal (with caution)

<!-- omit from toc -->
## Navigation

- [PowerShell Functions](#powershell-functions)
- [Usage examples](#usage-examples)
- [Parameters](#parameters)
- [Outputs](#outputs)
- [Notes](#notes)

## PowerShell Functions

The `Azure.DevOps.PSModule` is required for the following Azure DevOps operations:

| Function | Description |
| --- | --- |
| `Connect-AdoOrganization` | Establishes connection to Azure DevOps |
| `Get-AdoContext` | Retrieves current Azure DevOps context |
| `Get-AdoProject` | Retrieves project information |
| `Get-AdoTeam` | Retrieves team information |
| `New-AdoTeam` | Creates new teams |
| `Set-AdoTeam` | Updates team properties |
| `Remove-AdoTeam` | Deletes teams |
| `Get-AdoTeamSetting` | Retrieves team settings |
| `Set-AdoTeamSetting` | Updates team settings |
| `Get-AdoTeamIteration` | Retrieves team iterations |
| `Set-AdoTeamIteration` | Sets (copies) iterations to team |
| `Get-AdoClassificationNode` | Retrieves area/iteration paths |
| `New-AdoClassificationNode` | Creates area/iteration paths |
| `Get-AdoTeamFieldValue` | Retrieves team field values |
| `Set-AdoTeamFieldValue` | Updates team field values |

## Usage examples

### Example 1: Deploy using the deploy script with parameter file

```powershell
.\src\res\team\deploy.ps1
```

This uses the `deploy.ps1` script which:

- Reads configuration from `params\main.parameters.json`
- Executes `main.ps1` with the parameters from the JSON file
- Simplifies deployment by separating configuration from execution

You can also specify custom parameter files:

```powershell
.\src\res\team\deploy.ps1 -templateParameterFile 'params\custom.parameters.json'
```

To remove a team using the deploy script:

```powershell
.\src\res\team\deploy.ps1 -Remove -Force
```

### Example 2: Create a new team with default settings

```powershell
$paramSplat = @{
    Organization = 'my-org'
    ProjectId    = 'my-project'
    TeamId       = 'backend-team'
    Description  = 'Team responsible for backend services'
}

.\src\res\team\main.ps1 @paramSplat
```

This creates a team with:

- Default team settings inherited from project's default team
- Automatic iteration path configuration
- Area path created as `{ProjectName}\Area\backend-team`

### Example 3: Create team with custom settings

```powershell
$customSettings = @{
    bugsBehavior = 'AsRequirements'
    workingDays  = @('monday', 'tuesday', 'wednesday', 'thursday', 'friday')
}

$paramSplat = @{
    Organization = 'my-org'
    ProjectId    = 'my-project'
    TeamId       = 'frontend-team'
    Description  = 'UI/UX Development Team'
    Settings     = $customSettings
}

.\src\res\team\main.ps1 @paramSplat
```

### Example 4: Update an existing team's description

```powershell
$paramSplat = @{
    Organization = 'my-org'
    ProjectId    = 'my-project'
    TeamId       = 'existing-team'
    Description  = 'Updated team description with new responsibilities'
}

.\src\res\team\main.ps1 @paramSplat
```

> [!NOTE]  
> Only changed properties will be updated.

### Example 5: Remove a team (destructive operation)

```powershell
$paramSplat = @{
    Organization = 'my-org'
    ProjectId    = 'my-project'
    TeamId       = 'deprecated-team'
    Remove       = $true
}

.\src\res\team\main.ps1 @paramSplat
```

> [!WARNING]
> Using `-Remove` and `-Force` will permanently delete the team. This action cannot be undone.

## Parameters

### Required parameters

| Parameter | Type | Description |
| --- | --- | --- |
| `Organization` | string | The name of the Azure DevOps organization where the team will be created or updated |
| `ProjectId` | string | The ID of the Azure DevOps project where the team will be created or updated |
| `TeamId` | string | The ID or name of the Azure DevOps team to create or update |

### Optional parameters

| Parameter | Type | Default | Valid values | Description |
| --- | --- | --- | --- | --- |
| `Name` | string | Uses `TeamId` |  | The display name of the Azure DevOps team |
| `Description` | string |  |  | A description for the Azure DevOps team |
| `Settings` | hashtable | Inherits from default team | See below ¹ | A hashtable containing team settings to override defaults |
| `Remove` | switch |  |  | If specified, removes the team instead of creating/updating it |
| `Force` | switch |  |  | If specified, removes the team without user feedback for automated processes |

¹ Default _Settings_ Configuration (inherited from project's default team):

```powershell
@{
    bugsBehavior     = 'AsRequirements'  # or 'AsTasks', 'Off'
    workingDays      = @(
        'monday'
        'tuesday'
        'wednesday'
        'thursday'
        'friday'
    )
    backlogIteration = 'ProjectName'
    defaultIteration = 'ProjectName\Iteration 1'
}
```

## Outputs

| Scenario | Return Type | Description |
| --- | --- | --- |
| Team created/updated successfully | PSCustomObject | Returns the Azure DevOps team object with all properties including id, name, description, and projectId |
| Team removed successfully | PSCustomObject | Returns object with `Removed = $true` and `Status = Message` |
| Team doesn't exist (when removing) | PSCustomObject | Returns object with `Removed = $false` and `Status = Message` |

## Notes

- The script uses `CmdletBinding()` and supports common parameters (`-Verbose`, `-Debug`, etc.)
- All operations are logged with `Write-Verbose` for debugging
- The script automatically imports the `Azure.DevOps.PSModule` if not already loaded
- Automatic connection to Azure DevOps organization if not already connected
- Team refresh operations occur after modifications to ensure data consistency
