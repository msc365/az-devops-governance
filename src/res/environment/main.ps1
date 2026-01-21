#Requires -Version 7.0
<#PSScriptInfo
    .VERSION 0.1.0

    .GUID 4adf0e7d-d5cc-4f5a-a1fb-0945e475571a

    .AUTHOR Martin Swinkels

    .COMPANYNAME MSc365.eu

    .COPYRIGHT 2025 (c) MSc365.eu, Martin Swinkels

    .TAGS 'Azure', 'Security', 'Governance', 'DevOps', 'Platform', 'RBAC'

    .LICENSEURI https://github.com/msc365/az-devops-governance/blob/main/LICENSE

    .PROJECTURI https://github.com/msc365/az-devops-governance

    .ICONURI https://raw.githubusercontent.com/msc365/az-devops-governance/main/.assets/icon.png

    .EXTERNALMODULEDEPENDENCIES Az.Accounts, Az.Resources, Azure.DevOps.PSModule
#>
<#
.SYNOPSIS
    Create, update or rollback an Azure DevOps Environment.

.DESCRIPTION
    This PowerShell script creates, updates or rolls back an Azure DevOps Environment.

    It provides comprehensive environment management capabilities including configuration of an optional resource group
    and its properties as a scoped environment.

.PARAMETER CollectionUri
    Optional. The collection URI of the Azure DevOps collection/organization, e.g.: `https://dev.azure.com/my-org`, `https://vssps.dev.azure.com/my-org`.

.PARAMETER ProjectName
    Optional. The Azure DevOps project ID or Name where the environment will be created.

.PARAMETER Name
    Required. The name of the environment to create, update, or remove.

.PARAMETER Description
    Optional. A description for the environment.

.PARAMETER ResourceGroup
    Optional. An optional object defining the resource group properties: `Name`, `Location`, `Tags`. See [Notes](#notes) for more information.

.PARAMETER SubscriptionId
    Optional. The Azure subscription ID where the resource group will be created. Required when ResourceGroup is specified.

.PARAMETER Rollback
    Optional. Switch to indicate if the operation should rollback (remove) the environment and related resources.
    ⚠️ <b> WARNING! </b>
    Use with caution! Removing an environment is irreversible and may affect teams relying on it. See [Notes](#notes) for more information.

.OUTPUTS
    [PSCustomObject]@{
        id             = Environment ID
        name           = Environment Name
        description    = Environment Description
        resourceGroup  = @{
            name       = Resource Group Name
            location   = Resource Group Location
            resourceId = Resource Group Resource ID
        }
        createdBy      = User who created the environment
        createdOn      = Timestamp of environment creation
        lastModifiedBy = User who last modified the environment
        lastModifiedOn = Timestamp of last modification
        resourceType   = Resource Type (Environment)
        projectName    = Azure DevOps Project Name
        collectionUri  = Azure DevOps Collection URI
        status         = Operation Status (Created, Updated, NoChange, Removed, NotFound, Skipped)
    }

.EXAMPLE
    $deploySplat = @{
        TemplateFile          = 'main.ps1'
        TemplateParameterFile = 'params\main.parameters.json'
    }

    .\deploy.ps1 @deploySplat -Verbose

    Deploys the environment using the specified template and parameters.

.EXAMPLE
    $customSplat = @{
        TemplateFile          = 'main.ps1'
        TemplateParameterFile = 'params\custom.parameters.json'
    }

    .\deploy.ps1 @customSplat -Verbose

    Deploys the environment using the specified template and custom parameters.

.EXAMPLE
    $rollbackSplat = @{
        TemplateFile          = 'main.ps1'
        TemplateParameterFile = 'params\main.parameters.json'
    }

    .\deploy.ps1 @rollbackSplat -Rollback -Confirm:$false -Verbose

    Rolls back (removes) the environment and related resources without confirmation.

.EXAMPLE
    $paramSplat = @{
        CollectionUri  = 'https://dev.azure.com/e2egov-org'
        ProjectName    = 'e2egov-prjHb72x9'
        Name           = 'env-e2egov-prjHb72x9-tst'
        Description    = 'Default environment description'
        SubscriptionId = '00000000-0000-0000-0000-000000000000'
        ResourceGroup  = @{
            Name     = 'rg-e2egov-prjHb72x9-tst-weu'
            Location = 'westeurope'
            Tags     = @{ environment = 'tst'; service = 'e2egov' }
        }
    }
    .\main.ps1 @paramSplat -Verbose

    Deploys a new environment including the configuration of an optional resource group
    and its properties as a (least privileged) scoped environment using the specified parameters in code. <br><br>
    See [Service Connection](../service-connection) deployment for creating a service connection with least privileged access to the resource group.

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
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
[OutputType([PSCustomObject])]
param (
    [Parameter()]
    [string]$CollectionUri = $env:DefaultAdoCollectionUri,

    [Parameter()]
    [string]$ProjectName = $env:DefaultAdoProjectName,

    [Parameter(Mandatory)]
    [string]$Name,

    [Parameter()]
    [string]$Description,

    [Parameter()]
    [string]$SubscriptionId,

    [Parameter()]
    [hashtable]$ResourceGroup,

    [Parameter()]
    [switch]$Rollback
)

begin {
    Write-Verbose "[Enter]: .\src\res\environment\$($MyInvocation.MyCommand.Name)"

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
}

process {
    try {
        $ErrorActionPreference = 'Stop'

        #region INITIALIZE

        # Status
        $status = 'Unknown'

        # Variables
        $env, $rg = $null
        $changes = @()

        # Environment - Lookup by Name (DSC-like declarative approach)

        $envSplat = @{
            CollectionUri = $CollectionUri
            ProjectName   = $ProjectName
            Name          = $Name
        }

        $env = Get-AdoEnvironment @envSplat -ErrorAction SilentlyContinue

        if ($PSBoundParameters.ContainsKey('ResourceGroup') -and ($null -ne $ResourceGroup)) {
            # Validate required properties
            $requiredProps = @('name', 'location')

            foreach ($prop in $requiredProps) {
                if (-not $ResourceGroup.ContainsKey($prop) -or
                    [string]::IsNullOrWhiteSpace($ResourceGroup.$prop)) {
                    throw "ResourceGroup parameter is missing required property: '$prop'"
                }
            }

            # Validate SubscriptionId is provided when ResourceGroup is specified
            if ([string]::IsNullOrWhiteSpace($SubscriptionId)) {
                throw 'SubscriptionId parameter is required when ResourceGroup is specified.'
            }

            # Verify tags
            $tags = if ($ResourceGroup.ContainsKey('tags')) { $ResourceGroup.tags } else { $null }

            # Resource Group
            $rgSplat = @{
                Name           = $ResourceGroup.name
                Location       = $ResourceGroup.location
                SubscriptionId = $SubscriptionId
                Tags           = $tags
                Rollback       = $Rollback.IsPresent
                WhatIf         = $WhatIfPreference
                Verbose        = $VerbosePreference
            }

            $rg = & (Join-Path -Path $PSScriptRoot -ChildPath '..\shared\resource-group\main.ps1') @rgSplat -Confirm:$false
        }

        #endregion

        #region PLAN CHANGES

        if ($WhatIfPreference) {
            # Determine what changes will be made
            if (-not $Rollback.IsPresent) {
                # Check Environment changes
                if ($null -eq $env) {
                    $changes += [PSCustomObject]@{
                        ResourceType = 'Azure.DevOps/Environment'
                        ResourceName = $Name
                        Operation    = 'Create'
                        PropertyName = $null
                        OldValue     = $null
                        NewValue     = $null
                    }
                } else {
                    # Check for property changes
                    if ($PSBoundParameters.ContainsKey('Description')) {
                        $currentDesc = $env.Description ?? ''
                        $newDesc = $Description ?? ''

                        if ($newDesc -ne $currentDesc) {
                            $changes += [PSCustomObject]@{
                                ResourceType = 'Azure.DevOps/Environment'
                                ResourceName = $Name
                                Operation    = 'Modify'
                                PropertyName = 'Description'
                                OldValue     = $currentDesc
                                NewValue     = $newDesc
                            }
                        }
                    }
                }

                # Check Resource Group changes
                if ($null -ne $rg) {
                    if ($rg.status -eq 'Created' -or $rg.status -eq 'WouldCreate') {
                        $changes += [PSCustomObject]@{
                            ResourceType = 'Microsoft.Resources/resourceGroups'
                            ResourceName = $ResourceGroup.name
                            Operation    = 'Create'
                            PropertyName = $null
                            OldValue     = $null
                            NewValue     = $null
                        }

                        # Show all tags as being created
                        if ($tags) {
                            foreach ($tagKey in $tags.Keys) {
                                $changes += [PSCustomObject]@{
                                    ResourceType = 'Microsoft.Resources/resourceGroups'
                                    ResourceName = $ResourceGroup.name
                                    Operation    = 'Create'
                                    PropertyName = "Tags.$tagKey"
                                    OldValue     = $null
                                    NewValue     = $tags[$tagKey]
                                }
                            }
                        }
                    } elseif ($rg.status -eq 'Updated' -or $rg.status -eq 'WouldUpdate') {
                        # Analyze tag changes using current state (from $rg) and desired state (from $tags)
                        $currentTags = if ($rg.tags) { $rg.tags } else { @{} }
                        $newTags = if ($tags) { $tags } else { @{} }

                        # Find tags to add (in new but not in current)
                        foreach ($key in $newTags.Keys) {
                            if (-not $currentTags.ContainsKey($key)) {
                                $changes += [PSCustomObject]@{
                                    ResourceType = 'Microsoft.Resources/resourceGroups'
                                    ResourceName = $ResourceGroup.name
                                    Operation    = 'Create'
                                    PropertyName = "Tags.$key"
                                    OldValue     = $null
                                    NewValue     = $newTags[$key]
                                }
                            } elseif ($currentTags[$key] -ne $newTags[$key]) {
                                # Tag exists but value changed
                                $changes += [PSCustomObject]@{
                                    ResourceType = 'Microsoft.Resources/resourceGroups'
                                    ResourceName = $ResourceGroup.name
                                    Operation    = 'Modify'
                                    PropertyName = "Tags.$key"
                                    OldValue     = $currentTags[$key]
                                    NewValue     = $newTags[$key]
                                }
                            }
                        }

                        # Find tags to remove (in current but not in new)
                        foreach ($key in $currentTags.Keys) {
                            if (-not $newTags.ContainsKey($key)) {
                                $changes += [PSCustomObject]@{
                                    ResourceType = 'Microsoft.Resources/resourceGroups'
                                    ResourceName = $ResourceGroup.name
                                    Operation    = 'Delete'
                                    PropertyName = "Tags.$key"
                                    OldValue     = $currentTags[$key]
                                    NewValue     = $null
                                }
                            }
                        }
                    }
                }
            } else {
                # Rollback mode
                if ($null -ne $env) {
                    $changes += [PSCustomObject]@{
                        ResourceType = 'Azure.DevOps/Environment'
                        ResourceName = $Name
                        Operation    = 'Delete'
                        PropertyName = $null
                        OldValue     = $null
                        NewValue     = $null
                    }
                }

                if ($null -ne $rg -and ($rg.status -eq 'Removed' -or $rg.status -eq 'WouldRemove')) {
                    $changes += [PSCustomObject]@{
                        ResourceType = 'Microsoft.Resources/resourceGroups'
                        ResourceName = $ResourceGroup.name
                        Operation    = 'Delete'
                        PropertyName = $null
                        OldValue     = $null
                        NewValue     = $null
                    }
                }
            }

            # Display change summary
            if ($changes.Count -gt 0) {
                Write-Host ''
                Write-Host 'Resource and property changes are indicated with these symbols:'
                Write-Host '  - ' -ForegroundColor DarkRed -NoNewline
                Write-Host 'Delete'
                Write-Host '  + ' -ForegroundColor Green -NoNewline
                Write-Host 'Create'
                Write-Host '  ~ ' -ForegroundColor Magenta -NoNewline
                Write-Host 'Modify'
                Write-Host ''
                Write-Host 'The deployment will update the following scope:'
                Write-Host ''
                Write-Host "Scope: $CollectionUri/$ProjectName"
                Write-Host ''

                $groupedChanges = $changes | Group-Object -Property ResourceType, ResourceName

                foreach ($group in $groupedChanges) {
                    $operation = $group.Group[0].Operation
                    $symbol = switch ($operation) {
                        'Create' { '+' }
                        'Delete' { '-' }
                        'Modify' { '~' }
                    }
                    $color = switch ($operation) {
                        'Create' { 'Green' }
                        'Delete' { 'DarkRed' }
                        'Modify' { 'Magenta' }
                    }

                    Write-Host "  $symbol $($group.Group[0].ResourceType) '$($group.Group[0].ResourceName)'" -ForegroundColor $color

                    # Show property-level changes for Modify operations
                    $propertyChanges = $group.Group | Where-Object { $null -ne $_.PropertyName }
                    if ($propertyChanges) {
                        foreach ($change in $propertyChanges) {

                            $propertyPath = "properties.$($change.PropertyName)"

                            Write-Host "    ~ $propertyPath`:" -ForegroundColor Magenta
                            if ($null -ne $change.OldValue) {
                                Write-Host "      - `"$($change.OldValue)`"" -ForegroundColor DarkRed
                            }
                            if ($null -ne $change.NewValue) {
                                Write-Host "      + `"$($change.NewValue)`"" -ForegroundColor Green
                            }
                        }
                    }
                }

                Write-Host ''

                $createCount = ($changes | Where-Object Operation -EQ 'Create').Count
                $modifyCount = ($changes | Where-Object Operation -EQ 'Modify').Count
                $deleteCount = ($changes | Where-Object Operation -EQ 'Delete').Count

                $summaryParts = @()
                if ($createCount -gt 0) { $summaryParts += "$createCount to create" }
                if ($modifyCount -gt 0) { $summaryParts += "$modifyCount to modify" }
                if ($deleteCount -gt 0) { $summaryParts += "$deleteCount to delete" }

                Write-Host "Resource changes: $($summaryParts -join ', ')."
                Write-Host ''
            } else {
                Write-Host ''
                Write-Host 'No changes detected. All resources match the desired state.'
            }
        }

        #endregion

        #region DEPLOYMENTS

        if (-not $Rollback.IsPresent) {
            # Environment
            if ($null -eq $env) {
                if ($PSCmdlet.ShouldProcess($ProjectName, "Create environment: $($Name)")) {
                    $envSplat = @{
                        CollectionUri = $CollectionUri
                        ProjectName   = $ProjectName
                        Name          = $Name
                        Description   = $Description
                    }

                    $env = New-AdoEnvironment @envSplat -Confirm:$false -ErrorAction Stop

                    $status = 'Created'
                    Write-Verbose "[CREATED] Environment: '$Name' (ID: $($env.Id))"
                } else {
                    $env = [PSCustomObject]@{
                        id          = '<generated>'
                        name        = $Name
                        description = $Description
                    }
                    $status = 'WouldCreate'
                    Write-Verbose "[WHATIF] Call New-AdoEnvironment with parameters: $($envSplat | ConvertTo-Json -Depth 5)"
                }

            } else {
                # Environment already exists -> check for changes
                $hasChanges = $false

                $envSplat = @{
                    CollectionUri = $CollectionUri
                    ProjectName   = $ProjectName
                    Id            = $env.Id
                }

                # Only check description if it was explicitly provided
                if ($PSBoundParameters.ContainsKey('Description')) {

                    # Normalize to empty string for comparison
                    $currentDesc = $env.Description ?? ''
                    $newDesc = $Description ?? ''

                    if ($newDesc -ne $currentDesc) {
                        $envSplat['Description'] = $Description
                        $hasChanges = $true
                    }
                }

                if ($hasChanges) {
                    if ($PSCmdlet.ShouldProcess($ProjectName, "Update environment: $($Name)")) {

                        $env = Set-AdoEnvironment @envSplat -Confirm:$false -ErrorAction Stop

                        $status = 'Updated'
                        Write-Verbose "[UPDATED] Environment: '$Name' (ID: $($env.Id))"
                    } else {
                        $status = 'WouldUpdate'
                        Write-Verbose "[WHATIF] Call Set-AdoEnvironment with parameters: $($envSplat | ConvertTo-Json -Depth 5)"
                    }
                } else {
                    $status = 'NoChange'
                    Write-Verbose "[NOCHANGE] Environment: '$Name' (ID: $($env.Id))"
                }
            }
        }

        #endregion

        #region ROLLBACK

        if ($Rollback.IsPresent) {
            if ($null -ne $env) {
                if ($PSCmdlet.ShouldProcess($ProjectName, "Remove environment: $($Name)")) {
                    $envSplat = @{
                        CollectionUri = $CollectionUri
                        ProjectName   = $ProjectName
                        Id            = $env.Id
                    }

                    Remove-AdoEnvironment @envSplat -Confirm:$false -ErrorAction Stop

                    $status = 'Removed'
                    Write-Verbose "[REMOVED] Environment: '$Name' (ID: $($env.Id))"
                } else {
                    $status = 'WouldRemove'
                    Write-Verbose "[WHATIF] Call Remove-AdoEnvironment with parameters: $($envSplat | ConvertTo-Json -Depth 5)"
                }
            } else {
                $status = 'NotFound'
                $env = [PSCustomObject]@{
                    id   = $null
                    name = $Name
                }
                Write-Verbose "[NOTFOUND] Environment: '$Name' (ID: `$null)"
            }

            # Return rollback result
            return $env | Select-Object -ExcludeProperty collectionUri, projectName -Property *,
            @{ Name = 'projectName'; Expression = { $ProjectName } },
            @{ Name = 'collectionUri'; Expression = { $CollectionUri } },
            @{ Name = 'status'; Expression = { $status } }
        }

        #endregion

        #region OUTPUTS

        # Return deployment result
        $env | Select-Object -ExcludeProperty collectionUri, projectName -Property *,
        @{Name = 'resourceGroup'; Expression = {
                $rg | Select-Object -ExcludeProperty collectionUri, projectName -Property *
            }
        },
        @{Name = 'projectName'; Expression = { $ProjectName } },
        @{Name = 'collectionUri'; Expression = { $CollectionUri } },
        @{Name = 'status'; Expression = { $status } }

        #endregion

    } catch {
        throw $_
    }
}

end {
    Write-Verbose "[Exit]: .\src\res\environment\$($MyInvocation.MyCommand.Name)"
}
