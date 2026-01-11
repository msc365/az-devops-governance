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
    Optional. The collection URI of the Azure DevOps collection/organization, e.g. : `https://dev.azure.com/my-org`, `https://vssps.dev.azure.com/my-org`.

.PARAMETER ProjectName
    Optional. The Azure DevOps project ID or Name where the environment will be created.

.PARAMETER Name
    Required. The name of the environment to create, update, or remove.

.PARAMETER Description
    Optional. A description for the environment.

.PARAMETER ResourceGroup
    Optional. An optional object defining the resource group properties: `Name`, `Location`, `SubscriptionId`, `Tags`. See [Notes](#notes) for more information.

.PARAMETER Rollback
    Optional. Switch to indicate if the operation should rollback (remove) the environment and related resources. <br /> ⚠️ <b> WARNING! </b> <br /> Use with caution! Removing an environment is irreversible and may affect teams relying on it. See [Notes](#notes) for more information.

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
        projectName    = Azure DevOps Project Name
        collectionUri  = Azure DevOps Collection URI
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
        CollectionUri = 'https://dev.azure.com/e2egov-org'
        ProjectName   = 'e2egov-prjHb72x9'
        Name          = 'env-e2egov-prjHb72x9-tst'
        Description   = 'Default environment description'
        ResourceGroup = @{
            Name           = 'rg-e2egov-prjHb72x9-tst-weu'
            Location       = 'westeurope'
            SubscriptionId = '00000000-0000-0000-0000-000000000000'
            Tags           = @{ environment = 'tst'; service = 'e2egov' }
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
        $env, $ctx, $sub, $rg = $null

        # Environment - Lookup by Name (DSC-like declarative approach)
        $envSplat = @{
            CollectionUri = $CollectionUri
            ProjectName   = $ProjectName
            Name          = $Name
        }

        $env = Get-AdoEnvironment @envSplat -ErrorAction SilentlyContinue

        if ($PSBoundParameters.ContainsKey('ResourceGroup') -and ($null -ne $ResourceGroup)) {
            # Validate required properties
            $requiredProps = @('name', 'location', 'subscriptionId')

            foreach ($prop in $requiredProps) {
                if (-not $ResourceGroup.ContainsKey($prop) -or
                    [string]::IsNullOrWhiteSpace($ResourceGroup.$prop)) {
                    throw "ResourceGroup parameter is missing required property: '$prop'"
                }
            }

            # Validate subscription ID format
            if ($ResourceGroup.subscriptionId -notmatch '^[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}$') {
                throw "Invalid subscription ID format: '$($ResourceGroup.subscriptionId)'"
            }

            # Switch context if needed
            $ctx = Get-AzContext -ErrorAction Stop

            if ($ctx.Subscription.Id -ne $ResourceGroup.subscriptionId) {
                $subSplat = @{
                    TenantId       = $ctx.Tenant.Id
                    SubscriptionId = $ResourceGroup.subscriptionId
                    WhatIf         = $false
                }
                $sub = Set-AzContext @subSplat -ErrorAction Stop

                # Verify the context switch was successful
                $currentCtx = Get-AzContext
                if ($currentCtx.Subscription.Id -ne $ResourceGroup.subscriptionId) {
                    throw "Failed to switch to subscription '$($ResourceGroup.subscriptionId)'"
                }

                Write-Verbose "Switched to subscription: $($ResourceGroup.subscriptionId)"
            }

            # Resource Group
            $rgSplat = @{
                Name     = $ResourceGroup.name
                Location = $ResourceGroup.location
                Rollback = $Rollback.IsPresent
                WhatIf   = $WhatIfPreference
                Verbose  = $VerbosePreference
            }

            # Only add tags if they exist and are not empty
            if ($ResourceGroup.ContainsKey('tags') -and $ResourceGroup.tags -and $ResourceGroup.tags.Count -gt 0) {
                $rgSplat['Tags'] = $ResourceGroup.tags
            }
            $rg = & (Join-Path -Path $PSScriptRoot -ChildPath '..\shared\resource-group\main.ps1') @rgSplat -Confirm:$false
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
                    Write-Verbose "[CREATE] Environment: '$Name' (ID: $($env.Id))"
                } else {
                    $status = 'Skipped'
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
                        Write-Verbose "[UPDATE] Environment: '$Name' (ID: $($env.Id))"
                    } else {
                        $status = 'Skipped'
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
                    Write-Verbose "[REMOVE] Environment: '$Name' (ID: $($env.Id))"
                } else {
                    $status = 'Skipped'
                    Write-Verbose "[WHATIF] Call Remove-AdoEnvironment with parameters: $($envSplat | ConvertTo-Json -Depth 5)"
                }
            } else {
                $status = 'NotFound'
                Write-Verbose "[NOTFOUND] Environment: '$Name' (ID: UNKNOWN)"
            }

            # Return rollback result
            return [PSCustomObject]@{
                id      = if ($env) { $env.id } else { $null }
                name    = $Name
                project = $ProjectName
                action  = 'Rollback'
                status  = $status
            }
        }

        #endregion

        #region OUTPUTS

        $obj = [ordered]@{
            id          = if ($env) { $env.id } else { $null }
            name        = if ($env) { $env.name } else { $Name }
            description = if ($env) { $env.description } else { $Description }
        }
        if ($rg) {
            $obj['resourceGroup'] = [ordered]@{
                name       = $rg.ResourceGroupName
                location   = $rg.Location
                resourceId = $rg.ResourceId
            }
        }
        if ($env -and $env.createdBy) {
            $obj['createdBy'] = $env.createdBy
            $obj['createdOn'] = $env.createdOn
        }
        if ($env -and $env.lastModifiedBy) {
            $obj['lastModifiedBy'] = $env.lastModifiedBy
            $obj['lastModifiedOn'] = $env.lastModifiedOn
        }
        $obj['projectName'] = $ProjectName
        $obj['collectionUri'] = $CollectionUri
        $obj['status'] = $status
        [PSCustomObject]$obj

        #endregion

    } catch {
        throw $_
    }

    finally {
        if ($null -ne $ctx -and $null -ne $sub -and
            $ctx.Subscription.Id -ne $rg.SubscriptionId) {

            try {
                $ctxSplat = @{
                    TenantId       = $ctx.Tenant.Id
                    SubscriptionId = $ctx.Subscription.Id
                    WhatIf         = $false
                }
                $restored = Set-AzContext @ctxSplat -ErrorAction Stop
                Write-Verbose "Restored original subscription context: $($restored.Subscription.Id)"
            } catch {
                Write-Warning "Failed to restore original Azure context: $_"
                Write-Warning "Current context may be set to subscription: $($sub.Subscription.Id)"
            }
        }
    }
}

end {
    Write-Verbose "[Exit]: .\src\res\environment\$($MyInvocation.MyCommand.Name)"
}
