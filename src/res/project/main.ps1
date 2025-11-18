<#PSScriptInfo
    .VERSION 1.0

    .GUID cd2e86d4-084a-4af4-bf63-c72f48d029bd

    .AUTHOR Martin Swinkels

    .COMPANYNAME MSc365.eu

    .COPYRIGHT 2025 (c) MSc365.eu, Martin Swinkels

    .TAGS 'Azure', 'Security', 'Governance', 'DevOps', 'Platform', 'RBAC'

    .LICENSEURI https://github.com/msc365/az-devops-governance/blob/main/LICENSE

    .PROJECTURI https://github.com/msc365/az-devops-governance

    .ICONURI https://raw.githubusercontent.com/msc365/az-devops-governance/main/.assets/icon.png

    .EXTERNALMODULEDEPENDENCIES Az.Accounts
#>
<#
.SYNOPSIS
    Create or update an Azure DevOps Project with specified settings.

.DESCRIPTION
    This script creates or updates an Azure DevOps Project within a specified organization. It allows you to set project properties such as name, description, process template, source control type, visibility, and feature states.

    If the project already exists, it updates the properties and feature states as needed.

    Warning: The process template and source control type can only be set during project creation.

.PARAMETER Organization
    Mandatory. The name of the Azure DevOps organization where the project will be created or updated.

.PARAMETER Name
    Mandatory. The name of the Azure DevOps project to create or update.

.PARAMETER Description
    Mandatory. A description for the Azure DevOps project.

.PARAMETER DefaultTeam
    Mandatory. The name of the default team for the project.

.PARAMETER Process
    Mandatory. The process template to use for the project. Valid values are 'Agile', 'Scrum', 'CMMI', and 'Basic'.

.PARAMETER SourceControl
    Mandatory. The type of source control to use for the project. Valid values are 'Git' and 'Tfvc'.

.PARAMETER Visibility
    Mandatory. The visibility of the project. Valid values are 'Private' and 'Public'.

.PARAMETER Features
    Mandatory. A hashtable defining the feature states for the project. Valid features are 'Boards', 'Repos', 'Pipelines', 'TestPlans', and 'Artifacts' with states 'enabled' or 'disabled'.

.PARAMETER RemoveDeployment
    Optional. If specified, the project will be removed instead of created or updated.

    > [!WARNING]
    > Use with caution! If the project is removed, all associated resources will also be deleted.

.EXAMPLE
    $paramSplat = @{
        Organization     = 'my-org'
        ProjectName      = 'my-project'
        DefaultTeamName  = 'my-team'
        Description      = 'My project description'
        Process          = 'Agile'
        SourceControl    = 'Git'
        Visibility       = 'Private'
        Features         = @{
            'Boards'    = 'enabled'
            'Repos'     = 'enabled'
            'Pipelines' = 'enabled'
            'TestPlans' = 'disabled'
            'Artifacts' = 'enabled'
        }
    }

    .\src\res\project\main.ps1 @paramSplat

    This example deploys or updates a project named 'my-project' in the 'my-org' organization with the specified parameters.
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$Organization,

    [Parameter(Mandatory = $true)]
    [string]$Name,

    [Parameter(Mandatory = $true)]
    [string]$DefaultTeam,

    [Parameter(Mandatory = $true)]
    [string]$Description,

    [Parameter(Mandatory = $false)]
    [ValidateSet('Agile', 'Scrum', 'CMMI', 'Basic')]
    [string]$Process = 'Agile',

    [Parameter(Mandatory = $false)]
    [ValidateSet('Git', 'Tfvc')]
    [string]$SourceControl = 'Git',

    [Parameter(Mandatory = $false)]
    [ValidateSet('Private', 'Public')]
    [string]$Visibility = 'Private',

    [Parameter(Mandatory = $false)]
    [hashtable]$Features = @{
        'Boards'    = 'enabled'
        'Repos'     = 'enabled'
        'Pipelines' = 'enabled'
        'TestPlans' = 'disabled'
        'Artifacts' = 'enabled'
    },

    [Parameter()]
    [switch]$RemoveDeployment
)

begin {
    # Import required modules
    $modules = @(
        'Azure.DevOps.PSModule'
    )
    $modules | ForEach-Object {
        if (-not (Get-Module $_ -ListAvailable)) {
            Import-Module $_ -Force -Verbose:$false
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
        $project = $null
        $refreshProject = $false

        if ($RemoveDeployment.IsPresent) {
            Write-Verbose ("Removing project '{0}' from organization '{1}'..." -f $Name, $Organization)

            $project = Get-AdoProject -ProjectId $Name -Verbose:$VerbosePreference

            if ($null -ne $project) {
                Remove-AdoProject -ProjectId $project.Id -Verbose:$VerbosePreference | Out-Null

                Write-Verbose ("Project '{0}' has been removed." -f $Name)
                return $true
            }

            Write-Verbose ("Project '{0}' does not exist. No action taken." -f $Name)
            return $false
        }

        # Check if project exists
        Write-Verbose ("Checking if project '{0}' exists in organization '{1}'..." -f $Name, $Organization)
        $project = Get-AdoProject -ProjectId $Name -IncludeCapabilities -Verbose:$VerbosePreference

        if ($null -eq $project) {
            # Create new project
            Write-Verbose ("Project '{0}' does not exist. Creating new project..." -f $Name)

            $newSplat = @{
                Name          = $Name
                Description   = $Description
                Process       = $Process
                SourceControl = $SourceControl
                Visibility    = $Visibility
            }
            $project = New-AdoProject @newSplat -Verbose:$VerbosePreference

            $refreshProject = $true
        } else {
            # Update existing project
            Write-Verbose ("Project '{0}' exists." -f $Name)

            if ($project.Description -ne $Description -or $project.Visibility -ne $Visibility) {
                Write-Verbose ("Updating project '{0}' properties..." -f $Name)

                $updateSplat = @{
                    ProjectId   = $project.Id
                    Description = $Description
                    Visibility  = $Visibility
                }
                Set-AdoProject @updateSplat -Verbose:$VerbosePreference | Out-Null

                $refreshProject = $true
            }
        }

        if ($refreshProject) {
            Write-Verbose ("Refreshing project '{0}' data..." -f $Name)

            $project = $null
            $project = Get-AdoProject -ProjectId $Name -IncludeCapabilities -Verbose:$VerbosePreference

            $refreshProject = $false
        }

        # Update project feature states
        $currentFeatureStates = Get-AdoFeatureState -ProjectId $project.Id -Verbose:$VerbosePreference

        foreach ($currentFeatureId in $currentFeatureStates.featureIds) {
            # Map feature ID to feature name
            $featureId = switch ($currentFeatureId) {
                'ms.vss-work.agile' { 'Boards' }
                'ms.vss-code.version-control' { 'Repos' }
                'ms.vss-build.pipelines' { 'Pipelines' }
                'ms.vss-test-web.test' { 'TestPlans' }
                'ms.azure-artifacts.feature' { 'Artifacts' }
            }

            if ($Features.ContainsKey($featureId)) {
                $currentFeatureState = $currentFeatureStates.featureStates.$currentFeatureId.state

                # Compare and only update if different
                if ($Features[$featureId] -ne $currentFeatureState) {
                    $featureSplat = @{
                        ProjectId    = $project.id
                        Feature      = $featureId
                        FeatureState = $Features[$featureId]
                    }
                    Write-Verbose ("Updating feature '{0}' to state '{1}'..." -f $featureId, $Features[$featureId])
                    Set-AdoFeatureState @featureSplat -Verbose:$VerbosePreference | Out-Null

                    $refreshProject = $true
                }
            }
        }

        # Set default team name if different
        if ($project.defaultTeam.name -ne $DefaultTeam) {
            $defaultTeamSplat = @{
                ProjectId = $project.Id
                TeamId    = $project.DefaultTeam.Id
                Name      = $DefaultTeam
            }

            Write-Verbose ("Updating default team name for project to '{0}'..." -f $DefaultTeam)
            Set-AdoTeam @defaultTeamSplat -Verbose:$VerbosePreference | Out-Null

            $refreshProject = $true
        }

        # Final refresh if needed
        if ($refreshProject) {
            Write-Verbose ("Getting updated project '{0}' data..." -f $Name)

            $project = $null
            $project = Get-AdoProject -ProjectId $Name -IncludeCapabilities -Verbose:$VerbosePreference
        } else {
            Write-Verbose ("Project '{0}' is up to date." -f $Name)
        }

        return $project

    } catch {
        throw $_
    }
}

end {
    Write-Debug ('Exit : {0}' -f $MyInvocation.MyCommand.Name)
}
