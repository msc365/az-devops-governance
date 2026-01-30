#Requires -Version 7.0
<#PSScriptInfo
    .VERSION 0.1.0

    .GUID c05d4d33-60e1-4463-ae4d-9efd41278002

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
    Manage an Azure DevOps team within a project.

.DESCRIPTION
    This script creates, updates, or removes an Azure DevOps team within a specified project,
    including configuration of team settings, iteration paths, and area paths.

.PARAMETER CollectionUri
    Optional. The collection URI of the Azure DevOps collection/organization, e.g., `https://dev.azure.com/my-org`.

.PARAMETER ProjectName
    Optional. The Azure DevOps project ID or Name where the team will be managed.

.PARAMETER TeamName
    Mandatory. The name of the Azure DevOps team to manage.

.PARAMETER Description
    Optional. The description of the Azure DevOps team.

.PARAMETER TeamSettings
    Optional. A hashtable or PSCustomObject containing team settings to configure.

.PARAMETER Rollback
    Optional. Switch to indicate if the operation should rollback (remove) the specified team.

.OUTPUTS
    [PSCustomObject]@{
        id            = Team ID
        name          = Team Name
        description   = Team Description
        teamSettings  = Configured Team Settings
        projectName   = Azure DevOps Project Name
        collectionUri = Azure DevOps Collection URI
        status        = Operation Status (Created, Updated, Added, NoChange, Removed, NotFound)
    }

.EXAMPLE
    $deploySplat = @{
        TemplateFile          = 'main.ps1'
        TemplateParameterFile = 'params/main.parameters.json'
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
        TemplateParameterFile = 'params/main.parameters.json'
    }

    .\deploy.ps1 @rollbackSplat -Rollback -Confirm:$false -Verbose

    Rolls back (removes) the team and related resources without confirmation.

.EXAMPLE
    $params = @{
        CollectionUri = 'https://dev.azure.com/my-org'
        ProjectName   = 'e2egov-prjHb72x9'
        TeamName      = 'Another Team'
        Description   = 'Another team description'
        TeamSettings  = @{
            backlogVisibilities   = @{
                'Microsoft.EpicCategory'        = false
                'Microsoft.FeatureCategory'     = true
                'Microsoft.RequirementCategory' = true
            }
            bugsBehavior          = 'asRequirements'
            defaultIterationMacro = '@currentIteration'
            workingDays           = @(
                'monday'
                'tuesday'
                'wednesday'
                'thursday'
                'friday'
            )
        }
    }
    .\main.ps1 @params

    Creates or updates the specified team within the given project.
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
[OutputType([PSCustomObject])]
param (
    [Parameter()]
    [string]$CollectionUri = $env:DefaultAdoCollectionUri,

    [Parameter()]
    [string]$ProjectName = $env:DefaultAdoProjectName,

    [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
    [string]$TeamName,

    [Parameter(ValueFromPipelineByPropertyName)]
    [string]$Description,

    [Parameter(ValueFromPipelineByPropertyName)]
    [object]$TeamSettings,

    [Parameter()]
    [switch]$Rollback
)

begin {
    Write-Verbose ("[Enter]: ./rsc/team/$($MyInvocation.MyCommand.Name)")

    # Validate required parameters
    if ([string]::IsNullOrWhiteSpace($CollectionUri)) {
        throw "CollectionUri is required. Provide via parameter or use Set-AdoDefault to set '`$env:DefaultAdoCollectionUri'."
    }

    if ([string]::IsNullOrWhiteSpace($ProjectName)) {
        throw "ProjectName is required. Provide via parameter or use Set-AdoDefault to set '`$env:DefaultAdoProjectName'."
    }

    # Validate Azure context
    $currentContext = Get-AzContext
    if ($null -eq $currentContext) {
        throw 'No Azure context found. Please login using Connect-AzAccount.'
    }

    # Import required module if not already loaded
    $requiredModule = 'Azure.DevOps.PSModule'

    if (-not (Get-Module -Name $requiredModule)) {
        Import-Module $requiredModule -Force -Verbose:$false -ErrorAction Stop
        Write-Verbose "Module '$requiredModule' imported successfully."
    }

    # Project
    $prjSplat = [ordered]@{
        CollectionUri = $CollectionUri
        ProjectName   = $ProjectName
    }

    $prj = Get-AdoProject @prjSplat -Verbose:$false -ErrorAction SilentlyContinue

    if ($null -eq $prj) {
        throw "Project with ID $ProjectName does not exist, cannot proceed."
    }
}

process {
    try {
        $ErrorActionPreference = 'Stop'

        #region INITIALIZE

        # Status
        $status = 'Unknown'

        # Variables
        $tm = $null

        # Team
        $tmSplat = [ordered]@{
            CollectionUri = $CollectionUri
            ProjectName   = $ProjectName
            TeamName      = $TeamName
        }
        $tm = Get-AdoTeam @tmSplat -Verbose:$false

        #endregion

        #region DEPLOYMENTS

        if (-not $Rollback.IsPresent) {
            if ($null -eq $tm) {
                # Team does not exist, create it

                if ($PSBoundParameters.ContainsKey('Description')) {
                    $tmSplat['Description'] = $Description
                }

                if ($PSCmdlet.ShouldProcess($ProjectName, "Create team: $($TeamName)")) {

                    $tm = New-AdoTeam @tmSplat -Confirm:$false -Verbose:$false

                    $status = 'Created'
                    Write-Verbose "[CREATED]: Team '$TeamName' (ID: $($tm.Id))"
                } else {
                    $status = 'WouldCreate'
                    $tmSplat['teamSettings'] = $TeamSettings
                    Write-Verbose "[WHATIF]: Call New-AdoTeam with parameters: $($tmSplat | ConvertTo-Json -Depth 5)"
                }
            }

            if ($null -ne $tm) {
                # Team exists, check for description changes
                $hasChanges = $false

                $tmSplat = [ordered]@{
                    CollectionUri = $CollectionUri
                    ProjectName   = $ProjectName
                    TeamName      = $TeamName
                }

                # Only check description if it was explicitly provided
                if ($PSBoundParameters.ContainsKey('Description')) {
                    # Normalize to empty string for comparison
                    $currentDesc = $tm.Description ?? ''
                    $newDesc = $Description ?? ''

                    if ($newDesc -ne $currentDesc) {
                        $tmSplat['Description'] = $Description
                        $hasChanges = $true
                    }
                }

                if ($hasChanges) {
                    if ($PSCmdlet.ShouldProcess($TeamName, 'Update team description')) {

                        $tm = Set-AdoTeam @tmSplat -Id $tm.id -Confirm:$false -Verbose:$false

                        $status = 'Updated'
                        Write-Verbose "[UPDATED]: Team description '$TeamName' (ID: $($tm.Id))"
                    } else {
                        $status = 'WouldUpdate'
                        Write-Verbose "[WHATIF]: Call Set-AdoTeam with parameters: $($tmSplat | ConvertTo-Json -Depth 5)"
                    }
                } else {
                    # Only set NoChange if status is not already 'Created'
                    if ($status -ne 'Created') {
                        $status = 'NoChange'
                    }
                    Write-Verbose "[NOCHANGE]: Team '$TeamName' (ID: $($tm.Id))"
                }

                # Team settings, iteration paths, area paths
                $tmsSplat = [ordered]@{
                    CollectionUri = $CollectionUri
                    Project       = $prj
                    Team          = $tm
                    Verbose       = $VerbosePreference
                    WhatIf        = $WhatIfPreference
                    Confirm       = $false
                }

                # Team settings
                if ($PSBoundParameters.ContainsKey('TeamSettings')) {
                    $tmsSplat['TeamSettings'] = $TeamSettings
                }

                $tms = & (Join-Path -Path $PSScriptRoot -ChildPath 'modules\nested_teamSettings.ps1') @tmsSplat
                $tmsSplat.Remove('TeamSettings')

                # Team iteration paths
                & (Join-Path -Path $PSScriptRoot -ChildPath 'modules\nested_iterationPaths.ps1') @tmsSplat | Out-Null

                # Team area paths
                & (Join-Path -Path $PSScriptRoot -ChildPath 'modules\nested_areaPaths.ps1') @tmsSplat | Out-Null
            }
        }

        #endregion

        #region ROLLBACK

        if ($Rollback.IsPresent) {
            if ($null -ne $tm) {
                $tmSplat = [ordered]@{
                    CollectionUri = $CollectionUri
                    ProjectName   = $ProjectName
                    TeamName      = $TeamName
                }

                if ($PSCmdlet.ShouldProcess($ProjectName, "Remove team: $($TeamName)")) {

                    Remove-AdoTeam @tmSplat -Confirm:$false -ErrorAction Stop

                    $status = 'Removed'
                    Write-Verbose "[REMOVED]: Team '$TeamName' (ID: $($tm.Id))"
                } else {
                    $status = 'WouldRemove'
                    Write-Verbose "[WHATIF]: Call Remove-AdoTeam with parameters: $($tmSplat | ConvertTo-Json -Depth 5)"
                }
            } else {
                $status = 'NotFound'
                $tm = [PSCustomObject]@{
                    id   = $null
                    name = $TeamName
                }
                Write-Verbose "[NOTFOUND]: Team '$TeamName' (ID: `$null)"
            }

            # Return rollback result; rebuild object
            return $tm | Select-Object -ExcludeProperty collectionUri, projectName -Property *,
            @{ Name = 'projectName'; Expression = { $ProjectName } },
            @{ Name = 'collectionUri'; Expression = { $CollectionUri } },
            @{ Name = 'status'; Expression = { $status } }
        }

        #endregion

        #region OUTPUTS

        $tm | Select-Object -ExcludeProperty collectionUri, projectName, teamSettings -Property *,
        @{ Name = 'teamSettings'; Expression = { $tms ?? $TeamSettings } },
        @{ Name = 'projectName'; Expression = { $ProjectName } },
        @{ Name = 'collectionUri'; Expression = { $CollectionUri } },
        @{ Name = 'status'; Expression = { $status } }

        #endregion

    } catch {
        throw $_
    }
}

end {
    Write-Verbose ("[Exit]: ./rsc/team/$($MyInvocation.MyCommand.Name)")
}
