#Requires -Version 7.0
<#PSScriptInfo
    .VERSION 0.1.0

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
    Create, update or rollback an Azure DevOps Team within a specified project.

.DESCRIPTION
    This script creates, updates or rolls back an Azure DevOps Team within a specified project. It allows you to set team properties such as name, description and team settings.

    If the team already exists, it updates the properties and settings as needed.

.PARAMETER ProjectId
    Required. The Azure DevOps project ID or Name where the environment will be created.

.PARAMETER TeamId
    Optional. The ID or Name of the Azure DevOps team to create, update or rollback.

.PARAMETER Description
    Optional. A description for the Azure DevOps team.

.PARAMETER TeamSettings
    Optional. A hashtable containing team settings to override the default settings.

.PARAMETER Rollback
    Optional. Switch to indicate if the operation should rollback (delete) the team and related resources. <br /> ⚠️ <b> WARNING! </b> <br /> Use with caution! Removing a team is irreversible and may affect teams relying on it. See [Notes](#notes) for more information.

.PARAMETER Force
    Optional. Switch to force deletion without confirmation during rollback.

    .EXAMPLE
    $deploySplat = @{
        TemplateFile          = 'main.ps1'
        TemplateParameterFile = 'params\main.parameters.json'
    }

    .\deploy.ps1 @deploySplat -Verbose

    Deploys the team using the specified template and parameters.

.EXAMPLE
    $customSplat = @{
        TemplateFile          = 'main.ps1'
        TemplateParameterFile = 'params\custom.parameters.json'
    }

    .\deploy.ps1 @customSplat -Verbose

    Deploys the team using the specified template and custom parameters.

.EXAMPLE
    $rollbackSplat = @{
        TemplateFile          = 'main.ps1'
        TemplateParameterFile = 'params\main.parameters.json'
    }

    .\deploy.ps1 @rollbackSplat -Rollback -Force -Verbose

    Rolls back (deletes) the team and related resources without confirmation.

.EXAMPLE
    $paramSplat = @{
        ProjectId = 'e2egov-prjHb72x9'
        TeamId = 'Other Team'
        TeamSettings = @{
            BugsBehavior = "asRequirements"
            WorkingDays = @(
                "monday",
                "tuesday",
                "wednesday"
            )
        }
        Description = 'Other Team Description'
    }

    .\src\res\team\main.ps1 @paramSplat -Verbose

    Deploys or updates a team in the specified Azure DevOps project using the provided parameters in code.

.NOTES
    - Requires Azure PowerShell module Az.Accounts and Azure.DevOps.PSModule.
    - Ensure you are logged in to Azure using Connect-AzAccount before running this script.
#>
[CmdletBinding(SupportsShouldProcess)]
[OutputType([PSCustomObject])]
param (
    [Parameter(Mandatory)]
    [string]$ProjectId,

    [Parameter(Mandatory)]
    [string]$TeamId,

    [Parameter(Mandatory = $false)]
    [string]$Description,

    [Parameter(Mandatory = $false)]
    [object]$TeamSettings,

    [Parameter(Mandatory = $false)]
    [object[]]$GroupMembership,

    [Parameter()]
    [switch]$Rollback,

    [Parameter()]
    [switch]$Force
)

begin {
    Write-Verbose "[Enter]: .\src\res\team\$($MyInvocation.MyCommand.Name)"

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
}

process {
    try {
        $ErrorActionPreference = 'Stop'
        $Error.Clear()

        #region INITIALIZE

        # Variables
        $status = 'NoChange'
        $prj, $team, $settings, $area, $set, $get = $null

        # Project
        $prj = Get-AdoProject -ProjectId $ProjectId -ErrorAction SilentlyContinue

        if ($null -eq $prj) {
            throw "NotFound: 'project\$($ProjectId)'"
        }

        # Team
        $team = Get-AdoTeam -ProjectId $prj.Id -TeamId $TeamId -Verbose:$VerbosePreference

        # Root Area path
        $rootAreaSplat = @{
            ProjectId     = $prj.Id
            StructureType = 'Areas'
            Depth         = 2
        }

        $rootArea = Get-AdoClassificationNode @rootAreaSplat -ErrorAction Stop

        if ($rootArea.HasChildren) {
            $area = $rootArea.Children | Where-Object {
                $_.Name -eq $TeamId
            }
        }

        #endregion

        #region DEPLOYMENTS

        if (-not $Rollback.IsPresent) {
            # Team
            if ($null -eq $team) {
                if ($PSCmdlet.ShouldProcess("team\$($TeamId)", 'Create')) {

                    Write-Debug "Creating: team\$($TeamId)"

                    $teamSplat = @{
                        ProjectId = $prj.Id
                        Name      = $TeamId
                        Verbose   = $VerbosePreference
                    }

                    if ($PSBoundParameters.ContainsKey('Description')) {
                        $teamSplat['Description'] = $Description
                    }

                    $team = New-AdoTeam @teamSplat -ErrorAction Stop
                    $status = 'Succeeded'

                    Write-Verbose ("Created: 'team\$($TeamId)'")
                }
            } else {
                Write-Verbose "NoChange: team\$($team.Name)"
            }

            if ($null -ne $team) {
                $set = $false

                $teamSplat = @{
                    ProjectId = $prj.Id
                    TeamId    = $team.Id
                    Name      = $team.Name
                    Verbose   = $VerbosePreference
                }

                if ($PSBoundParameters.ContainsKey('Description') -and ($team.Description -ne $Description)) {
                    if ($PSCmdlet.ShouldProcess("team\Description\$($Description)", 'Update')) {

                        $teamSplat['Description'] = $Description
                        $set = $true
                    }
                }

                if ($set) {
                    Write-Debug "Updating: team\$($team.Name)"

                    Set-AdoTeam @teamSplat -ErrorAction Stop | Out-Null
                    $get = $true
                    $status = 'Succeeded'

                    Write-Verbose "Updated: team\$($team.Name)"
                }

                # Team settings
                $settingsSplat = @{
                    Project      = $prj
                    Team         = $team
                    TeamSettings = $TeamSettings ?? @{}
                    WhatIf       = $WhatIfPreference
                    Verbose      = $VerbosePreference
                }

                $settings = & (Join-Path -Path $PSScriptRoot -ChildPath 'modules\nested_teamSettings.ps1') @settingsSplat

                if ($null -ne $settings -and $settings.Status -eq 'Succeeded') {
                    $status = 'Succeeded'
                    $get = $true
                }

                # Iteration Paths
                $ipsSplat = @{
                    Project = $prj
                    Team    = $team
                    WhatIf  = $WhatIfPreference
                    Verbose = $VerbosePreference
                }

                & (Join-Path -Path $PSScriptRoot -ChildPath 'modules\nested_iterationPaths.ps1') @ipsSplat | Out-Null

                # Root Area path
                if ($null -eq $area) {
                    if ($PSCmdlet.ShouldProcess("project\areaPath\$($team.Name)", 'Create')) {

                        Write-Debug "Creating: project\areaPath\$($team.Name)"

                        $areaSplat = @{
                            ProjectId     = $prj.Id
                            Name          = $team.Name
                            StructureType = 'Areas'
                            Verbose       = $VerbosePreference
                        }

                        $area = New-AdoClassificationNode @areaSplat -ErrorAction Stop

                        Write-Verbose "Created: project\areaPath\$($area.Name)"
                    }
                } else {
                    Write-Verbose "NoChange: project\areaPath\$($area.Name)"
                }

                # Team Area path
                $apsSplat = @{
                    Project = $prj
                    Team    = $team
                    WhatIf  = $WhatIfPreference
                    Verbose = $VerbosePreference
                }

                & (Join-Path -Path $PSScriptRoot -ChildPath 'modules\nested_areaPaths.ps1') @apsSplat | Out-Null
            }
        }

        #endregion

        #region ROLLBACK

        if ($Rollback.IsPresent) {
            # Project area path
            if ($null -ne $area) {
                if ($PSCmdlet.ShouldProcess("project\areaPath\$($area.Name)", 'Remove')) {
                    if (-not $Force.IsPresent) {
                        $prompt = @(
                            "This script will delete area path '$($area.Name)' and all of its children."
                            'This action cannot be undone and the area path cannot be restored.'
                            "Do you want to continue? 'Yes [Y]' 'No [N]'"
                        ) -join "`n"

                        $result = Read-Host -Prompt $prompt
                        $result = $result.ToLower()

                        if ($result -ne 'y' -and $result -ne 'yes') {
                            Write-Warning 'Operation cancelled by user'
                            return
                        }
                    }

                    Write-Debug "Removing: 'project\areaPath\$($area.Name)\ReclassifyId\$($rootArea.Id)'"

                    $areaSplat = @{
                        ProjectId     = $prj.Id
                        StructureType = 'Areas'
                        Path          = $area.Name
                        ReclassifyId  = $rootArea.Id
                        Verbose       = $VerbosePreference
                    }

                    Remove-AdoClassificationNode @areaSplat -ErrorAction Stop | Out-Null
                    $status = 'Removed'

                    Write-Verbose "Removed: 'project\areaPath\$($area.Name)\ReclassifyId\$($rootArea.Id)'"
                }
            } else {
                $status = 'NotFound'
                Write-Warning "NotFound: 'project\areaPath\$($TeamId)'"
            }

            # Team
            if ($null -ne $team) {
                if ($PSCmdlet.ShouldProcess("team\$($team.Name)", 'Remove')) {
                    if (-not $Force.IsPresent) {
                        $prompt = @(
                            "This script will delete team '$($team.Name)'."
                            'All related resources like dashboards, backlogs and boards will be lost.'
                            "Do you want to continue? 'Yes [Y]' 'No [N]'"
                        ) -join "`n"

                        $result = Read-Host -Prompt $prompt
                        $result = $result.ToLower()

                        if ($result -ne 'y' -and $result -ne 'yes') {
                            Write-Warning 'Operation cancelled by user'
                            return
                        }
                    }

                    Write-Debug "Removing: 'team\$($team.Name)'"

                    $teamSplat = @{
                        ProjectId = $prj.Id
                        TeamId    = $team.Id
                        Verbose   = $VerbosePreference
                    }

                    Remove-AdoTeam @teamSplat | Out-Null
                    $status = 'Removed'

                    Write-Verbose "Removed: 'team\$($team.Name)'"
                }
            } else {
                $status = 'NotFound'
                Write-Warning "NotFound: 'team\$($TeamId)'"
            }

            if (-not $WhatIfPreference -and $status -ne 'NotFound') {
                $output = [PSCustomObject]@{
                    ProjectId = $prj.Id
                    TeamId    = $team.Id ?? $TeamId
                    Status    = $status
                }

                return $output
            }

            return
        }

        #endregion

        #region OUTPUTS

        if (-not $WhatIfPreference) {
            if ($get) {
                $team = Get-AdoTeam -ProjectId $prj.Id -TeamId $team.Id -ErrorAction Stop
            }

            $output = [PSCustomObject]@{
                ProjectId = $prj.Id
                TeamId    = $team.Id
                Team      = ($team | Select-Object -Property *)
                Status    = $status
            }

            return $output
        }

        #endregion

        return

    } catch {
        throw $_
    }
}

end {
    Write-Verbose "[Exit]: .\src\res\team\$($MyInvocation.MyCommand.Name)"
}
