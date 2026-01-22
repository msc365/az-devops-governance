<#
.SYNOPSIS
    Deploys dependencies for Azure DevOps Service Connection.

.DESCRIPTION
    Deploys a Resource Group and a Managed Identity for  Azure DevOps Service Connection.

.PARAMETER IdentityName
    Required. The name of the Managed Identity to create.

.PARAMETER SubscriptionId
    Required. The Subscription ID where the resources will be created.

.PARAMETER ResourceGroupName
    Required. The name of the Resource Group to create.

.PARAMETER Location
    Optional. The Azure region where the resources will be created (e.g.: 'westeurope', 'northeurope').

.PARAMETER Tags
    Optional. A hashtable of tags to assign to the resources. Default is an empty hashtable.

.PARAMETER Rollback
    Optional. If specified, the script will delete the created resources.

.EXAMPLE
    $depSplat = @{
        IdentityName      = 'id-e2egov-prjHb72x9-tst'
        SubscriptionId    = '00000000-0000-0000-0000-000000000000'
        ResourceGroupName = 'rg-e2egov-prjHb72x9-tst-weu'
        Location          = 'westeurope'
        Tags              = @{ environment = 'tst'; service = 'e2egov' }
    }
    .\dependencies.ps1 @depSplat

    Deploys the dependencies in the specified subscription.
#>
[CmdletBinding(SupportsShouldProcess)]
[OutputType([PSCustomObject])]
param (
    [Parameter(Mandatory)]
    [string]$IdentityName,

    [Parameter(Mandatory)]
    [string]$SubscriptionId,

    [Parameter(Mandatory)]
    [string]$ResourceGroupName,

    [Parameter()]
    [string]$Location,

    [Parameter()]
    [object]$Tags,

    [Parameter()]
    [switch]$Rollback
)

begin {
    Write-Verbose ('[Enter]: ./src\res\service-connection\modules\{0}' -f $MyInvocation.MyCommand.Name)
}

process {
    try {
        $ErrorActionPreference = 'Stop'

        #region INITIALIZE

        # Status
        $status = 'Unknown'

        # Variables #
        $ctx, $rg, $msi = $null

        # Resource Group
        $rgSplat = @{
            Name           = $ResourceGroupName
            Location       = $Location
            SubscriptionId = $SubscriptionId
            Tags           = $Tags
            Rollback       = $Rollback.IsPresent
            WhatIf         = $WhatIfPreference
            Verbose        = $VerbosePreference
        }

        $rg = & (Join-Path -Path $PSScriptRoot -ChildPath '..\..\shared\resource-group\main.ps1') @rgSplat -Confirm:$false

        # Managed Identity #
        $msiSplat = @{
            Name              = $IdentityName
            ResourceGroupName = $ResourceGroupName
            SubscriptionId    = $SubscriptionId
        }

        $msi = Get-AzUserAssignedIdentity @msiSplat -Verbose:$false -ErrorAction SilentlyContinue

        #endregion

        #region DEPLOYMENTS

        if (-not $Rollback.IsPresent) {
            # Managed service identity
            if ($null -eq $msi) {
                if ($PSCmdlet.ShouldProcess($ResourceGroupName, "Create managed identity: $($IdentityName)")) {
                    $msiSplat += @{
                        Location = $Location
                        Tag      = $Tags
                    }

                    $msi = New-AzUserAssignedIdentity -Confirm:$false -Verbose:$false @msiSplat

                    $status = 'Created'
                    Write-Verbose "[CREATE] Managed identity: '$IdentityName' (PrincipalId: $($msi.principalId))"
                } else {
                    $status = 'Skipped'
                    Write-Verbose "[WHATIF] Call New-AzUserAssignedIdentity with parameters: $($msiSplat | ConvertTo-Json -Depth 5)"
                }
            } else {
                $status = 'NoChange'
                Write-Verbose "[NOCHANGE] Managed identity: '$IdentityName' (PrincipalId: $($msi.principalId))"
            }
        }

        #endregion

        #region ROLLBACK

        if ($Rollback.IsPresent) {
            if ($null -ne $msi) {
                if ($PSCmdlet.ShouldProcess($ResourceGroupName, "Remove managed identity: $IdentityName")) {

                    $msi | Remove-AzUserAssignedIdentity -Confirm:$false -Verbose:$false | Out-Null

                    $status = 'Removed'
                    Write-Verbose "[REMOVE] Managed identity: '$IdentityName' (PrincipalId: $($msi.principalId))"
                } else {
                    $status = 'Skipped'
                    Write-Verbose "[WHATIF] Call Remove-AzUserAssignedIdentity with parameters: $($msiSplat | ConvertTo-Json -Depth 5)"
                }
            } else {
                $status = 'NotFound'
                Write-Warning "[NOTFOUND] Managed identity: '$IdentityName' (PrincipalId: UNKNOWN)"
            }
        }

        #endregion

        #region OUTPUTS

        $obj = [ordered]@{
            id                = if ($msi) { $msi.id } else { $null }
            name              = if ($msi) { $msi.name } else { $null }
            clientId          = if ($msi) { $msi.clientId } else { $null }
            principalId       = if ($msi) { $msi.principalId } else { $null }
            tenantId          = if ($msi) { $msi.tenantId } else { $null }
            resourceGroupName = if ($msi) { $msi.resourceGroupName } else { $null }
            type              = if ($msi) { $msi.type } else { $null }
        }
        $obj['status'] = $status
        [PSCustomObject]$obj

        #endregion

    } catch {
        throw $_
    }
}

end {
    Write-Verbose ('[Exit]: ./src\res\service-connection\modules\{0}' -f $MyInvocation.MyCommand.Name)
}
