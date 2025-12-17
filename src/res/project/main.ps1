#Requires -Version 7.0
<#PSScriptInfo
    .VERSION 0.1.0

    .GUID cd2e86d4-084a-4af4-bf63-c72f48d029bd

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
    Create, update or delete an Azure DevOps Project with specified settings.

.DESCRIPTION
    This script creates, updates or deletes an Azure DevOps Project within a specified organization.

    It allows you to set project properties such as name, description, process template, source control type, visibility, and feature states.

.PARAMETER Organization
    Required. The name of the Azure DevOps organization where the project will be created or updated.

.PARAMETER Name
    Required. The name of the Azure DevOps project to create, update or delete.

.PARAMETER Description
    Optional. A description for the Azure DevOps project.

.PARAMETER DefaultTeam
    Optional. The name of the default team for the project. Defaults to '\<Project Name> Team'.

.PARAMETER Process
    Optional. The process template to use for the project. Valid values are 'Agile', 'Scrum', 'CMMI', and 'Basic'. Defaults to the organization's default process.

.PARAMETER SourceControl
    Optional. The type of source control to use for the project. Valid values are 'Git' and 'Tfvc'. Defaults to 'Git'.

.PARAMETER Visibility
    Optional. The visibility of the project. Valid values are 'Private' and 'Public'. Defaults to 'Private'.

.PARAMETER Features
    Optional. A hashtable defining the feature states for the project. Valid features are 'boards', 'repos', 'pipelines', 'testPlans', and 'artifacts' with states 'enabled' or 'disabled'.

.PARAMETER Rollback
    Optional. Switch to indicate if the operation should rollback (delete) the project and related resources. <br /> ⚠️ <b> WARNING! </b> <br /> Use with caution! Removing a project may affect teams relying on it. See [Notes](#notes) for more information.

.PARAMETER Force
    Optional. Switch to force deletion without confirmation during rollback.

.EXAMPLE
    $deploySplat = @{
        TemplateFile          = 'main.ps1'
        TemplateParameterFile = 'params\main.parameters.json'
    }

    .\deploy.ps1 @deploySplat -Verbose

    Deploys the project using the specified template and parameters.

.EXAMPLE
    $customSplat = @{
        TemplateFile          = 'main.ps1'
        TemplateParameterFile = 'params\custom.parameters.json'
    }

    .\deploy.ps1 @customSplat -Verbose

    Deploys the project using the specified template and custom parameters.

.EXAMPLE
    $rollbackSplat = @{
        TemplateFile          = 'main.ps1'
        TemplateParameterFile = 'params\main.parameters.json'
    }

    .\deploy.ps1 @rollbackSplat -Rollback -Force -Verbose

    Rolls back (deletes) the project and related resources without confirmation.

.EXAMPLE
    $paramSplat = @{
        Organization  = 'e2egov-org'
        Name          = 'e2egov-prjHb72x9'
        Description   = 'Default e2e governance description'
        DefaultTeam   = 'Default Team'
        SourceControl = 'Git'
        Process       = 'Agile'
        Visibility    = 'Private'
        Features      = @{
            boards    = 'enabled'
            repos     = 'enabled'
            pipelines = 'enabled'
            artifacts = 'enabled'
            testPlans = 'disabled'
        }
    }

    .\src\res\project\main.ps1 @paramSplat

    Deploys or updates a project in the specified Azure DevOps organization using the provided parameters in code.
#>
[CmdletBinding(SupportsShouldProcess)]
[OutputType([pscustomobject])]
param (
    [Parameter(Mandatory)]
    [string]$Organization,

    [Parameter(Mandatory)]
    [string]$Name,

    [Parameter(Mandatory = $false)]
    [string]$DefaultTeam,

    [Parameter(Mandatory = $false)]
    [string]$Description,

    [Parameter(Mandatory = $false)]
    [ValidateSet('Agile', 'Scrum', 'CMMI', 'Basic')]
    [string]$Process,

    [Parameter(Mandatory = $false)]
    [ValidateSet('Git', 'Tfvc')]
    [string]$SourceControl,

    [Parameter(Mandatory = $false)]
    [ValidateSet('Private', 'Public')]
    [string]$Visibility,

    [Parameter(Mandatory = $false)]
    [ValidateScript({
            $validKeys = @('boards', 'repos', 'pipelines', 'artifacts', 'testPlans')
            $validValues = @('enabled', 'disabled')

            foreach ($key in $_.Keys) {
                if ($key -notin $validKeys) {
                    throw "Invalid key: '$key'. Valid keys: $($validKeys -join ', ')"
                }
                if ($_[$key] -notin $validValues) {
                    throw "Invalid value '$key': '$($_[$key])'. Valid values: $($validValues -join ', ')"
                }
            }
            return $true
        })]
    [hashtable]$Features,

    [Parameter()]
    [switch]$Rollback,

    [Parameter()]
    [switch]$Force
)

begin {
    Write-Verbose ('[Enter]: .\src\res\project\{0}' -f $MyInvocation.MyCommand.Name)

    if ($null -eq (Get-AzContext)) {
        throw 'No Azure context found. Please login using Connect-AzAccount.'
    }

    # Define required modules
    $modules = @(
        'Azure.DevOps.PSModule'
    )

    # Import required modules
    $modules | ForEach-Object {
        if (-not (Get-Module -Name $_)) {
            Import-Module $_ -Force -Verbose:$false -ErrorAction Stop
        }
    }

    # Connect to Azure DevOps Organization
    Connect-AdoOrganization -Organization $Organization | Out-Null
}

process {
    try {
        $ErrorActionPreference = 'Stop'
        $Error.Clear()

        #region INITIALIZE

        # Variables

        $prj, $set, $get = $null

        # Project
        $prj = Get-AdoProject -ProjectId $Name -ErrorAction SilentlyContinue

        #endregion

        #region DEPLOYMENTS

        if (-not $Rollback.IsPresent) {
            if ($null -eq $prj) {
                if ($PSCmdlet.ShouldProcess(('{0}' -f $Name), 'Create')) {

                    $prjSplat = @{
                        Name    = $Name
                        Verbose = $VerbosePreference
                    }

                    if ($PSBoundParameters.ContainsKey('Description')) {
                        $prjSplat['Description'] = $Description
                    }
                    if ($PSBoundParameters.ContainsKey('Process')) {
                        $prjSplat['Process'] = $Process
                    }
                    if ($PSBoundParameters.ContainsKey('SourceControl')) {
                        $prjSplat['SourceControl'] = $SourceControl
                    }
                    if ($PSBoundParameters.ContainsKey('Visibility')) {
                        $prjSplat['Visibility'] = $Visibility
                    }

                    $prj = New-AdoProject @prjSplat -ErrorAction Stop
                }
            }

            if ($null -ne $prj) {

                $set = $false
                $prjSplat = @{
                    ProjectId = $prj.Id
                    Verbose   = $VerbosePreference
                }

                if ($PSBoundParameters.ContainsKey('Description') -and ($prj.Description -ne $Description)) {
                    if ($PSCmdlet.ShouldProcess(("Property='Description' Value='{0}...'" -f $Description.Substring(0, [Math]::Min($Description.Length, 16))), 'Update')) {

                        $prjSplat['Description'] = $Description
                        $set = $true
                    }
                }

                if ($PSBoundParameters.ContainsKey('Visibility') -and ($prj.Visibility -ne $Visibility)) {
                    if ($PSCmdlet.ShouldProcess(("Property='Visibility' Value='{0}'" -f $Visibility), 'Update')) {

                        $prjSplat['Visibility'] = $Visibility
                        $set = $true
                    }
                }

                if ($set) {
                    Set-AdoProject @prjSplat -ErrorAction Stop | Out-Null
                    $get = $true
                }

                if ($PSBoundParameters.ContainsKey('DefaultTeam') -and $prj.DefaultTeam.Name -ne $DefaultTeam) {
                    if ($PSCmdlet.ShouldProcess(("Property='DefaultTeam' Value='{0}'" -f $DefaultTeam), 'Update')) {

                        $teamSplat = @{
                            ProjectId = $prj.Id
                            TeamId    = $prj.DefaultTeam.Id
                            Name      = $DefaultTeam
                        }

                        Set-AdoTeam @teamSplat -Verbose:$VerbosePreference | Out-Null
                        $get = $true
                    }
                }

                # Features
                if ($PSBoundParameters.ContainsKey('Features')) {

                    $featureStatesSplat = @{
                        ProjectId = $prj.Id
                    }

                    $featureStates = Get-AdoFeatureState @featureStatesSplat -ErrorAction Stop

                    foreach ($featureId in $featureStates.featureIds) {
                        # Map feature ID to feature name
                        $featureName = switch ($featureId) {
                            'ms.vss-work.agile' { 'boards' }
                            'ms.vss-code.version-control' { 'repos' }
                            'ms.vss-build.pipelines' { 'pipelines' }
                            'ms.vss-test-web.test' { 'testPlans' }
                            'ms.azure-artifacts.feature' { 'artifacts' }
                        }

                        if ($Features.ContainsKey($featureName)) {
                            $featureState = $featureStates.featureStates.$featureId.state

                            # Only update if different
                            if ($Features[$featureName] -ne $featureState) {
                                if ($PSCmdlet.ShouldProcess(("Feature='{0}' Value='{1}'" -f $featureName, $Features[$featureName]), 'Update')) {
                                    $featureSplat = @{
                                        ProjectId    = $prj.Id
                                        Feature      = $featureName
                                        FeatureState = $Features[$featureName]
                                    }

                                    Set-AdoFeatureState @featureSplat -Verbose:$VerbosePreference | Out-Null
                                }
                            }
                        }
                    }
                }
            }
        }

        #endregion

        #region ROLLBACK

        if ($Rollback.IsPresent) {
            if ($null -ne $prj) {
                if ($PSCmdlet.ShouldProcess(('{0}' -f $Name), 'Delete')) {
                    if (-not $Force.IsPresent) {
                        $prompt = @(
                            "This script will delete project '$($Name)'."
                            'All related resources like repositories, pipelines, artifacts and boards will be lost.'
                            "Do you want to continue? 'Yes [Y]' 'No [N]'"
                        ) -join "`n"

                        $result = Read-Host -Prompt $prompt
                        $result = $result.ToLower()

                        if ($result -ne 'y' -and $result -ne 'yes') {
                            Write-Warning 'Operation cancelled by user'
                            return
                        }
                    }

                    # Project
                    $prjSplat = @{
                        ProjectId = $prj.Id
                        Verbose   = $VerbosePreference
                    }

                    Remove-AdoProject @prjSplat -ErrorAction Stop
                    Write-Verbose ("Deleted. '/project/{0}'" -f $Name)
                }
            } else {
                Write-Warning ("Doesn't Exist. '/project/{0}'" -f $Name)
            }

            return
        }

        #end region

        #region OUTPUTS

        if (-not $WhatIfPreference) {
            # Refresh project info if synced
            if ($get) {
                $prj = Get-AdoProject -ProjectId $prj.Id -ErrorAction Stop
            }

            # Get feature states whether updated or not
            $featureStates = Get-AdoFeatureState -ProjectId $prj.Id -ErrorAction Stop

            $output = [pscustomobject]@{
                Project       = ($prj | Select-Object *) ?? $null
                FeatureStates = ($featureStates.FeatureStates | Select-Object *) ?? $null
            }

            return $output
        }

        return $null

        #endregion

    } catch {
        throw $_
    }
}

end {
    Write-Verbose ('[Exit]: .\{0}' -f $MyInvocation.MyCommand.Name)
}
