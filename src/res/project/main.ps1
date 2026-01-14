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
    Create, update or rollback an Azure DevOps Project.

.DESCRIPTION
    This script creates, updates or rolls back an Azure DevOps Project within a specified organization.

    It provides options to configure project properties such as description, default team, process template, source control type, visibility, and feature states.

.PARAMETER CollectionUri
    Optional. The collection URI of the Azure DevOps collection/organization, e.g.: `https://dev.azure.com/my-org`, `https://vssps.dev.azure.com/my-org`.

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
    Optional. Switch to indicate if the operation should rollback (soft delete) the project and related resources.
    ⚠️ <b> WARNING! </b>
    Use with caution! Removing a project may affect teams relying on it. See [Notes](#notes) for more information.

.OUTPUTS
    [PSCustomObject]@{
        id            = Project ID
        name          = Project Name
        description   = Project Description
        visibility    = Project Visibility
        defaultTeam   = Default Team Object
        featureStates = Array of Feature State Objects
        resourceType  = Resource Type (Project)
        collectionUri = Collection URI
        status        = Operation Status (Created, Updated, UnChanged, Removed, NotFound, Skipped)
    }

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

    .\deploy.ps1 @rollbackSplat -Rollback -Confirm:$false -Verbose

    Rolls back (removes) the project and related resources without confirmation.

.EXAMPLE
    $paramSplat = @{
        CollectionUri = 'https://dev.azure.com/e2egov-org'
        Name          = 'e2egov-prjHb72x9'
        Description   = 'Default project description'
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

.NOTES
    ## Declarative (DSC-like) Design

    This script follows a declarative, idempotent design pattern similar to Desired State Configuration (DSC).
    Resources are identified by their **Name** (logical identifier), not by system-generated IDs.

    The script automatically determines the required operation based on current state:
    - **Create**: If environment with the specified name doesn't exist
    - **Update**: If environment exists and properties differ from desired state
    - **No Change**: If environment exists and matches desired state
    - **Remove**: If -Rollback switch is specified

    This approach enables true infrastructure-as-code where configuration files define the desired state,
    and the script converges the actual state to match it.
#>
[CmdletBinding(SupportsShouldProcess)]
[OutputType([PSCustomObject])]
param (
    [Parameter()]
    [string]$CollectionUri = $env:DefaultAdoCollectionUri,

    [Parameter(Mandatory)]
    [string]$Name,

    [Parameter()]
    [string]$DefaultTeam,

    [Parameter()]
    [string]$Description,

    [Parameter()]
    [ValidateSet('Agile', 'Scrum', 'CMMI', 'Basic')]
    [string]$Process,

    [Parameter()]
    [ValidateSet('Git', 'Tfvc')]
    [string]$SourceControl,

    [Parameter()]
    [ValidateSet('Private', 'Public')]
    [string]$Visibility,

    [Parameter()]
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
    [switch]$Rollback
)

begin {
    Write-Verbose "[Enter]: .\src\res\project\$($MyInvocation.MyCommand.Name)"

    # Validate required parameters
    if ([string]::IsNullOrWhiteSpace($CollectionUri)) {
        throw "CollectionUri is required. Provide via parameter or use Set-AdoDefault to set '`$env:DefaultAdoCollectionUri'."
    }

    # Validate Azure context
    $currentContext = Get-AzContext
    if ($null -eq $currentContext) {
        throw 'No Azure context found. Please login using Connect-AzAccount.'
    }
    if ($null -eq $currentContext.Subscription) {
        throw 'No active Azure subscription found in current context. Use Set-AzContext to select a subscription.'
    }

    $ctxSplat = @{
        Tenant           = $currentContext.Tenant.Id
        SubscriptionId   = $currentContext.Subscription.Id
        SubscriptionName = $currentContext.Subscription.Name
    }
    Write-Verbose "Context: $($ctxSplat | ConvertTo-Json -Depth 5)"

    # Import required module if not already loaded
    $requiredModule = 'Azure.DevOps.PSModule'

    if (-not (Get-Module -Name $requiredModule)) {
        Import-Module $requiredModule -Force -Verbose:$false -ErrorAction Stop
        Write-Verbose "Module '$requiredModule' imported successfully."
    }
}

process {
    try {
        $ErrorActionPreference = 'Stop'

        #region INITIALIZE

        # Status
        $status = 'Unknown'

        # Variables

        $prj, $set, $get = $null

        # Project
        $prj = Get-AdoProject -Project $Name -WhatIf:$false -ErrorAction SilentlyContinue

        #endregion

        #region DEPLOYMENTS

        if (-not $Rollback.IsPresent) {
            if ($null -eq $prj) {
                if ($PSCmdlet.ShouldProcess($CollectionUri, "Create project: $($Name)")) {
                    $prjSplat = @{
                        Name = $Name
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

                    $prj = New-AdoProject @prjSplat -Confirm:$false -ErrorAction Stop

                    $status = 'Created'
                    Write-Verbose "[CREATE] Project: '$Name' (ID: $($prj.Id))"
                } else {
                    $status = 'Skipped'
                    Write-Verbose "[WHATIF] Call New-AdoProject with parameters: $($prjSplat | ConvertTo-Json -Depth 5)"
                }
            }

            if ($null -ne $prj) {
                # Environment already exists -> check for changes
                $hasChanges = $false
                if ($status -ne 'Created') { $status = 'UnChanged' }

                $prjSplat = @{
                    CollectionUri = $CollectionUri
                    Id            = $prj.Id
                    Name          = $Name
                }

                # Only check description if it was explicitly provided
                if ($PSBoundParameters.ContainsKey('Description')) {

                    # Normalize to empty string for comparison
                    $currentDesc = $prj.Description ?? ''
                    $newDesc = $Description ?? ''

                    if ($newDesc -ne $currentDesc) {
                        $prjSplat['Description'] = $Description
                        $hasChanges = $true
                    }
                }

                # Only check visibility if it was explicitly provided
                if ($PSBoundParameters.ContainsKey('Visibility')) {
                    if ($Visibility -ne $prj.Visibility) {
                        $prjSplat['Visibility'] = $Visibility
                        $hasChanges = $true
                    }
                }

                if ($hasChanges) {
                    if ($PSCmdlet.ShouldProcess($CollectionUri, "Update project: $($Name)")) {
                        Set-AdoProject @prjSplat -Confirm:$false -ErrorAction Stop | Out-Null

                        if ($status -ne 'Created') { $status = 'Updated' }
                        $hasChanges = $false
                        Write-Verbose "[UPDATE] Project: '$Name' (ID: $($prj.Id))"
                    } else {
                        $status = 'Skipped'
                        $hasChanges = $false
                        Write-Verbose "[WHATIF] Call Set-AdoProject with parameters: $($prjSplat | ConvertTo-Json -Depth 5)"
                    }
                }

                # Only check default team if it was explicitly provided
                if ($PSBoundParameters.ContainsKey('DefaultTeam')) {
                    $teamSplat = @{
                        CollectionUri = $CollectionUri
                        ProjectName   = $Name
                        Id            = $prj.DefaultTeam.Id
                    }

                    # Normalize to empty string for comparison
                    $currentDefaultTeam = $prj.DefaultTeam.Name ?? ''
                    $newDefaultTeam = $DefaultTeam ?? ''

                    if ($currentDefaultTeam -ne $newDefaultTeam) {
                        $teamSplat['Name'] = $DefaultTeam
                        $hasChanges = $true
                    }

                    if ($hasChanges) {
                        if ($PSCmdlet.ShouldProcess($Name, "Update default team: $($DefaultTeam)")) {

                            Set-AdoTeam @teamSplat -Confirm:$false -ErrorAction Stop | Out-Null

                            if ($status -ne 'Created') { $status = 'Updated' }
                            $hasChanges = $false
                            Write-Verbose "[UPDATE] DefaultTeam: '$DefaultTeam' (ID: $($prj.DefaultTeam.Id))"
                        } else {
                            $status = 'Skipped'
                            $hasChanges = $false
                            Write-Verbose "[WHATIF] Call Set-AdoTeam with parameters: $($teamSplat | ConvertTo-Json -Depth 5)"
                        }
                    }
                }

                # Only check features if it was explicitly provided
                if ($PSBoundParameters.ContainsKey('Features')) {
                    $featureStatesSplat = @{
                        CollectionUri = $CollectionUri
                        ProjectName   = $Name
                    }

                    # Get current feature states
                    $featureStates = Get-AdoFeatureState @featureStatesSplat -ErrorAction Stop

                    foreach ($fst in $featureStates) {
                        $featureName = $fst.feature
                        $featureState = $fst.state

                        if ($Features.ContainsKey($featureName)) {
                            # Only update if state differs
                            if ($Features[$featureName] -ne $featureState) {
                                if ($PSCmdlet.ShouldProcess($Name, "Update feature state '$($featureName)' to '$($Features[$featureName])'")) {
                                    $featureSplat = @{
                                        CollectionUri = $CollectionUri
                                        ProjectName   = $Name
                                        Feature       = $featureName
                                        FeatureState  = $Features[$featureName]
                                    }

                                    Set-AdoFeatureState @featureSplat -Confirm:$false -ErrorAction Stop | Out-Null

                                    if ($status -ne 'Created') { $status = 'Updated' }
                                    Write-Verbose "[UPDATE] FeatureState: '$featureName' to '$($Features[$featureName])' (ID: $($fst.featureId))"
                                } else {
                                    $status = 'Skipped'
                                    Write-Verbose "[WHATIF] Call Set-AdoFeatureState with parameters: $($featureSplat | ConvertTo-Json -Depth 5)"
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

                $prjSplat = @{
                    CollectionUri = $CollectionUri
                    Id            = $prj.Id
                }

                if ($PSCmdlet.ShouldProcess($CollectionUri, "Remove project: $($Name)")) {
                    Remove-AdoProject @prjSplat -Confirm:$false -ErrorAction Stop

                    $status = 'Removed'
                    Write-Verbose "[REMOVE] Project: '$Name' (ID: $($prj.Id))"
                } else {
                    $status = 'Skipped'
                    Write-Verbose "[WHATIF] Call Remove-AdoProject with parameters: $($prjSplat | ConvertTo-Json -Depth 5)"
                }
            } else {
                $status = 'NotFound'
                Write-Verbose "[NOTFOUND] Project: '$Name' (ID: UNKNOWN)"
            }

            # Return rollback result
            return [PSCustomObject]@{
                id            = if ($prj) { $prj.id } else { $null }
                name          = $Name
                resourceType  = 'Project'
                collectionUri = $CollectionUri
                action        = 'Rollback'
                status        = $status
            }
        }

        #endregion

        #region OUTPUTS

        # Refresh project details after create and update operations
        if ($status -in @('Created', 'Updated')) {
            $prj = Get-AdoProject -CollectionUri $CollectionUri -Name $Name -WhatIf:$false -ErrorAction Stop
        }

        # Always refresh all feature states, because $Features may not have been provided
        $fst = Get-AdoFeatureState -CollectionUri $CollectionUri -ProjectName $Name -WhatIf:$false -ErrorAction Stop

        $obj = [ordered]@{
            id          = if ($prj) { $prj.id } else { $null }
            name        = if ($prj) { $prj.name } else { $null }
            description = if ($prj) { $prj.description } else { $null }
            visibility  = if ($prj) { $prj.visibility } else { $null }
            defaultTeam = if ($prj) { $prj.DefaultTeam } else { $null }
        }
        $obj['featureStates'] = if ($fst) {
            foreach ($fs_ in $fst) {
                [PSCustomObject]@{
                    feature = $fs_.feature
                    state   = $fs_.state
                }
            }
        } else { $null }
        $obj['resourceType'] = 'Project'
        $obj['collectionUri'] = $CollectionUri
        $obj['status'] = $status
        [PSCustomObject]$obj

        #endregion

    } catch {
        throw $_
    }
}

end {
    Write-Verbose "[Exit]: .\$($MyInvocation.MyCommand.Name)"
}
