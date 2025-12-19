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

.PARAMETER Rollback
    Not implemented yet. See [Notes](#notes) for detailed information.

.PARAMETER Force
    Not implemented yet.

.EXAMPLE
    $rgParams = @{
        Name     = 'rg-e2egov-prjHb72x9-tst-weu'
        Location = 'westeurope'
        Tags     = @{
            'environment' = 'tst'
            'owner'       = 'e2egov'
        }
        Verbose  = $true
    }
    .\main.ps1 @rgParams

    Creates or updates the Resource Group 'rg-e2egov-prjHb72x9-tst-weu' in the 'westeurope' region with the specified tags.
#>
[CmdletBinding(SupportsShouldProcess)]
[OutputType([PSCustomObject])]
param (
    [Parameter(Mandatory)]
    [string]$Name,

    [Parameter(Mandatory)]
    [string]$Location,

    [Parameter(Mandatory = $false)]
    [object]$Tags,

    [Parameter()]
    [switch]$Rollback,

    [Parameter()]
    [switch]$Force
)

begin {
    Write-Verbose "[Enter]: .\src\res\shared\resource-group\$($MyInvocation.MyCommand.Name)"
}

process {
    try {
        $ErrorActionPreference = 'Stop'

        #region INITIALIZE

        # Variables
        $rg = $null

        # Resource Group
        $rg = Get-AzResourceGroup -Name $Name -ErrorAction SilentlyContinue

        #endregion

        #region DEPLOYMENT

        if (-not $Rollback.IsPresent) {
            if ($null -eq $rg) {
                if ($PSCmdlet.ShouldProcess("resourceGroup/$($Name)", 'Create')) {
                    $rgSplat = @{
                        Name     = $Name
                        Location = $Location
                        Tags     = $Tags
                        Verbose  = $VerbosePreference
                    }

                    $rg = New-AzResourceGroup @rgSplat -ErrorAction Stop
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

                # Update tags if they differ
                if ($tagsDiff) {
                    if ($PSCmdlet.ShouldProcess("resourceGroup/$($Name)", 'Update')) {
                        $rgSplat = @{
                            Name    = $Name
                            Tags    = $Tags
                            Verbose = $VerbosePreference
                        }

                        $rg = Set-AzResourceGroup @rgSplat -ErrorAction Stop
                    }
                } else {
                    Write-Verbose "Exists: 'resourceGroup/$($Name)'"
                }
            }
        }

        #endregion

        #region ROLLBACK

        if ($Rollback.IsPresent) {
            if ($null -ne $rg) {
                if ($PSCmdlet.ShouldProcess("resourceGroup/$($Name)", 'None')) {
                    Write-Verbose "Not Deleted: 'resourceGroup/$($Name)'"
                }
            } else {
                Write-Verbose "Doesn't exist: 'resourceGroup/$($Name)'"
            }
        }

        #endregion

        #region OUTPUT

        return $rg

        #endregion

    } catch {
        throw $_
    }
}

end {
    Write-Verbose "[Exit]: .\src\res\shared\resource-group\$($MyInvocation.MyCommand.Name)"
}
