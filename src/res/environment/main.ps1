<#PSScriptInfo
    .VERSION 1.0

    .GUID 4adf0e7d-d5cc-4f5a-a1fb-0945e475571a

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
    Creates or updates an Azure Environment within a specified subscription.

.DESCRIPTION
    This PowerShell script creates or updates an Azure Environment within a specified subscription.

    It provides comprehensive environment management capabilities including configuration of resource groups and their properties.

.PARAMETER Name
    The name of the environment to create or update.

.PARAMETER SubscriptionId
    The Azure Subscription ID where the environment will be created or updated.

.PARAMETER ResourceGroup
    An optional hashtable defining the resource group properties:

    - Name: The name of the resource group.
    - Location: The Azure region for the resource group.
    - Tags: A hashtable of tags to apply to the resource group.

.PARAMETER Remove
    A switch indicating whether to remove the specified environment.

.PARAMETER Force
    A switch to force removal without confirmation.

.EXAMPLE
    $params = @{
        Name           = 'my-environment'
        SubscriptionId = '00000000-0000-0000-0000-000000000000'
        ResourceGroup  = @{
            Name     = 'rg-my-environment'
            Location = 'westeurope'
            Tags     = @{ environment = 'dev' }
        }
    }
    .\main.ps1 @params

    Creates or updates the 'my-environment' environment in the specified subscription with the given resource group configuration.

.NOTES
    Requires Azure PowerShell module Az.Accounts and Azure.DevOps.PSModule.

    Ensure you are logged in to Azure using Connect-AzAccount before running this script.
#>

[CmdletBinding()]
[OutputType([pscustomobject])]
param (
    [Parameter(Mandatory)]
    [string]$Name,

    [Parameter(Mandatory)]
    [string]$SubscriptionId,

    [Parameter(Mandatory = $false)]
    [object]$ResourceGroup,

    [Parameter()]
    [switch]$Remove,

    [Parameter()]
    [switch]$Force
)

begin {
    Write-Verbose ('Command : {0}' -f $MyInvocation.MyCommand.Name)

    if ($null -eq (Get-AzContext)) {
        Write-Error 'No Azure context found. Please login using Connect-AzAccount.'
        return
    }
}

process {
    try {
        $ErrorActionPreference = 'Stop'
        $Error.Clear()

        if ($Remove.IsPresent -and -not $Force.IsPresent) {
            # Prompt user to confirm
            $prompt = @(
                "This script will delete environment '$($Name)'."
                'All related resources like resource group and Azure DevOps environment will be lost.'
                "Do you want to continue? 'Yes [Y]' 'No [N]'"
            ) -join "`n"

            $result = Read-Host -Prompt $prompt
            $result = $result.ToLower()

            if ($result -ne 'y' -and $result -ne 'yes') {
                Write-Warning 'Operation cancelled by user'
                return
            }
        }

        if ($null -ne $ResourceGroup) {
            Write-Verbose ("Target scope 'resourceGroup'. Checking context...")

            $currentSubscription = (Get-AzContext).Subscription
            Write-Verbose ("Currently using '{0}' subscription." -f $currentSubscription.Name)

            if ($SubscriptionId -ne $currentSubscription.Id) {

                $targetSubscription = (Set-AzContext -SubscriptionId $SubscriptionId).Subscription
                Write-Verbose ("Switched to '{0}' as target subscription." -f $targetSubscription.Name)
            }

            if ($Remove.IsPresent) {
                Write-Verbose ("Removing environment '{0}'..." -f $Name)

                $rg = Get-AzResourceGroup -Name $ResourceGroup.name -ErrorAction SilentlyContinue -Verbose:$false

                if ($null -ne $rg) {
                    Remove-AzResourceGroup -Name $ResourceGroup.name -Force -Verbose:$false | Out-Null

                    return [pscustomobject]@{
                        removed = $true
                        message = ("Environment '{0}' has been removed." -f $Name)
                    }
                }

                return [pscustomobject]@{
                    removed = $false
                    message = ("Environment '{0}' does not exist. No action taken." -f $Name)
                }
            }

            Write-Verbose ("Checking if resource group '{0}' exists..." -f $ResourceGroup.name)
            $rg = Get-AzResourceGroup -Name $ResourceGroup.name -ErrorAction SilentlyContinue -Verbose:$false

            if ($null -eq $rg) {

                Write-Verbose ("Resource group '{0}' does not exist. Creating resource group..." -f $ResourceGroup.name)
                $resourceGroupSplat = @{
                    Name     = $ResourceGroup.name
                    Location = $ResourceGroup.location
                    Tags     = $ResourceGroup.tags
                }

                $rg = New-AzResourceGroup @resourceGroupSplat -Verbose:$false

            } else {
                Write-Verbose ("Resource group '{0}' already exists. Updating if necessary..." -f $ResourceGroup.name)

                $tagsAreDifferent = $false
                foreach ($key in $ResourceGroup.tags.Keys) {
                    if (-not $rg.Tags.ContainsKey($key) -or $rg.Tags[$key] -ne $ResourceGroup.tags[$key]) {
                        $tagsAreDifferent = $true
                        break
                    }
                }

                if ($tagsAreDifferent) {
                    $rg = Set-AzResourceGroup -Name $ResourceGroup.name -Tag $ResourceGroup.tags -Verbose:$false
                    Write-Verbose ("Updated resource group '{0}'." -f $ResourceGroup.name)
                } else {
                    Write-Verbose ("Resource group '{0}' is up to date." -f $ResourceGroup.name)
                }
            }

            return [pscustomobject]@{
                name           = $Name
                subscriptionId = $SubscriptionId
                resourceGroup  = @{
                    name              = $rg.ResourceGroupName
                    location          = $rg.Location
                    resourceId        = $rg.ResourceId
                    tags              = $rg.Tags
                    provisioningState = $rg.ProvisioningState
                }
            }
        }

        Write-Verbose ("Target scope 'subscription'.")
        return $null

    } catch {
        throw $_
    }
}

end {
    if ($SubscriptionId -ne $currentSubscription.Id) {
        Set-AzContext -SubscriptionId $currentSubscription.Id | Out-Null
        Write-Verbose ("Reset context to '{0}' subscription." -f $currentSubscription.Name)
    }

    Write-Verbose ('Exit : {0}' -f $MyInvocation.MyCommand.Name)
}
