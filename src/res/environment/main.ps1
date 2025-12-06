#Requires -Version 7.0
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
    [string]$Organization,

    [Parameter(Mandatory)]
    [string]$ProjectId,

    [Parameter(Mandatory)]
    [string]$Name,

    [Parameter(Mandatory = $false)]
    [string]$Description,

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

    # Import required modules
    $modules = @(
        'Az.Accounts'
        'Az.Resources'
        'Azure.DevOps.PSModule'
    )

    $modules | ForEach-Object {
        if (-not (Get-Module $_) -or (Get-Module $_ -ListAvailable)) {
            Import-Module $_ -Force -Verbose:$false -ErrorAction Stop
        }
    }

    # Connect to Azure DevOps Organization
    if ($null -eq (Get-AdoContext)) {
        Connect-AdoOrganization -Organization $Organization -Verbose:$VerbosePreference
    }
}

process {
    try {
        $ErrorActionPreference = 'Stop'
        $Error.Clear()

        ## --------- ##
        ## VARIABLES ##
        ## --------- ##

        $prj, $rg, $env = $null

        ## ------------ ##
        ## DEPENDENCIES ##
        ## ------------ ##

        $prj = Get-AdoProject -ProjectId $ProjectId -ErrorAction SilentlyContinue

        if ($null -eq $prj) {
            throw ("Doesn't exists. 'RESOURCE /projects/{0}' ." -f $ProjectId)
        }

        if ($null -ne $ResourceGroup) {
            $contextSub = (Get-AzContext).Subscription

            if ($contextSub.Id -ne $ResourceGroup.subscriptionId) {
                $targetSub = (Set-AzContext -SubscriptionId $ResourceGroup.subscriptionId -WhatIf:$false).Subscription
            }
        }

        ## --------- ##
        ## RESOURCES ##
        ## --------- ##

        $env = Get-AdoEnvironmentList -ProjectId $prj.Id -Name $Name -ErrorAction SilentlyContinue

        if ($Remove.IsPresent) {
            if ($null -ne $env) {
                if ($PSCmdlet.ShouldProcess("Call module 'Azure.DevOps.PSModule' operation.", 'Remove-AdoEnvironment')) {
                    if (-not $Force.IsPresent) {
                        $prompt = @(
                            "This script will delete the environment '$($Name)'."
                            'All related resources like Azure DevOps environment with approvals and checks will be lost.'
                            "Do you want to continue? 'Yes [Y]' 'No [N]'"
                        ) -join "`n"

                        $result = Read-Host -Prompt $prompt
                        $result = $result.ToLower()

                        if ($result -ne 'y' -and $result -ne 'yes') {
                            Write-Warning 'Operation cancelled by user'
                            return
                        }
                    }

                    ## Environment ##
                    ## ----------- ##

                    Remove-AdoEnvironment -ProjectId $prj.Id -EnvironmentId $env.Id -Verbose:$VerbosePreference | Out-Null
                }
            } else {
                Write-Warning ("Doesn't Exist. 'RESOURCE /environments/{0}'" -f $Name)
            }

            ## Resource Group ##
            ## -------------- ##

            if ($null -ne $ResourceGroup) {
                $rg = Get-AzResourceGroup -Name $ResourceGroup.name -ErrorAction SilentlyContinue -Verbose:$false

                if ($null -ne $rg) {
                    if ($PSCmdlet.ShouldProcess("Call module 'Az.Resources' operation.", 'Remove-AzResourceGroup')) {
                        if (-not $Force.IsPresent) {
                            $prompt = @(
                                "This script will delete the environment '$($rg.ResourceGroupName)'."
                                'All resources in the resource group will be lost.'
                                "Do you want to continue? 'Yes [Y]' 'No [N]'"
                            ) -join "`n"

                            $result = Read-Host -Prompt $prompt
                            $result = $result.ToLower()

                            if ($result -ne 'y' -and $result -ne 'yes') {
                                Write-Warning 'Operation cancelled by user'
                                return
                            }
                        }

                        Remove-AzResourceGroup -Id $rg.ResourceId -Force -Verbose:$VerbosePreference | Out-Null
                    }
                } else {
                    Write-Warning ("Doesn't Exist. 'RESOURCE GROUP /{0}'" -f $ResourceGroup.name)
                }
            }

            return
        }

        if ($null -eq $env) {
            if ($PSCmdlet.ShouldProcess("Call module 'Azure.DevOps.PSModule' operation.", 'New-AdoEnvironment')) {

                $envSplat = @{
                    ProjectId   = $prj.Id
                    Name        = $Name
                    Description = $Description
                    Verbose     = $VerbosePreference
                }

                $env = New-AdoEnvironment @envSplat
            }
        } else {
            if ($Description -ne $env.description -or
                $Name -ne $env.name) {

                if ($PSCmdlet.ShouldProcess("Call module 'Azure.DevOps.PSModule' operation.", 'Update-AdoEnvironment')) {
                    $envSplat = @{
                        ProjectId     = $prj.Id
                        EnvironmentId = $env.Id
                        Name          = $Name
                        Description   = $Description
                        Verbose       = $VerbosePreference
                    }

                    $env = Set-AdoEnvironment @envSplat
                }
            } else {
                Write-Verbose ("Exists. No updates. 'RESOURCE /environment/{0}'" -f $env.name)
            }
        }

        ## ---------------- ##
        ## NESTED RESOURCES ##
        ## ---------------- ##

        ## Resource Group ##
        ## -------------- ##

        if ($null -ne $ResourceGroup) {
            $rgSplat = @{
                Name     = $ResourceGroup.name
                Location = $ResourceGroup.location
                Tags     = $ResourceGroup.tags
                Verbose  = $VerbosePreference
                WhatIf   = $WhatIfPreference
            }

            $rg = & (Join-Path -Path $PSScriptRoot -ChildPath 'modules\nested_resourceGroup.ps1') @rgSplat

        } else {
            Write-Verbose ("Null. 'PARAMETER /ResourceGroup'")
        }

        ## ------- ##
        ## OUTPUTS ##
        ## ------- ##

        $output = [pscustomobject]@{
            name          = $env.name
            description   = $env.description
            environmentId = $env.Id
        }

        if ($null -ne $rg) {
            $output | Add-Member -MemberType NoteProperty -Name 'resourceGroup' -Value ($rg | Select-Object -Property ResourceGroupName, Location, ResourceId)
        }

        return -not $WhatIfPreference ? $output : $null

    } catch {
        throw $_
    }

    finally {
        if ($null -ne $targetSub) {
            Set-AzContext -SubscriptionId $contextSub.Id -Verbose:$false | Out-Null
        }
    }
}

end {
    Write-Verbose ('Exit : {0}' -f $MyInvocation.MyCommand.Name)
}
