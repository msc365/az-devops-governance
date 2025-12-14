<#
.SYNOPSIS
    Deploys dependencies for Azure DevOps Service Connection.

.DESCRIPTION
    Deploys a Resource Group and a Managed Identity for  Azure DevOps Service Connection.

.PARAMETER IdentityName
    Required. The name of the Managed Identity to create.

.PARAMETER ResourceGroupName
    Required. The name of the Resource Group to create.

.PARAMETER Location
    Optional. The Azure region where the resources will be created. Default is 'westeurope'.

.PARAMETER Tags
    Optional. A hashtable of tags to assign to the resources. Default is an empty hashtable.

.PARAMETER SubscriptionId
    Required. The Subscription ID where the resources will be created.

.PARAMETER Rollback
    Optional. If specified, the script will delete the created resources.

.PARAMETER Force
    Optional. If specified, the script will not prompt for confirmation during rollback.

.EXAMPLE
    .\dependencies.ps1 -IdentityName 'myIdentity' -ResourceGroupName 'myResourceGroup' -SubscriptionId 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'

    Deploys the dependencies in the specified subscription.

.NOTES
    Ensure you are logged in to Azure using Connect-AzAccount before running this script.
#>
[CmdletBinding(SupportsShouldProcess)]
[OutputType([pscustomobject])]
param (
    [Parameter(Mandatory)]
    [string]$IdentityName,

    [Parameter(Mandatory)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory = $false)]
    [string]$Location = 'westeurope',

    [Parameter(Mandatory = $false)]
    [object]$Tags = @{},

    [Parameter(Mandatory)]
    [string]$SubscriptionId,

    [Parameter()]
    [switch]$Rollback,

    [Parameter()]
    [switch]$Force
)

begin {
    Write-Verbose ('[Enter]: .\src\res\service-connection\modules\{0}' -f $MyInvocation.MyCommand.Name)
}

process {
    try {
        $ErrorActionPreference = 'Stop'

        #region INITIALIZE

        # Variables #
        $ctx, $sub, $rg, $msi = $null

        # Subscription Context #
        $ctx = (Get-AzContext).Subscription

        if ($ctx.Id -ne $SubscriptionId) {
            $sub = (Set-AzContext -SubscriptionId $SubscriptionId -WhatIf:$false).Subscription
        }

        # Resource Group #
        $rgSplat = @{
            Name     = $ResourceGroupName
            Location = $Location
            Tags     = $Tags
            Rollback = $Rollback.IsPresent
            WhatIf   = $WhatIfPreference
            Verbose  = $VerbosePreference
        }

        $rg = & (Join-Path -Path $PSScriptRoot -ChildPath '..\..\shared\resource-group\main.ps1') @rgSplat

        # Managed Identity #
        $msiSplat = @{
            Name              = $IdentityName
            ResourceGroupName = $ResourceGroupName
            SubscriptionId    = $SubscriptionId
            Verbose           = $VerbosePreference
        }

        $msi = Get-AzUserAssignedIdentity @msiSplat -ErrorAction SilentlyContinue

        #endregion

        #region DEPLOYMENTS

        # Managed Identity #
        if (-not $Rollback.IsPresent) {
            if ($null -eq $msi) {
                if ($PSCmdlet.ShouldProcess("Call module 'Az.ManagedServiceIdentity' operation.", 'New-AzUserAssignedIdentity')) {

                    $msiSplat += @{
                        Location = $Location
                        Tag      = $Tags
                    }

                    $msi = New-AzUserAssignedIdentity @msiSplat
                }
            } else {
                Write-Verbose ("Exists. '/managedServiceIdentity/{0}'" -f $msi.Name)
            }
        }

        #endregion

        #region ROLLBACK

        if ($Rollback.IsPresent) {
            if ($null -ne $msi) {
                if ($PSCmdlet.ShouldProcess("Call module 'Az.ManagedServiceIdentity' operation.", 'Remove-AzUserAssignedIdentity')) {
                    if (-not $Force.IsPresent) {
                        $prompt = @(
                            "This will delete '/managedServiceIdentity/$($IdentityName)'."
                            "All related resources like 'federatedIdentityCredentials' will be lost."
                            "Do you want to continue? 'Yes [Y]' 'No [N]'"
                        ) -join "`n"

                        $result = Read-Host -Prompt $prompt
                        $result = $result.ToLower()

                        if ($result -ne 'y' -and $result -ne 'yes') {
                            Write-Warning 'Operation cancelled by user'
                            return
                        }
                    }

                    Write-Verbose ("Removing '/managedServiceIdentity/{0}' dependencies..." -f $msi.Name)

                    $msi | Remove-AzUserAssignedIdentity | Out-Null
                    Write-Verbose ("Deleted. '/managedServiceIdentity/{0}'" -f $IdentityName)
                }
            } else {
                Write-Warning ("Doesn't exist. '/managedServiceIdentity/{0}'" -f $IdentityName)
            }
        }

        #endregion

        #region OUTPUTS

        $output = [pscustomobject]@{
            Identity      = ($msi | Select-Object *) ?? $null
            ResourceGroup = ($rg | Select-Object *) ?? $null
        }

        return $output

        #endregion

    } catch {
        throw $_
    }

    finally {
        if ($null -ne $ctx -and $null -ne $sub) {
            Set-AzContext -SubscriptionId $ctx.Id -Verbose:$false | Out-Null
        }
    }
}

end {
    Write-Verbose ('[Exit]: .\src\res\service-connection\modules\{0}' -f $MyInvocation.MyCommand.Name)
}
