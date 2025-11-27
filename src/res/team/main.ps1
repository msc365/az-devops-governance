<#PSScriptInfo
    .VERSION 1.0

    .GUID f0c127fe-4f91-4aa8-93ac-cd99447faf0e

    .AUTHOR Martin Swinkels

    .COMPANYNAME MSc365.eu

    .COPYRIGHT 2025 (c) MSc365.eu, Martin Swinkels

    .TAGS 'Azure', 'Security', 'Governance', 'DevOps', 'Platform', 'RBAC'

    .LICENSEURI https://github.com/msc365/az-devops-governance/blob/main/LICENSE

    .PROJECTURI https://github.com/msc365/az-devops-governance

    .ICONURI https://raw.githubusercontent.com/msc365/az-devops-governance/main/.assets/icon.png

    .EXTERNALMODULEDEPENDENCIES Az.Accounts, Azure.DevOps.PSModule
#>
<#
.SYNOPSIS
    Create or update an Azure DevOps Team within a specified project.

.DESCRIPTION
    This script creates or updates an Azure DevOps Team within a specified project. It allows you to set team properties such as name and description.

    If the team already exists, it updates the properties as needed.

.PARAMETER Organization
    Mandatory. The name of the Azure DevOps organization where the project is located.

.PARAMETER ProjectId
    Mandatory. The ID of the Azure DevOps project where the team will be created or updated

.PARAMETER TeamId
    Mandatory. The id or name of the Azure DevOps team to create or update.

.PARAMETER Name
    Optional. The display name of the Azure DevOps team.

.PARAMETER Description
    Optional. A description for the Azure DevOps team.

.PARAMETER Settings
    Optional. A hashtable containing team settings to override the default settings.

.PARAMETER RemoveDeployment
    Optional. If specified, the team will be removed instead of created or updated.

    > [!WARNING]
    > Use with caution! Removing a team is irreversible and may affect team members and their access to project resources.

.EXAMPLE
    $paramSplat = @{
        Organization     = 'my-org'
        ProjectId        = 'my-project'
        TeamId           = 'my-other-team'
        Name             = 'my-other-team-updated'
        Description      = 'My team description'
    }

    ..\src\res\team\main.ps1 @paramSplat -Verbose

    This example creates or updates a team named 'my-team' in the 'my-project' project within the 'my-org' organization, setting its name and description.
#>
[CmdletBinding()]
[OutputType([object])]
param (
    [Parameter(Mandatory)]
    [string]$Organization,

    [Parameter(Mandatory)]
    [string]$ProjectId,

    [Parameter(Mandatory)]
    [string]$TeamId,

    [Parameter()]
    [string]$Name,

    [Parameter()]
    [string]$Description,

    [Parameter()]
    [hashtable]$Settings,

    [Parameter()]
    [switch]$Remove,

    [Parameter()]
    [switch]$Force
)

begin {

    if ($null -eq (Get-AzContext)) {
        Write-Error 'No Azure context found. Please login using Connect-AzAccount.'
        return
    }

    # Import required modules
    $modules = @(
        'Azure.DevOps.PSModule'
    )
    $modules | ForEach-Object {
        if (-not (Get-Module $_) -or (Get-Module $_ -ListAvailable)) {
            Import-Module $_ -Force -Verbose:$false -ErrorAction Stop
        }
    }

    # Connect to Azure DevOps Organization
    if ($null -eq (Get-AdoContext)) {
        Connect-AdoOrganization -Organization $Organization -Verbose:$VerbosePreference
    }
}

process {
    try {
        $ErrorActionPreference = 'Stop'
        $Error.Clear()

        # Initialize variables
        $project, $team, $area = $null

        #region Project

        # Check if project exists
        Write-Verbose ("Checking if project '{0}' exists in organization '{1}'..." -f $ProjectId, $Organization)
        $project = Get-AdoProject -ProjectId $ProjectId -Verbose:$VerbosePreference

        if ($null -eq $project) {
            throw ("Project '{0}' does not exist in organization '{1}'." -f $ProjectId, $Organization)
        } else {
            Write-Verbose ("Project '{0}' exists." -f $project.name)
        }

        #endregion Project

        #region Team Removal

        if ($Remove.IsPresent -and -not $Force.IsPresent) {
            # Prompt user to confirm
            $prompt = @(
                "This script will delete team $($TeamId). All data and related configuration will be lost."
                "Do you want to continue? 'Yes [Y]' 'No [N]'"
            ) -join "`n"

            $result = Read-Host -Prompt $prompt
            $result = $result.ToLower()

            if ($result -ne 'y' -and $result -ne 'yes') {
                Write-Warning "Removing team '$($TeamId)' cancelled by user"
                return
            }
        }

        # Remove team if specified
        if ($Remove.IsPresent) {
            Write-Verbose ("Removing team '{0}' from project '{1}'..." -f $TeamId, $project.name)

            $team = Get-AdoTeam -ProjectId $project.id -TeamId $TeamId -Verbose:$VerbosePreference

            if ($null -ne $team) {
                Remove-AdoTeam -ProjectId $project.id -TeamId $TeamId -Verbose:$VerbosePreference | Out-Null

                Write-Verbose ("Team '{0}' has been removed." -f $TeamId)
                return [pscustomobject]@{
                    Removed = $true
                    Message = 'Team has been removed.'
                }
            }

            Write-Verbose ("Team '{0}' does not exist. No action taken." -f $TeamId)
            return [pscustomobject]@{
                Removed = $false
                Message = 'Team does not exist. No action taken.'
            }
        }

        #endregion Team Removal

        #region Team

        Write-Verbose ("Checking if team '{0}' exists in project '{1}'..." -f $TeamId, $project.name)
        $team = Get-AdoTeam -ProjectId $project.id -TeamId $TeamId -Verbose:$VerbosePreference

        if ($null -eq $team) {
            Write-Verbose ("Team '{0}' does not exist. Creating new team..." -f $TeamId)

            $newSplat = @{
                ProjectId   = $project.id
                Name        = $TeamId
                Description = $Description
            }
            $team = New-AdoTeam @newSplat -Verbose:$VerbosePreference

        } else {
            Write-Verbose ("Team '{0}' exists." -f $TeamId)
            Write-Verbose ("Checking if team '{0}' properties need to be updated..." -f $TeamId)

            if (-not ([System.String]::IsNullOrEmpty($Name) -and $team.name -ne $Name) -or $team.description -ne $Description) {
                Write-Verbose ("Updating team '{0}' properties..." -f $TeamId)

                $updateSplat = @{
                    ProjectId   = $project.id
                    TeamId      = $TeamId
                    Name        = (-not [System.String]::IsNullOrEmpty($Name) ? $Name : $TeamId)
                    Description = $Description
                }

                $team = Set-AdoTeam @updateSplat -Verbose:$VerbosePreference

            } else {
                Write-Verbose ("Team '{0}' is up to date." -f $TeamId)
            }
        }

        #endregion Team

        #region Team Settings

        Write-Verbose ("Getting default team settings for project '{0}'..." -f $project.name)
        $defaultSettings = Get-AdoTeamSettings -ProjectId $project.id -TeamId $project.defaultTeam.id -Verbose:$VerbosePreference

        if ($null -ne $Settings) {
            Write-Verbose ("Overriding default team settings with provided team settings for '{0}'..." -f $team.name)
            foreach ($key in $Settings.Keys) {
                if ($defaultSettings.PSObject.Properties.Name -contains $key) {
                    $defaultSettings.$key = $Settings[$key]
                }
            }
        }

        # Create new object with default team values
        $teamSettings = [TeamSettingsPatch]::new(
            @{
                backlogIteration      = $defaultSettings.backlogIteration.id
                backlogVisibilities   = $defaultSettings.backlogVisibilities
                bugsBehavior          = $defaultSettings.bugsBehavior
                defaultIteration      = $defaultSettings.defaultIteration.id
                defaultIterationMacro = $defaultSettings.defaultIterationMacro
                workingDays           = $defaultSettings.workingDays
            })

        # Convert to hashtable for Set-AdoTeamSettings input
        $settingSplat = $teamSettings.AsHashtable()

        # Remove defaultIteration or defaultIterationMacro to avoid conflicts
        if ($null -ne $settingSplat['defaultIterationMacro']) {
            $settingSplat.Remove('defaultIteration')
        } else {
            $settingSplat.Remove('defaultIterationMacro')
        }

        Write-Verbose ("Applying team settings to team '{0}' in project '{1}'..." -f $team.name, $project.name)
        Set-AdoTeamSettings -ProjectId $project.id -TeamId $team.name -TeamSettings $settingSplat | Out-Null

        #endregion Team Settings

        #region Iteration Paths

        Write-Verbose ("Checking if team '{0}' has iteration paths configured..." -f $team.name)
        $teamIteration = Get-AdoTeamIterationList -ProjectId $project.id -TeamId $team.name -Verbose:$VerbosePreference

        if ($null -eq $teamIteration -or $teamIteration.count -eq 0) {
            Write-Verbose ("No iterations found for team '{0}'. Copy project iterations..." -f $team.name)

            $projectIteration = Get-AdoTeamIterationList -ProjectId $project.id -Verbose:$VerbosePreference

            if ($projectIteration.count -gt 0) {

                $projectIteration.value | ForEach-Object -Process {
                    Write-Verbose ("Adding iteration '{0}' to team '{1}'..." -f $_.path, $team.name)

                    Set-AdoTeamIteration -ProjectId $project.id -TeamId $team.name -IterationId $_.id | Out-Null
                }
            }
        } else {
            Write-Verbose ("Team '{0}' already has iteration paths configured. No changes made." -f $team.name)
        }

        #endregion Iteration Paths

        #region Area Paths

        # Check if project area path exists
        Write-Verbose ("Checking if project area path '{0}\Area\{1}' exists..." -f $project.name, $team.name)
        $rootArea = Get-AdoClassificationNode -ProjectId $project.id -StructureType 'Areas' -Depth 2 -Verbose:$VerbosePreference

        if ($rootArea.hasChildren) {
            $area = $rootArea.Children | Where-Object {
                $_.Name -contains $team.name
            }
        }

        if ($null -eq $area) {
            Write-Verbose ("Project area path '{0}\Area\{1}' does not exist. Creating area path..." -f $project.name, $team.name)

            $area = New-AdoClassificationNode -ProjectId $project.id -Name $team.name -StructureType 'Areas' -Verbose:$VerbosePreference

        } else {
            Write-Verbose ("Project area path '{0}' exists." -f $area.path)
        }

        # Check if team area path exists
        Write-Verbose ("Checking if team area path '{0}\{1}' exists..." -f $project.name, $team.name)
        $fieldValue = Get-AdoTeamFieldValue -ProjectId $project.id -Team $team.id -Verbose:$VerbosePreference

        if ($null -eq $fieldValue.defaultValue) {
            # Set team area path to the team
            Write-Verbose ("Set team area path '{0}\{1}'..." -f $project.name, $team.name)
            $defaultValue = ('{0}\{1}' -f $project.name, $team.name)
            $values = @(
                @{
                    value           = $defaultValue
                    includeChildren = $false
                }
            )
            Set-AdoTeamFieldValue -ProjectId $project.id -Team $team.id -DefaultValue $defaultValue -Values $values -Verbose:$VerbosePreference | Out-Null

        } else {
            Write-Verbose ("Team area path '{0}' exists." -f $fieldValue.defaultValue)
        }

        #endregion Area Paths

        return $team

    } catch {
        throw $_
    }
}

end {
    Write-Debug ('Exit : {0}' -f $MyInvocation.MyCommand.Name)
}
