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

.PARAMETER Organization
    Required. The Azure DevOps organization name.

.PARAMETER ProjectId
    Required. The Azure DevOps project ID or Name where the service connection will be created.

.PARAMETER ServiceEndpointName
    Required. The name of the service connection to be created.

.PARAMETER Scope
    Required. The scope for the service connection (e.g., /subscriptions/00000000-0000-0000-0000-000000000000).

.PARAMETER ManagedServiceIdentity
    Required. An object containing details of the Managed Service Identity to be used.

.PARAMETER Rollback
    Optional. Switch to indicate if the operation should rollback (delete) the service connection and related resources. <br /> ⚠️ <b> WARNING! </b> <br /> Use with caution! Removing a service connection is irreversible and may affect teams relying on it. See [Notes](#notes) for more information.

.PARAMETER Force
    Optional. Switch to force deletion without confirmation during rollback.

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
        Organization           = 'e2egov-org'
        ProjectId              = 'e2egov-prjHb72x9'
        ServiceEndpointName    = 'rg-e2egov-prjHb72x9-tst-weu'
        Scope                  = '/subscriptions/00000000-0000-0000-0000-000000000000'
        ManagedServiceIdentity = @{
            name               = 'id-e2egov-prjHb72x9-tst'
            resourceGroupName  = 'rg-e2egov-prjHb72x9-tst-weu'
            subscriptionId     = '00000000-0000-0000-0000-000000000000'
            location           = 'westeurope'
            tags               = @{ 'environment' = 'prd'; 'owner' = 'e2egov' }
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
    [Parameter(Mandatory)]
    [string]$Organization,

    [Parameter(Mandatory)]
    [string]$ProjectId,

    [Parameter(Mandatory)]
    [string]$ServiceEndpointName,

    [Parameter(Mandatory)]
    [string]$Scope,

    [Parameter(Mandatory)]
    [object]$ManagedServiceIdentity,

    [Parameter()]
    [switch]$Rollback,

    [Parameter()]
    [switch]$Force
)

begin {
    Write-Verbose ('[Enter]: .\src\res\service-connection\{0}' -f $MyInvocation.MyCommand.Name)

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
        $prj, $dep, $se, $fic, $sync, $ras = $null

        # Project
        $prj = Get-AdoProject -ProjectId $ProjectId -ErrorAction SilentlyContinue

        if ($null -eq $prj) {
            throw ("Doesn't exists. '/projects/{0}' ." -f $ProjectId)
        }

        # Dependencies
        $depSplat = @{
            IdentityName      = $ManagedServiceIdentity.name
            ResourceGroupName = $ManagedServiceIdentity.resourceGroupName
            SubscriptionId    = $ManagedServiceIdentity.subscriptionId
            Location          = $ManagedServiceIdentity.location
            Tags              = $ManagedServiceIdentity.tags
            Rollback          = $Rollback.IsPresent
            Force             = $Force.IsPresent
            WhatIf            = $WhatIfPreference
            Verbose           = $VerbosePreference
        }

        $dep = & (Join-Path -Path $PSScriptRoot -ChildPath 'modules\dependencies.ps1') @depSplat

        # Service Endpoint
        $seSplat = @{
            ProjectId    = $ProjectId
            EndPointName = $ServiceEndpointName
            Verbose      = $VerbosePreference
        }

        $se = Get-AdoServiceEndpointByName @seSplat -ErrorAction SilentlyContinue

        # Federated Credential
        $ficName = 'fic-{0}' -f $ServiceEndpointName.Substring(3)

        $ficSplat = @{
            Name              = $ficName
            IdentityName      = $ManagedServiceIdentity.name
            ResourceGroupName = $ManagedServiceIdentity.resourceGroupName
            SubscriptionId    = $ManagedServiceIdentity.subscriptionId
            Verbose           = $VerbosePreference
        }

        $fic = Get-AzFederatedIdentityCredential @ficSplat -ErrorAction SilentlyContinue

        # Role Assignments
        $rasSplat = @{
            ObjectId            = ($null -ne $dep.Identity) ? $dep.Identity.PrincipalId : '[Unknown]'
            RoleAssignments     = $ManagedServiceIdentity.roleAssignments
            EnforceDesiredState = $true
            Rollback            = $Rollback.IsPresent
            Force               = $Force.IsPresent
            WhatIf              = $WhatIfPreference
            Verbose             = $VerbosePreference
        }

        $ras = & (Join-Path -Path $PSScriptRoot -ChildPath '..\shared\role-assignment\main.ps1') @rasSplat

        #endregion

        #region DEPLOYMENTS

        if (-not $Rollback.IsPresent) {

            # Service Endpoint
            if ($null -eq $se) {
                if ($PSCmdlet.ShouldProcess(('serviceEndpoint/{0}' -f $ServiceEndpointName), 'Create')) {

                    $subSplat = @{
                        SubscriptionId = ($Scope -split '/')[2]
                        TenantId       = $dep.Identity.TenantId
                    }

                    $sub = Get-AzSubscription @subSplat -ErrorAction Stop

                    $data = [Ordered]@{
                        creationMode     = 'Manual'
                        environment      = 'AzureCloud'
                        scopeLevel       = 'Subscription'
                        subscriptionId   = $sub.SubscriptionId
                        subscriptionName = $sub.Name
                    }

                    $sepConfig = [Ordered]@{
                        data                             = $data
                        name                             = $ServiceEndpointName
                        type                             = 'AzureRM'
                        url                              = 'https://management.azure.com/'
                        authorization                    = [Ordered]@{
                            parameters = [Ordered]@{
                                serviceprincipalid = $dep.Identity.ClientId
                                tenantid           = $dep.Identity.TenantId
                                scope              = $Scope
                            }
                            scheme     = 'WorkloadIdentityFederation'
                        }
                        isShared                         = $false
                        isReady                          = $true
                        serviceEndpointProjectReferences = @(
                            [Ordered]@{
                                name             = $ServiceEndpointName
                                projectReference = [Ordered]@{
                                    id   = $prj.Id
                                    name = $prj.Name
                                }
                            }
                        )
                    }

                    $seSplat = @{
                        Configuration = ($sepConfig | ConvertTo-Json -Depth 5)
                        Verbose       = $VerbosePreference
                    }

                    $se = New-AdoServiceEndpoint @seSplat -ErrorAction Stop
                }
            } else {
                Write-Verbose ("Exists. 'serviceEndpoint/{0}'" -f $se.Name)
            }

            # Federated Credential
            if ($null -eq $fic) {
                if ($PSCmdlet.ShouldProcess(('federatedIdentityCredential/{0}' -f $ficName), 'Create')) {

                    if ($null -eq $se) {
                        throw ("ServiceEndpoint '{0}' not found! Cannot create 'federatedIdentityCredential'." -f $ServiceEndpointName)
                    }

                    $ficSplat += @{
                        Issuer  = $se.Authorization.Parameters.WorkloadIdentityFederationIssuer
                        Subject = $se.Authorization.Parameters.WorkloadIdentityFederationSubject
                    }

                    $fic = New-AzFederatedIdentityCredential @ficSplat -ErrorAction Stop
                }
            } else {
                Write-Verbose ("Exists. 'federatedIdentityCredential/{0}'" -f $fic.Name)
            }
        }
        #endregion

        #region ROLLBACK

        if ($Rollback.IsPresent) {
            # Service Endpoint
            if ($null -ne $se) {
                if ($PSCmdlet.ShouldProcess(('serviceEndpoint/{0}' -f $ServiceEndpointName), 'Delete')) {
                    if (-not $Force.IsPresent) {
                        $prompt = @(
                            "This will delete '/serviceEndpoint/$($se.Name)'."
                            "Do you want to continue? 'Yes [Y]' 'No [N]'"
                        ) -join "`n"

                        $result = Read-Host -Prompt $prompt
                        $result = $result.ToLower()

                        if ($result -ne 'y' -and $result -ne 'yes') {
                            Write-Warning 'Operation cancelled by user'
                            return
                        }
                    }

                    $seSplat = @{
                        EndpointId = $se.Id
                        ProjectIds = $prj.Id
                        Verbose    = $VerbosePreference
                    }

                    $maxAttempts = 3; $waitSeconds = 15; $attempt = 0; $success = $false

                    while ($attempt -lt $maxAttempts -and -not $success) {
                        $attempt++

                        try {
                            Write-Verbose ("Removing 'serviceEndpoint/{0}', attempt '{1}' of '{2}'..." -f $se.Name, $attempt, $maxAttempts)

                            Remove-AdoServiceEndpoint @seSplat | Out-Null
                            Write-Verbose ("Deleted. 'serviceEndpoint/{0}'" -f $se.Name)
                            $success = $true
                        } catch {
                            Write-Warning ("Attempt '{0} of {1}' failed: {2}" -f $attempt, $maxAttempts, $_.Exception.Message)

                            if ($attempt -lt $maxAttempts) {
                                Write-Information ('Retrying in {0} seconds...' -f $waitSeconds) -InformationAction Continue
                                Start-Sleep -Seconds $waitSeconds
                            } else {
                                throw $_
                            }
                        }
                    }
                }
            } else {
                Write-Warning ("Doesn't exist: 'serviceEndpoint/{0}'" -f $ServiceEndpointName)
            }

            return
        }

        #endregion

        #region OUTPUTS

        if (-not $WhatIfPreference) {

            $output = [PSCustomObject]@{
                ServiceEndpoint = ($se | Select-Object -Property *)
                Identity        = ($dep.Identity | Select-Object -Property ClientId, Id, Name, PrincipalId, ResourceGroupName, TenantId, Type)
                RoleAssignments = ($ras | ForEach-Object { $_ | Select-Object -Property ObjectId, DisplayName, RoleDefinitionName, Scope } )
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
    Write-Verbose ('[Exit]: .\src\res\service-connection\{0}' -f $MyInvocation.MyCommand.Name)
}
