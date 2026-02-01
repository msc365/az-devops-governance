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

    .EXTERNALMODULEDEPENDENCIES Az.Accounts, Az.ManagedServiceIdentity, Azure.DevOps.PSModule
#>
<#
.SYNOPSIS
    Deploys an Azure DevOps service connection.

.DESCRIPTION
    This script deploys an Azure DevOps service connection for a managed identity, including the creation of a federated identity credential.

.PARAMETER CollectionUri
    Optional. The collection URI of the Azure DevOps collection/organization, e.g.: `https://dev.azure.com/my-org`, `https://vssps.dev.azure.com/my-org`.

.PARAMETER ProjectName
    Optional. The Azure DevOps project ID or Name where the service connection will be created.

.PARAMETER Name
    Required. The name of the service connection to be created.

.PARAMETER Description
    Optional. A description for the service connection.

.PARAMETER ManagedIdentity
    Required. An object containing details of the Managed Identity to be used. The object should contain: `name`, `resourceGroupName`, `subscriptionId`, and `federatedIdentityCredential` (an object with the `name` property). See [Example 4](#example-4) for more information.

.PARAMETER Rollback
    Optional. Switch to indicate if the operation should rollback (remove) the service connection and related resources.
    ⚠️ WARNING: Use with caution! Removing a service connection is irreversible and may affect teams relying on it.

.OUTPUTS
    [PSCustomObject]@{
        id                               = Service endpoint ID
        name                             = Service endpoint name
        type                             = Type of service endpoint (e.g., AzureRM)
        description                      = Service endpoint description
        authorization                    = Authorization details
        url                              = URL of the service endpoint
        isShared                         = Indicates if the service endpoint is shared
        isReady                          = Indicates if the service endpoint is ready
        owner                            = Owner of the service endpoint
        data                             = Additional data related to the service endpoint
        serviceEndpointProjectReferences = Project references for the service endpoint
        projectName                      = Name of the project
        collectionUri                    = URI of the collection
        status                           = Status of the service endpoint deployment
    }

.EXAMPLE
    $deploySplat = @{
        TemplateFile          = 'main.ps1'
        TemplateParameterFile = 'params/main.parameters.json'
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
        TemplateParameterFile = 'params/main.parameters.json'
    }

    .\deploy.ps1 @rollbackSplat -Rollback -Force -Verbose

    Rolls back (deletes) the service connection and related resources without confirmation.

.EXAMPLE
    $paramSplat = @{
        CollectionUri          = 'https://dev.azure.com/e2egov-org'
        ProjectName            = 'e2egov-prjHb72x9'
        Name                   = 'rg-e2egov-prjHb72x9-tst-weu'
        Description            = 'Service Connection for e2egov-prjHb72x9 testing in West Europe'
        ManagedIdentity = @{
            Name                         = 'id-e2egov-prjHb72x9-tst'
            ResourceGroupName            = 'rg-e2egov-prjHb72x9-tst-weu'
            SubscriptionId               = '00000000-0000-0000-0000-000000000000'
            FederatedIdentityCredential  = @{
                Name = 'fic-e2egov-prjHb72x9-tst'
            }
        }
    }

    .\main.ps1 @paramSplat -Verbose

    Deploys a service connection using the specified parameters in code.
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
[OutputType([PSCustomObject])]
param (
    [Parameter()]
    [string]$CollectionUri = $env:DefaultAdoCollectionUri,

    [Parameter()]
    [string]$ProjectName = $env:DefaultAdoProjectName,

    [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
    [string]$Name,

    [Parameter(ValueFromPipelineByPropertyName)]
    [string]$Description,

    [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
    [object]$ManagedIdentity,

    [Parameter()]
    [switch]$Rollback
)

begin {
    Write-Verbose "[Enter]: ./src/res/connection/$($MyInvocation.MyCommand.Name)"

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
        $prj, $msi, $fic, $sep = $null

        # Project
        $prjSplat = [ordered]@{
            CollectionUri = $CollectionUri
            Project       = $ProjectName
        }
        $prj = Get-AdoProject @prjSplat -Verbose:$false -ErrorAction SilentlyContinue

        if ($null -eq $prj) {
            throw "Project with ID $ProjectName does not exist, cannot proceed."
        }

        # Managed service identity
        $msiSplat = [ordered]@{
            Name              = $ManagedIdentity.name
            ResourceGroupName = $ManagedIdentity.resourceGroupName
            SubscriptionId    = $ManagedIdentity.subscriptionId
        }
        $msi = Get-AzUserAssignedIdentity @msiSplat -Verbose:$false -ErrorAction SilentlyContinue

        # Federated identity credential
        $ficSplat = [ordered]@{
            Name              = $ManagedIdentity.federatedIdentityCredential.name
            IdentityName      = $ManagedIdentity.name
            ResourceGroupName = $ManagedIdentity.resourceGroupName
            SubscriptionId    = $ManagedIdentity.subscriptionId
        }
        $fic = Get-AzFederatedIdentityCredential @ficSplat -Verbose:$false -ErrorAction SilentlyContinue

        # Service endpoint
        $sepSplat = [ordered]@{
            CollectionUri = $CollectionUri
            ProjectName   = $ProjectName
            Names         = $Name
        }
        $sep = Get-AdoServiceEndpoint @sepSplat -Verbose:$false -ErrorAction SilentlyContinue

        #endregion

        #region DEPLOYMENTS

        if (-not $Rollback.IsPresent) {
            # Service endpoint
            if ($null -eq $sep) {
                # Get Subscription details
                if ($msi) {
                    $subSplat = @{
                        TenantId       = $msi.tenantId
                        SubscriptionId = $ManagedIdentity.subscriptionId
                    }
                    $sub = Get-AzSubscription @subSplat -Verbose:$false -ErrorAction Stop
                } else {
                    $sub = [PSCustomObject]@{
                        Name           = '<unknown>'
                        SubscriptionId = $ManagedIdentity.subscriptionId
                    }
                }

                # Prepare Service Endpoint configuration
                $data = [Ordered]@{
                    creationMode     = 'Manual'
                    environment      = 'AzureCloud'
                    scopeLevel       = 'Subscription'
                    subscriptionId   = $sub.subscriptionId
                    subscriptionName = $sub.name
                }

                $sepConfig = [Ordered]@{
                    data                             = $data
                    name                             = $Name
                    description                      = $Description
                    type                             = 'AzureRM'
                    url                              = 'https://management.azure.com/'
                    authorization                    = [Ordered]@{
                        parameters = [Ordered]@{
                            serviceprincipalid = if ($msi) { $msi.clientId } else { '<generated>' }
                            tenantid           = if ($msi) { $msi.tenantId } else { '<generated>' }
                            scope              = "/subscriptions/$($sub.subscriptionId)"
                        }
                        scheme     = 'WorkloadIdentityFederation'
                    }
                    isShared                         = $false
                    isReady                          = $true
                    serviceEndpointProjectReferences = @(
                        [Ordered]@{
                            name             = $Name
                            projectReference = [Ordered]@{
                                id   = $prj.id
                                name = $prj.name
                            }
                        }
                    )
                }

                $sepSplat = [ordered]@{
                    CollectionUri = $CollectionUri
                    Configuration = $sepConfig
                }

                if ($PSCmdlet.ShouldProcess($ProjectName, "Create service endpoint: $($Name)")) {

                    if ($null -eq $msi) {
                        throw "Managed identity '$($ManagedIdentity.name)' not found in resource group '$($ManagedIdentity.resourceGroupName)'. Cannot create service endpoint."
                    }

                    $sep = New-AdoServiceEndpoint @sepSplat -Confirm:$false -Verbose:$false

                    $status = 'Created'
                    Write-Verbose "[CREATED]: Service endpoint '$Name' (ID: $($sep.Id))"
                } else {
                    $status = 'WouldCreate'
                    Write-Verbose "[WHATIF]: Call New-AdoServiceEndpoint with parameters: $($sepSplat | ConvertTo-Json -Depth 5)"
                }
            } else {
                $status = 'NoChange'
                Write-Verbose "[NOCHANGE]: Service endpoint '$($sep.Name)' (ID: $($sep.Id))"
            }

            # Federated Credential
            if ($null -eq $fic) {
                if ($PSCmdlet.ShouldProcess($Name, "Create federated identity credential: $($ManagedIdentity.federatedIdentityCredential.name)")) {
                    if ($null -eq $sep) {
                        throw "Service endpoint '$($Name)' not found! Cannot create 'Federated Identity Credential'."
                    }

                    $ficSplat['Issuer'] = $sep.Authorization.Parameters.WorkloadIdentityFederationIssuer
                    $ficSplat['Subject'] = $sep.Authorization.Parameters.WorkloadIdentityFederationSubject

                    $fic = New-AzFederatedIdentityCredential @ficSplat -Confirm:$false -Verbose:$false

                    # $status = 'Created'
                    Write-Verbose "[CREATED]: Federated identity credential '$($fic.Name)' (ID: $($fic.Id))"
                } else {
                    # $status = 'Skipped'
                    Write-Verbose "[WHATIF]: Call New-AzFederatedIdentityCredential with parameters: $($ficSplat | ConvertTo-Json -Depth 5)"
                }

            } else {
                # $status = 'NoChange'
                Write-Verbose "[NOCHANGE]: Federated identity credential '$($fic.Name)' (ID: $($fic.Id))"
            }
        }

        #endregion

        #region ROLLBACK

        if ($Rollback.IsPresent) {
            # Federated identity credential
            if ($null -ne $fic) {
                if ($PSCmdlet.ShouldProcess($Name, "Remove federated identity credential: $($ManagedIdentity.federatedIdentityCredential.name)")) {
                    $ficSplat = [ordered]@{
                        CollectionUri     = $CollectionUri
                        ProjectName       = $ProjectName
                        Name              = $ManagedIdentity.federatedIdentityCredential.name
                        IdentityName      = $ManagedIdentity.name
                        ResourceGroupName = $ManagedIdentity.resourceGroupName
                        SubscriptionId    = $ManagedIdentity.subscriptionId
                    }

                    Remove-AzFederatedIdentityCredential @ficSplat -Confirm:$false -Verbose:$false | Out-Null

                    Write-Verbose "[REMOVED]: Federated identity credential '$($fic.Name)' (ID: $($fic.Id))"
                    $fic = $null
                } else {
                    Write-Verbose "[WHATIF]: Call Remove-AzFederatedIdentityCredential with parameters: $($ficSplat | ConvertTo-Json -Depth 5)"
                }
            } else {
                Write-Warning "[NOTFOUND]: Federated identity credential '$($ManagedIdentity.federatedIdentityCredential.name)' (ID: <unknown>)"
            }

            # Service endpoint
            if ($null -ne $sep) {
                if ($PSCmdlet.ShouldProcess($ProjectName, "Remove service endpoint: $($Name)")) {
                    if ($fic) {
                        throw "Federated identity credential '$($ManagedIdentity.federatedIdentityCredential.name)' still exists! Cannot remove service endpoint '$($Name)'."
                    }

                    $sepSplat = [ordered]@{
                        CollectionUri = $CollectionUri
                        ProjectName   = $ProjectName
                        Id            = $sep.id
                        ProjectIds    = $prj.id
                    }

                    $maxAttempts = 3; $waitSeconds = 15; $attempt = 0; $success = $false

                    while ($attempt -lt $maxAttempts -and -not $success) {
                        $attempt++

                        try {
                            Write-Verbose "Removing service endpoint: '$($sep.name)', attempt '$($attempt)' of '$($maxAttempts)'..."

                            Remove-AdoServiceEndpoint @sepSplat -Confirm:$false -Verbose:$false | Out-Null

                            $success = $true
                            $status = 'Removed'
                            Write-Verbose "[REMOVED]: Service endpoint '$($sep.name)' (ID: $($sep.id))"
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
                    $status = 'WouldRemove'
                    Write-Verbose "[WHATIF]: Call Remove-AdoServiceEndpoint with parameters: $($sepSplat | ConvertTo-Json -Depth 5)"
                }
            } else {
                $status = 'NotFound'
                $sep = [PSCustomObject]@{
                    name          = $Name
                    projectName   = $ProjectName
                    collectionUri = $CollectionUri
                }

                Write-Warning "[NOTFOUND]: Service endpoint '$($Name)' (ID: <unknown>)"
            }

            # Return rollback result
            return $sep | Select-Object -Property *, @{
                Name = 'status'; Expression = { $status }
            }
        }

        #endregion

        #region OUTPUTS

        $sep | Select-Object -ExcludeProperty collectionUri, projectName -Property *,
        @{ Name = 'projectName'; Expression = { $ProjectName } },
        @{ Name = 'collectionUri'; Expression = { $CollectionUri } },
        @{ Name = 'status'; Expression = { $status } }

        #endregion

    } catch {
        throw $_
    }
}

end {
    Write-Verbose "[Exit]: ./src/res/connection/$($MyInvocation.MyCommand.Name)"
}
