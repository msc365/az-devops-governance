<#PSScriptInfo
    .VERSION 0.1.0

    .GUID 6ea00de2-e56e-476e-8e48-88a949f8b80c

    .AUTHOR Martin Swinkels

    .COMPANYNAME MSc365.eu

    .COPYRIGHT 2025 (c) MSc365.eu, Martin Swinkels

    .TAGS 'Azure', 'Security', 'Governance', 'DevOps', 'Platform', 'RBAC'

    .LICENSEURI https://github.com/msc365/az-devops-governance/blob/main/LICENSE

    .PROJECTURI https://github.com/msc365/az-devops-governance

    .ICONURI https://raw.githubusercontent.com/msc365/az-devops-governance/main/.assets/icon.png

    .EXTERNALMODULEDEPENDENCIES Az.Accounts, Az.Resources
#>
<#
.SYNOPSIS
    Create or update an Azure Resource Group.

.DESCRIPTION
    This script creates a new Azure Resource Group or updates an existing one with specified tags.

.PARAMETER Name
    Required. The name of the Resource Group.

.PARAMETER Location
    Required. The Azure region where the Resource Group will be created e.g.: 'westeurope', 'northeurope'.

.PARAMETER Tags
    Optional. A hashtable of tags to assign to the Resource Group.

.PARAMETER SubscriptionId
    Optional. The Azure subscription ID where the resource group will be created. If not provided, the current context subscription will be used.

.PARAMETER Rollback
    Not implemented by design. See [Notes](#notes) for detailed information.

.EXAMPLE
    $rgParams = @{
        Name           = 'rg-e2egov-prjHb72x9-tst-weu'
        Location       = 'westeurope'
        SubscriptionId = '00000000-0000-0000-0000-000000000000'
        Tags           = @{
            'environment' = 'tst'
            'owner'       = 'e2egov'
        }
    }
    .\main.ps1 @rgParams

    Creates or updates the resource group 'rg-e2egov-prjHb72x9-tst-weu' in the 'westeurope' region with the specified tags.
    The resource group will be deployed in  current Azure subscription context.
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
[OutputType([PSCustomObject])]
param (
    [Parameter(Mandatory)]
    [string]$Name,

    [Parameter(Mandatory)]
    [string]$Location,

    [Parameter()]
    [string]$SubscriptionId,

    [Parameter()]
    [object]$Tags,

    [Parameter()]
    [switch]$Rollback
)

begin {
    Write-Verbose "[Enter]: .\src\res\shared\resource-group\$($MyInvocation.MyCommand.Name)"

    # Variables
    $ctxInfo = $null

    # Import and use context helper utility if SubscriptionId is provided
    if ($PSBoundParameters.ContainsKey('SubscriptionId') -and
        -not [string]::IsNullOrWhiteSpace($SubscriptionId)) {

        . (Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\utl\Set-AzContextInfo.ps1')

        $ctxInfo = Set-AzContextInfo -SubscriptionId $SubscriptionId -Verbose:$VerbosePreference
    }

    # Validate Azure context
    $subscription = (Get-AzContext).Subscription

    if ($null -eq $subscription) {
        throw 'No Azure subscription context found. Please login using Connect-AzAccount.'
    } else {
        Write-Verbose "Using subscription: $($subscription.Name) (ID: $($subscription.Id))"
    }
}

process {
    try {
        $ErrorActionPreference = 'Stop'

        #region INITIALIZE

        # Status
        $status = 'Unknown'

        # Variables
        $rg = $null

        # Resource group
        $rg = Get-AzResourceGroup -Name $Name -ErrorAction SilentlyContinue

        #endregion

        #region DEPLOYMENTS

        if (-not $Rollback.IsPresent) {
            if ($null -eq $rg) {
                if ($PSCmdlet.ShouldProcess($subscription.Name, "Create resource group: $Name")) {
                    $rgSplat = @{
                        Name     = $Name
                        Location = $Location
                    }
                    if ($null -ne $Tags) {
                        $rgSplat['Tags'] = $Tags
                    }

                    $rg = New-AzResourceGroup @rgSplat -Verbose:$false -ErrorAction Stop

                    $status = 'Created'
                    Write-Verbose "[CREATE] Resource group: '$Name'"
                } else {
                    $status = 'Skipped'
                    Write-Verbose "[WHATIF] Call New-AzResourceGroup with parameters: $($rgSplat | ConvertTo-Json -Depth 5)"
                }
            } else {
                # Check if tags differ
                $tagsDiff = $false
                foreach ($key in $Tags.Keys) {
                    if ($rg.Tags.Count -ne $Tags.Count -or
                        -not $rg.Tags.ContainsKey($key) -or
                        $rg.Tags[$key] -ne $Tags[$key]) {

                        $tagsDiff = $true
                        break
                    }
                }

                # Set tags if they differ
                if ($tagsDiff) {
                    if ($PSCmdlet.ShouldProcess($subscription.Name, "Update resource group: $Name")) {
                        $rgSplat = @{
                            Name = $Name
                            Tags = $Tags
                        }

                        $rg = Set-AzResourceGroup @rgSplat -Verbose:$false -ErrorAction Stop

                        $status = 'Updated'
                        Write-Verbose "[UPDATE] Resource group: '$Name'"
                    } else {
                        $status = 'Skipped'
                        Write-Verbose "[WHATIF] Call Set-AzResourceGroup with parameters: $($rgSplat | ConvertTo-Json -Depth 5)"
                    }
                } else {
                    $status = 'NoChange'
                    Write-Verbose "[NOCHANGE] Resource group: '$Name'"
                }
            }
        }

        #endregion

        #region ROLLBACK

        if ($Rollback.IsPresent) {
            if ($null -ne $rg) {
                if ($PSCmdlet.ShouldProcess($subscription.Name, "Skip resource group: $Name (not removed by design)")) {
                    $status = 'Skipped'
                    Write-Verbose "[SKIPPED] Resource group: '$Name' (not removed by design)"
                } else {
                    $status = 'Skipped'
                    Write-Verbose "[WHATIF] Resource group: '$Name' would be skipped (not removed)"
                }
            } else {
                $status = 'NotFound'
                Write-Verbose "[NOTFOUND] Resource group: '$Name'"
            }

            # Return rollback result
            return [PSCustomObject]@{
                name         = $Name
                location     = $Location
                subscription = [ordered]@{
                    Id   = $subscription.Id
                    Name = $subscription.Name
                }
                resourceType = 'ResourceGroup [Az]'
                action       = 'Rollback'
                status       = $status
            }
        }

        #endregion

        #region OUTPUTS

        $obj = [ordered]@{
            name         = if ($rg) { $rg.ResourceGroupName } else { $Name }
            location     = if ($rg) { $rg.Location } else { $Location }
            resourceId   = if ($rg) { $rg.ResourceId } else { $null }
            subscription = [ordered]@{
                Id   = $subscription.Id
                Name = $subscription.Name
            }
        }
        if ($rg -and $rg.Tags) {
            $obj['tags'] = $rg.Tags
        }
        $obj['resourceType'] = 'ResourceGroup [Az]'
        $obj['status'] = $status
        [PSCustomObject]$obj

        #endregion

    } catch {
        throw $_
    } finally {
        # Restore original Azure context if it was switched
        if ($null -ne $ctxInfo) {
            Restore-AzContextInfo -ContextInfo $ctxInfo
        }
    }
}

end {
    Write-Verbose "[Exit]: .\src\res\shared\resource-group\$($MyInvocation.MyCommand.Name)"
}
