#Requires -Version 7.0
<#PSScriptInfo
    .VERSION 0.1.0

    .GUID f516b5a3-35db-416c-a86f-10fa326cb692

    .AUTHOR Martin Swinkels

    .COMPANYNAME MSc365.eu

    .COPYRIGHT 2025 (c) MSc365.eu, Martin Swinkels

    .TAGS 'Azure', 'Security', 'Governance', 'DevOps', 'Platform', 'RBAC'

    .LICENSEURI https://github.com/msc365/az-devops-governance/blob/main/LICENSE

    .PROJECTURI https://github.com/msc365/az-devops-governance

    .ICONURI https://raw.githubusercontent.com/msc365/az-devops-governance/main/.assets/icon.png

    .EXTERNALMODULEDEPENDENCIES Az.Accounts, Az.Resources, Az.ManagedServiceIdentity, Azure.DevOps.PSModule
#>
<#
.SYNOPSIS
    Deploys an Azure DevOps Service Connection with Managed Service Identity and Role Assignment.

.DESCRIPTION
    This script deploys an Azure DevOps Service Connection using a Managed Service Identity (MSI) for authentication.
    It also creates the necessary role assignments for the MSI to access Azure resources aka _Azure DevOps Workload Identity Federation_.

.PARAMETER CollectionUri
    Optional. The collection URI of the Azure DevOps collection/organization, e.g.: `https://dev.azure.com/my-org`, `https://vssps.dev.azure.com/my-org`.

.PARAMETER ProjectName
    Optional. The Azure DevOps project ID or Name where the environment will be created.

.PARAMETER Name
    Required. The name of the service connection to be created.

.PARAMETER Description
    Optional. A description for the service connection.

.PARAMETER Scope
    Required. The scope for the service connection (e.g.: /subscriptions/00000000-0000-0000-0000-000000000000).

.PARAMETER ManagedServiceIdentity
    Required. An object containing details of the Managed Service Identity to be used. The object should contain: `name`, `resourceGroupName`, `subscriptionId`, `location`, `tags`, and `roleAssignments` (an array of role assignment definitions). See [Example 4](#example-4) for more information.

.PARAMETER Rollback
    Optional. Switch to indicate if the operation should rollback (remove) the environment and related resources.
    ⚠️ <b> WARNING! </b>
    Use with caution! Removing an environment is irreversible and may affect teams relying on it. See [Notes](#notes) for more information.

.EXAMPLE
    $deploySplat = @{
        TemplateFile          = 'main.ps1'
        TemplateParameterFile = 'params\main.parameters.json'
    }

    .\deploy.ps1 @deploySplat -Verbose

    Deploys the service connection using the specified template and parameters.

.EXAMPLE
    $customSplat = @{
        TemplateFile          = 'main.ps1'
        TemplateParameterFile = 'params\custom.parameters.json'
    }

    .\deploy.ps1 @customSplat -Verbose

    Deploys the service connection using the specified template and custom parameters.

    .EXAMPLE

    $rollbackSplat = @{
        TemplateFile          = 'main.ps1'
        TemplateParameterFile = 'params\main.parameters.json'
    }

    .\deploy.ps1 @rollbackSplat -Rollback -Force -Verbose

    Rolls back (deletes) the service connection and related resources without confirmation.

.EXAMPLE
    $paramSplat = @{
        CollectionUri          = 'https://dev.azure.com/e2egov-org'
        ProjectName            = 'e2egov-prjHb72x9'
        Name                   = 'rg-e2egov-prjHb72x9-tst-weu'
        Description            = 'Service Connection for e2egov-prjHb72x9 testing in West Europe'
        Scope                  = '/subscriptions/00000000-0000-0000-0000-000000000000'
        ManagedServiceIdentity = @{
            name               = 'id-e2egov-prjHb72x9-tst'
            resourceGroupName  = 'rg-e2egov-prjHb72x9-tst-weu'
            subscriptionId     = '00000000-0000-0000-0000-000000000000'
            location           = 'westeurope'
            tags               = @{ 'environment' = 'tst'; 'owner' = 'e2egov' }
            roleAssignments     = @(
                @{
                    roleDefinitionName = 'Reader'
                    scope              = '/subscriptions/00000000-0000-0000-0000-000000000000'
                },
                @{
                    roleDefinitionName = 'Contributor'
                    scope              = '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-my-project'
                }
            )
        }
    }

    .\main.ps1 @paramSplat -Verbose

    Deploys a service connection using the specified parameters in code.
#>
[CmdletBinding(SupportsShouldProcess)]
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

    [Parameter(Mandatory)]
    [string]$Scope,

    [Parameter(Mandatory)]
    [object]$ManagedServiceIdentity,

    [Parameter()]
    [switch]$Rollback
)

begin {
    Write-Verbose "[Enter]: .\src\res\service-connection\$($MyInvocation.MyCommand.Name)"

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

        $RESOURCE_TYPE = 'ServiceEndpoint'

        #region INITIALIZE

        # Status
        $status = 'Unknown'

        # Variables
        $prj, $dep, $se, $fic, $sync, $ras = $null

        # Project
        $prj = Get-AdoProject -Project $ProjectName -Verbose:$false -ErrorAction SilentlyContinue

        # Dependencies
        $depSplat = @{
            IdentityName      = $ManagedServiceIdentity.name
            ResourceGroupName = $ManagedServiceIdentity.resourceGroupName
            SubscriptionId    = $ManagedServiceIdentity.subscriptionId
            Location          = $ManagedServiceIdentity.location
            Tags              = $ManagedServiceIdentity.tags
            Rollback          = $Rollback.IsPresent
            WhatIf            = $WhatIfPreference
            Verbose           = $VerbosePreference
        }

        $dep = & (Join-Path -Path $PSScriptRoot -ChildPath 'modules\dependencies.ps1') @depSplat

        # Service Endpoint
        $seSplat = @{
            ProjectName = $ProjectName
            Names       = $Name
        }

        $se = Get-AdoServiceEndpoint @seSplat -Verbose:$false -ErrorAction SilentlyContinue

        # Federated Credential
        $ficName = "fic-$($Name.Substring(3))"

        $ficSplat = @{
            Name              = $ficName
            IdentityName      = $ManagedServiceIdentity.name
            ResourceGroupName = $ManagedServiceIdentity.resourceGroupName
            SubscriptionId    = $ManagedServiceIdentity.subscriptionId
        }

        $fic = Get-AzFederatedIdentityCredential @ficSplat -Verbose:$false -ErrorAction SilentlyContinue

        # Role Assignments
        if ($dep.principalId) {
            $rasSplat = @{
                ObjectId        = $dep.principalId
                RoleAssignments = $ManagedServiceIdentity.roleAssignments
                Rollback        = $Rollback.IsPresent
                WhatIf          = $WhatIfPreference
                Verbose         = $VerbosePreference
            }

            $ras = & (Join-Path -Path $PSScriptRoot -ChildPath '..\shared\role-assignment\main.ps1') @rasSplat
        } else {
            $ras = @()
        }

        #endregion

        #region DEPLOYMENTS

        if (-not $Rollback.IsPresent) {
            # Service Endpoint
            if ($null -eq $se) {
                # Get Subscription details
                $subSplat = @{
                    SubscriptionId = ($Scope -split '/')[2]
                    TenantId       = $dep.tenantId
                }

                $sub = Get-AzSubscription @subSplat -Verbose:$false -ErrorAction Stop

                # Prepare Service Endpoint configuration
                $data = [Ordered]@{
                    creationMode     = 'Manual'
                    environment      = 'AzureCloud'
                    scopeLevel       = 'Subscription'
                    subscriptionId   = $sub.SubscriptionId
                    subscriptionName = $sub.Name
                }

                $sepConfig = [Ordered]@{
                    data                             = $data
                    name                             = $Name
                    description                      = $Description
                    type                             = 'AzureRM'
                    url                              = 'https://management.azure.com/'
                    authorization                    = [Ordered]@{
                        parameters = [Ordered]@{
                            serviceprincipalid = $dep.clientId
                            tenantid           = $dep.tenantId
                            scope              = $Scope
                        }
                        scheme     = 'WorkloadIdentityFederation'
                    }
                    isShared                         = $false
                    isReady                          = $true
                    serviceEndpointProjectReferences = @(
                        [Ordered]@{
                            name             = $Name
                            projectReference = [Ordered]@{
                                id   = $prj.Id
                                name = $prj.Name
                            }
                        }
                    )
                }

                $seSplat = @{
                    Configuration = $sepConfig
                }

                if ($PSCmdlet.ShouldProcess($ProjectName, "Create service endpoint: $($Name)")) {

                    $se = New-AdoServiceEndpoint @seSplat -Confirm:$false -Verbose:$false -ErrorAction Stop

                    $status = 'Created'
                    Write-Verbose "[CREATE] Service endpoint: '$Name' (ID: $($se.Id))"
                } else {
                    $status = 'Skipped'
                    Write-Verbose "[WHATIF] Call New-AdoServiceEndpoint with parameters: $($seSplat | ConvertTo-Json -Depth 5)"
                }
            } else {
                $status = 'NoChange'
                Write-Verbose "[NOCHANGE] Service endpoint: '$($se.Name)' (ID: $($se.Id))"
            }

            # Federated Credential
            if ($null -eq $fic) {
                if ($PSCmdlet.ShouldProcess($Name, "Create federated identity credential: $($ficName)")) {
                    if ($null -eq $se) {
                        throw "Service endpoint '$($Name)' not found! Cannot create 'Federated Identity Credential'."
                    }

                    $ficSplat += @{
                        Issuer  = $se.Authorization.Parameters.WorkloadIdentityFederationIssuer
                        Subject = $se.Authorization.Parameters.WorkloadIdentityFederationSubject
                    }

                    $fic = New-AzFederatedIdentityCredential @ficSplat -Verbose:$false -ErrorAction Stop

                    # $status = 'Created'
                    Write-Verbose "[CREATE] Federated identity credential: '$($fic.Name)' (ID: $($fic.Id))"
                } else {
                    # $status = 'Skipped'
                    Write-Verbose "[WHATIF] Call New-AzFederatedIdentityCredential with parameters: $($ficSplat | ConvertTo-Json -Depth 5)"
                }

            } else {
                # $status = 'NoChange'
                Write-Verbose "[NOCHANGE] Federated identity credential: '$($fic.Name)' (ID: $($fic.Id))"

                # if ($null -ne $se) {
                #     if ($fic.Issuer -ne $se.Authorization.Parameters.WorkloadIdentityFederationIssuer -or
                #         $fic.Subject -ne $se.Authorization.Parameters.WorkloadIdentityFederationSubject) {

                #         $ficSplat += @{
                #             Issuer  = $se.Authorization.Parameters.WorkloadIdentityFederationIssuer
                #             Subject = $se.Authorization.Parameters.WorkloadIdentityFederationSubject
                #         }

                #         if ($PSCmdlet.ShouldProcess($Name, "Update federated identity credential: $($ficName)")) {

                #             $fic = Update-AzFederatedIdentityCredential @ficSplat -Verbose:$false -ErrorAction Stop

                #             # $status = 'Updated'
                #             Write-Verbose "[UPDATE] Federated identity credential: '$($fic.Name)' (ID: $($fic.Id))"
                #         } else {
                #             # $status = 'Skipped'
                #             Write-Verbose "[WHATIF] Call Update-AzFederatedIdentityCredential with parameters: $($ficSplat | ConvertTo-Json -Depth 5)"
                #         }
                #     } else {
                #         # $status = 'NoChange'
                #         Write-Verbose "[NOCHANGE] Federated identity credential: '$($fic.Name)' (ID: $($fic.Id))"
                #     }
                # }
            }
        }

        #endregion

        #region ROLLBACK

        if ($Rollback.IsPresent) {
            # Service Endpoint
            if ($null -ne $se) {
                if ($PSCmdlet.ShouldProcess($ProjectName, "Remove service endpoint: $($Name)")) {

                    $seSplat = @{
                        Id         = $se.Id
                        ProjectIds = $prj.Id
                    }

                    $maxAttempts = 3; $waitSeconds = 15; $attempt = 0; $success = $false

                    while ($attempt -lt $maxAttempts -and -not $success) {
                        $attempt++

                        try {
                            Write-Verbose "Removing service endpoint: '$($se.Name)', attempt '$($attempt)' of '$($maxAttempts)'..."

                            Remove-AdoServiceEndpoint @seSplat -Confirm:$false -Verbose:$false | Out-Null

                            $success = $true
                            $status = 'Removed'
                            Write-Verbose "[REMOVE] Service endpoint: '$($se.Name)' (ID: $($se.Id))"
                        } catch {
                            Write-Warning "Attempt '$($attempt) of $($maxAttempts)' failed: $($_.Exception.Message)"

                            if ($attempt -lt $maxAttempts) {
                                Write-Information "Retrying in $($waitSeconds) seconds..." -InformationAction Continue
                                Start-Sleep -Seconds $waitSeconds
                            } else {
                                throw $_
                            }
                        }
                    }
                } else {
                    $status = 'Skipped'
                    Write-Verbose "[WHATIF] Call Remove-AdoServiceEndpoint with parameters: $($seSplat | ConvertTo-Json -Depth 5)"
                }
            } else {
                $status = 'NotFound'
                Write-Warning "[NOTFOUND] Service endpoint: '$($Name)' (ID: UNKNOWN)"
            }

            # Return rollback result
            return [PSCustomObject]@{
                id            = if ($se) { $se.id } else { $null }
                name          = $Name
                resourceType  = $RESOURCE_TYPE
                projectName   = $ProjectName
                collectionUri = $CollectionUri
                action        = 'Rollback'
                status        = $status
            }
        }

        #endregion

        #region OUTPUTS

        $obj = [ordered]@{
            serviceEndpoint = if ($se) {
                [PSCustomObject]@{
                    id                               = $se.id
                    name                             = $se.name
                    type                             = $se.type
                    description                      = $se.description
                    authorization                    = $se.authorization
                    isShared                         = $se.isShared
                    url                              = $se.url
                    isReady                          = $se.isReady
                    owner                            = $se.owner
                    data                             = $se.data
                    serviceEndpointProjectReferences = $se.serviceEndpointProjectReferences
                    projectName                      = $projectName
                    collectionUri                    = $CollectionUri
                }
            } else { $null }
            identity        = if ($dep) {
                [PSCustomObject]@{
                    id                = $dep.id
                    name              = $dep.name
                    clientId          = $dep.clientId
                    principalId       = $dep.principalId
                    tenantId          = $dep.tenantId
                    resourceGroupName = $dep.resourceGroupName
                    type              = $dep.type
                }
            } else { $null }
            credential      = if ($fic) {
                [PSCustomObject]@{
                    id        = $fic.id
                    name      = $fic.name
                    issuer    = $fic.issuer
                    subject   = $fic.subject
                    audiences = $fic.audiences
                }
            } else { $null }
            roleAssignments = if ($ras -and $ras.Count -gt 0) {
                $ras | ForEach-Object {
                    [PSCustomObject]@{
                        objectId           = $_.objectId
                        displayName        = $_.displayName
                        roleDefinitionName = $_.roleDefinitionName
                        principalId        = $_.principalId
                        principalType      = $_.principalType
                        scope              = $_.scope
                        status             = $_.status
                    }
                }
            } else { $null }
            resourceType    = $RESOURCE_TYPE
            projectName     = $ProjectName
            collectionUri   = $CollectionUri
            status          = $status
        }
        [PSCustomObject]$obj

        #endregion

    } catch {
        throw $_
    }
}

end {
    Write-Verbose "[Exit]: .\src\res\service-connection\$($MyInvocation.MyCommand.Name)"
}
