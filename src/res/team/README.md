<!-- cSpell: ignore hashtable msc365 -->

<!-- omit from toc -->
# Azure DevOps Team Resource

This PowerShell script (`main.ps1`) creates or updates an Azure DevOps Team within a specified project. It provides comprehensive team management capabilities including configuration of team properties, settings, iteration paths, and area paths.

- [Overview](#overview)
- [Parameters](#parameters)
- [Return Values](#return-values)
- [Exceptions and Errors](#exceptions-and-errors)
- [Dependencies](#dependencies)
- [Usage Examples](#usage-examples)
- [Script Behavior](#script-behavior)
- [Team Configuration Details](#team-configuration-details)
- [Notes](#notes)


## Overview

The script manages Azure DevOps Teams with the following capabilities:
- Creates new teams with specified configuration
- Updates existing team properties (name, description)
- Configures team settings (backlog visibilities, bugs behavior, working days)
- Manages iteration path assignments
- Creates and assigns area paths
- Supports team removal (with caution)

**Important Note:**
- Team settings are based on the project's default team settings unless explicitly overridden

## Parameters

### Mandatory Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `Organization` | string | The name of the Azure DevOps organization where the team will be created or updated |
| `ProjectId` | string | The ID of the Azure DevOps project where the team will be created or updated |
| `TeamId` | string | The ID or name of the Azure DevOps team to create or update |

### Optional Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `Name` | string | Uses `TeamId` | The display name of the Azure DevOps team |
| `Description` | string | N/A | A description for the Azure DevOps team |
| `Settings` | hashtable | Inherits from default team | A hashtable containing team settings to override defaults (e.g., backlog visibilities, bugs behavior, working days) |
| `RemoveDeployment` | switch | N/A | If specified, removes the team instead of creating/updating it |

### Team Settings Configuration

Team settings are inherited from the project's default team unless explicitly overridden in the `Settings` parameter. Common settings include:

```powershell
@{
    bugsBehavior       = 'AsRequirements'  # or 'AsTasks', 'Off'
    workingDays        = @('monday', 'tuesday', 'wednesday', 'thursday', 'friday')
    backlogIteration   = 'ProjectName'
    defaultIteration   = 'ProjectName\Iteration 1'
}
```

## Return Values

| Scenario | Return Type | Description |
|----------|-------------|-------------|
| Team created/updated successfully | PSCustomObject | Returns the Azure DevOps team object with all properties including id, name, description, and projectId |
| Team removed successfully | PSCustomObject | Returns object with `Removed` (boolean) and `Message` (string) properties |
| Team doesn't exist (when removing) | PSCustomObject | Returns object with `Removed = $false` and status message |

## Exceptions and Errors

The script uses `$ErrorActionPreference = 'Stop'` and will throw exceptions for:
- Authentication failures to Azure DevOps
- Invalid organization or project ID
- Permission issues
- API communication errors
- Team creation/update failures
- Invalid settings configuration

## Dependencies

### PowerShell Modules
- **Azure.DevOps.PSModule** - Required for all Azure DevOps operations

### Functions Used
- `Connect-AdoOrganization` - Establishes connection to Azure DevOps
- `Get-AdoContext` - Retrieves current Azure DevOps context
- `Get-AdoProject` - Retrieves project information
- `Get-AdoTeam` - Retrieves team information
- `New-AdoTeam` - Creates new teams
- `Set-AdoTeam` - Updates team properties
- `Remove-AdoTeam` - Deletes teams
- `Get-AdoTeamSetting` - Retrieves team settings
- `Set-AdoTeamSetting` - Updates team settings
- `Get-AdoTeamIteration` - Retrieves team iterations
- `Set-AdoTeamIteration` - Sets (copies) iterations to team
- `Get-AdoClassificationNode` - Retrieves area/iteration paths
- `New-AdoClassificationNode` - Creates area/iteration paths
- `Get-AdoTeamFieldValue` - Retrieves team field values
- `Set-AdoTeamFieldValue` - Updates team field values

## Usage Examples

### Example 1: Create a New Team with Default Settings

```powershell
$paramSplat = @{
    Organization = 'my-org'
    ProjectId    = 'my-project'
    TeamId       = 'backend-team'
    Name         = 'Backend Development Team'
    Description  = 'Team responsible for backend services'
}

.\src\res\team\main.ps1 @paramSplat
```

This creates a team with:
- Default team settings inherited from project's default team
- Automatic iteration path configuration
- Area path created as `{ProjectName}\Area\Backend Development Team`

### Example 2: Create Team with Custom Settings

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

### Example 3: Update an Existing Team's Description

```powershell
$paramSplat = @{
    Organization = 'my-org'
    ProjectId    = 'my-project'
    TeamId       = 'existing-team'
    Description  = 'Updated team description with new responsibilities'
}

.\src\res\team\main.ps1 @paramSplat
```

**Note:** Only changed properties will be updated.

### Example 4: Create Team with Minimal Configuration

```powershell
$paramSplat = @{
    Organization = 'my-org'
    ProjectId    = 'my-project'
    TeamId       = 'ops-team'
}

.\src\res\team\main.ps1 @paramSplat
```

This creates a team using `TeamId` as the name and inherits all settings from the project's default team.

### Example 5: Remove a Team (Destructive Operation)

```powershell
$paramSplat = @{
    Organization     = 'my-org'
    ProjectId        = 'my-project'
    TeamId           = 'deprecated-team'
    RemoveDeployment = $true
}

.\src\res\team\main.ps1 @paramSplat
```

> [!WARNING]
> Using `-RemoveDeployment` will permanently delete the team. This action cannot be undone.

## Script Behavior

### Create Operation
1. Checks if project exists
2. If team doesn't exist:
   - Creates new team with specified configuration
   - Inherits or applies team settings
   - Copies iteration paths from project if none exist
   - Creates and assigns area path
3. Returns the created team object

### Update Operation
1. Checks if team exists
2. If exists:
   - Updates name and description if changed
   - Updates team settings if specified
   - Preserves existing iteration and area configurations
3. Returns the updated team object

### Remove Operation
1. Checks if team exists
2. If exists:
   - Removes the team
   - Returns PSCustomObject with `Removed = $true`
3. If not exists:
   - Returns PSCustomObject with `Removed = $false`

## Team Configuration Details

### Iteration Path Management
- Checks if team has iteration paths configured
- If no iterations exist, copies all iteration paths from project level
- Preserves existing iteration configurations on updates

### Area Path Management
- Creates a dedicated area path for the team: `{ProjectName}\Area\{TeamName}`
- Sets the team's area path to match the team name
- Configures the area path as the team's default value

## Notes

- The script uses `CmdletBinding()` and supports common parameters (`-Verbose`, `-Debug`, etc.)
- All operations are logged with `Write-Verbose` for debugging
- The script automatically imports the `Azure.DevOps.PSModule` if not already loaded
- Automatic connection to Azure DevOps organization if not already connected
- Team refresh operations occur after modifications to ensure data consistency
- Avoids unnecessary updates when team properties are already up to date

<!-- omit from toc -->
## Version Information

- **Version:** 1.0
- **Author:** Martin Swinkels
- **Company:** MSc365.eu
- **Copyright:** 2025 (c) MSc365.eu, Martin Swinkels
- **License:** [MIT License](https://github.com/msc365/az-devops-governance/blob/main/LICENSE)
- **Project URI:** [az-devops-governance](https://github.com/msc365/az-devops-governance)
