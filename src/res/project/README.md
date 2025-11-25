<!-- cSpell: ignore hashtable msc365 -->
<!-- omit from toc -->
# Azure DevOps Project Resource

This PowerShell script (`main.ps1`) creates or updates an Azure DevOps Project within a specified organization. It provides comprehensive project management capabilities including configuration of project properties, feature states, and team settings.

- [Overview](#overview)
- [Parameters](#parameters)
- [Return Values](#return-values)
- [Exceptions and Errors](#exceptions-and-errors)
- [Dependencies](#dependencies)
- [Usage Examples](#usage-examples)
- [Script Behavior](#script-behavior)
- [Feature ID Mapping](#feature-id-mapping)
- [Notes](#notes)

## Overview

The script manages Azure DevOps Projects with the following capabilities:
- Creates new projects with specified configuration
- Updates existing project properties (description, visibility)
- Configures project feature states (Boards, Repos, Pipelines, TestPlans, Artifacts)
- Sets default team name
- Supports project removal (with caution)

**Important Limitations:**
- Process template can only be set during project creation (cannot be changed after creation)
- Source control type can only be set during project creation (cannot be changed after creation)

## Parameters

### Mandatory Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `Organization` | string | The name of the Azure DevOps organization where the project will be created or updated |
| `Name` | string | The name of the Azure DevOps project to create or update |
| `DefaultTeam` | string | The name of the default team for the project |
| `Description` | string | A description for the Azure DevOps project |

### Optional Parameters

| Parameter | Type | Default | Valid Values | Description |
|-----------|------|---------|--------------|-------------|
| `Process` | string | 'Agile' | 'Agile', 'Scrum', 'CMMI', 'Basic' | The process template to use for the project (only applies during creation) |
| `SourceControl` | string | 'Git' | 'Git', 'Tfvc' | The type of source control to use (only applies during creation) |
| `Visibility` | string | 'Private' | 'Private', 'Public' | The visibility level of the project |
| `Features` | hashtable | See below | See below | A hashtable defining the feature states for the project |
| `RemoveDeployment` | switch | N/A | N/A | If specified, removes the project instead of creating/updating it |

### Default Features Configuration

```powershell
@{
    'Boards'    = 'enabled'
    'Repos'     = 'enabled'
    'Pipelines' = 'enabled'
    'TestPlans' = 'disabled'
    'Artifacts' = 'enabled'
}
```

Valid feature names: `Boards`, `Repos`, `Pipelines`, `TestPlans`, `Artifacts`  
Valid feature states: `enabled`, `disabled`

## Return Values

| Scenario | Return Type | Description |
|----------|-------------|-------------|
| Project created/updated successfully | PSCustomObject | Returns the Azure DevOps project object with all properties and capabilities |
| Project removed successfully | Boolean | Returns `$true` |
| Project doesn't exist (when removing) | Boolean | Returns `$false` |

## Exceptions and Errors

The script uses `$ErrorActionPreference = 'Stop'` and will throw exceptions for:
- Authentication failures to Azure DevOps
- Invalid organization name
- Permission issues
- API communication errors
- Invalid parameter combinations
- Project creation/update failures

## Dependencies

### PowerShell Modules
- **Azure.DevOps.PSModule** - Required for all Azure DevOps operations

### Functions Used
- `Connect-AdoOrganization` - Establishes connection to Azure DevOps
- `Get-AdoContext` - Retrieves current Azure DevOps context
- `Get-AdoProject` - Retrieves project information
- `New-AdoProject` - Creates new projects
- `Set-AdoProject` - Updates project properties
- `Remove-AdoProject` - Deletes projects
- `Get-AdoFeatureState` - Retrieves feature states
- `Set-AdoFeatureState` - Updates feature states
- `Set-AdoTeam` - Updates team properties

## Usage Examples

### Example 1: Create a New Project with Default Settings

```powershell
$paramSplat = @{
    Organization = 'my-org'
    Name         = 'my-project'
    DefaultTeam  = 'my-team'
    Description  = 'My project description'
}

.\src\res\project\main.ps1 @paramSplat
```

This creates a project with:
- Process: Agile (default)
- Source Control: Git (default)
- Visibility: Private (default)
- All features enabled except TestPlans

### Example 2: Create a Scrum Project with Custom Configuration

```powershell
$paramSplat = @{
    Organization  = 'my-org'
    Name          = 'my-webapp-project'
    DefaultTeam   = 'Development Team'
    Description   = 'Web application development project'
    Process       = 'Scrum'
    SourceControl = 'Git'
    Visibility    = 'Private'
    Features      = @{
        'Boards'    = 'enabled'
        'Repos'     = 'enabled'
        'Pipelines' = 'enabled'
        'TestPlans' = 'enabled'
        'Artifacts' = 'enabled'
    }
}

.\src\res\project\main.ps1 @paramSplat
```

### Example 3: Update an Existing Project's Description and Visibility

```powershell
$paramSplat = @{
    Organization = 'my-org'
    Name         = 'existing-project'
    DefaultTeam  = 'Existing Team'
    Description  = 'Updated project description'
    Visibility   = 'Public'
}

.\src\res\project\main.ps1 @paramSplat
```

**Note:** Process and SourceControl cannot be changed for existing projects.

### Example 4: Disable Specific Features

```powershell
$paramSplat = @{
    Organization = 'my-org'
    Name         = 'minimal-project'
    DefaultTeam  = 'Core Team'
    Description  = 'Minimal project with only essential features'
    Features     = @{
        'Boards'    = 'enabled'
        'Repos'     = 'enabled'
        'Pipelines' = 'disabled'
        'TestPlans' = 'disabled'
        'Artifacts' = 'disabled'
    }
}

.\src\res\project\main.ps1 @paramSplat
```

### Example 5: Remove a Project (Destructive Operation)

```powershell
$paramSplat = @{
    Organization     = 'my-org'
    Name             = 'old-project'
    DefaultTeam      = 'N/A'
    Description      = 'N/A'
    RemoveDeployment = $true
}

.\src\res\project\main.ps1 @paramSplat
```

> [!WARNING]
> Using `-RemoveDeployment` will permanently delete the project and all associated resources. This action cannot be undone.

## Script Behavior

### Create Operation
1. Checks if project exists
2. If not exists:
   - Creates new project with specified settings
   - Configures features
   - Sets default team name
3. Returns the created project object

### Update Operation
1. Checks if project exists
2. If exists:
   - Updates description and visibility if changed
   - Updates feature states if different from current
   - Updates default team name if different
3. Returns the updated project object

### Remove Operation
1. Checks if team exists
2. If exists:
   - Removes the team
   - Returns PSCustomObject with `Removed = $true`
3. If not exists:
   - Returns PSCustomObject with `Removed = $false`

## Feature ID Mapping

The script uses internal Azure DevOps feature IDs:

| Feature Name | Azure DevOps Feature ID |
|--------------|-------------------------|
| Boards | `ms.vss-work.agile` |
| Repos | `ms.vss-code.version-control` |
| Pipelines | `ms.vss-build.pipelines` |
| TestPlans | `ms.vss-test-web.test` |
| Artifacts | `ms.azure-artifacts.feature` |

## Notes

- The script uses `CmdletBinding()` and supports common parameters (`-Verbose`, `-Debug`, etc.)
- All operations are logged with `Write-Verbose` for debugging
- The script automatically imports the `Azure.DevOps.PSModule` if not already loaded
- Automatic connection to Azure DevOps organization if not already connected
- Project refresh operations occur after modifications to ensure data consistency

<!-- omit from toc -->
## Version Information

- **Version:** 1.0
- **Author:** Martin Swinkels
- **Company:** MSc365.eu
- **Copyright:** 2025 (c) MSc365.eu, Martin Swinkels
- **License:** [MIT License](https://github.com/msc365/az-devops-governance/blob/main/LICENSE)
- **Project URI:** [az-devops-governance](https://github.com/msc365/az-devops-governance)

