<!-- cSpell: ignore hashtable msc365 -->
<!-- omit from toc -->
# Azure DevOps Project `[res]`

This PowerShell script (`main.ps1`) creates or updates an Azure DevOps Project within a specified organization. It provides comprehensive project management capabilities including configuration of project properties, feature states, and team settings. The script manages Azure DevOps Projects with the following capabilities:

- Creates new projects with specified configuration
- Updates existing project properties (_description_, _visibility_)
- Configures project feature states (_Boards_, _Repos_, _Pipelines_, _TestPlans_, _Artifacts_)
- Sets default team name (other then default, e.g.: `My-Project Team`)
- Supports project soft delete (with caution)

<!-- omit from toc -->
## Navigation

- [PowerShell modules](#powershell-modules)
- [Usage examples](#usage-examples)
- [Parameters](#parameters)
- [Outputs](#outputs)
- [Notes](#notes)

## PowerShell modules

- **Azure.DevOps.PSModule**  
  Required for all Azure DevOps operations

### Functions used

- `Connect-AdoOrganization` - Establishes connection to Azure DevOps
- `Get-AdoContext` - Retrieves current Azure DevOps context
- `Get-AdoProject` - Retrieves project information
- `New-AdoProject` - Creates new projects
- `Set-AdoProject` - Updates project properties
- `Remove-AdoProject` - Deletes projects
- `Get-AdoFeatureState` - Retrieves feature states
- `Set-AdoFeatureState` - Updates feature states
- `Set-AdoTeam` - Updates team properties

## Usage examples

### Example 1: Create a new project with default settings

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

### Example 2: Create a scrum project with custom configuration

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

### Example 3: Update an existing project's description and visibility

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

> [!NOTE] Note  
> Project `Process` and `SourceControl` cannot be changed for existing projects.

### Example 4: Disable specific features

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

### Example 5: Remove a project (destructive operation)

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
> Using `-Remove` and `-Force` will permanently delete the project and all associated resources. Azure DevOps uses a soft-delete mechanism for projects: when you delete a project, it goes into a "Recently deleted" projects state for 28 days, after which it is permanently removed.

## Parameters

### Required parameters

| Parameter | Type | Description |
| --- | --- | --- |
| `Organization` | string | The name of the Azure DevOps organization where the project will be created or updated |
| `Name` | string | The name of the Azure DevOps project to create or update |
| `DefaultTeam` | string | The name of the default team for the project |
| `Description` | string | A description for the Azure DevOps project |

### Optional parameters

| Parameter | Type | Default | Valid values | Description |
| --- | --- | --- | --- | --- |
| `Process` | string | 'Agile' | 'Agile', 'Scrum', 'CMMI', 'Basic' | The process template to use for the project (only applies during creation) |
| `SourceControl` | string | 'Git' | 'Git', 'Tfvc' | The type of source control to use (only applies during creation) |
| `Visibility` | string | 'Private' | 'Private', 'Public' | The visibility level of the project |
| `Features` | hashtable | See below ¹ | See below ¹ | A hashtable defining the feature states for the project |
| `Remove` | switch |  |  | If specified, removes the project instead of creating/updating it |
| `Force` | switch |  |  | If specified, removes the project without user feedback for automated processes |

¹ Default _Features_ Configuration:

```powershell
@{
    'Boards'    = 'enabled'
    'Repos'     = 'enabled'
    'Pipelines' = 'enabled'
    'TestPlans' = 'disabled'
    'Artifacts' = 'enabled'
}
```

## Outputs

| Scenario | Return Type | Description |
| --- | --- | --- |
| Project created/updated successfully | PSCustomObject | Returns the Azure DevOps project object with all properties and capabilities |
| Project removed successfully | PSCustomObject | Returns object with `Removed = $true` and `Status = Message` |
| Project doesn't exist (when removing) | PSCustomObject | Returns object with `Removed = $false` and `Status = Message` |

## Notes

- The script uses `CmdletBinding()` and supports common parameters (`-Verbose`, `-Debug`, etc.)
- All operations are logged with `Write-Verbose` for debugging
- The script automatically imports the `Azure.DevOps.PSModule` if not already loaded
- Automatic connection to Azure DevOps organization if not already connected
- Project refresh operations occur after modifications to ensure data consistency
