<#
.SYNOPSIS
    Create or update an Azure Resource Group.

.DESCRIPTION
    This script creates a new Azure Resource Group or updates an existing one with specified tags.

.PARAMETER Name
    Required. The name of the Resource Group.

.PARAMETER Location
    Optional. The Azure region where the Resource Group will be created. Defaults to 'westeurope'.

.PARAMETER Tags
    Optional. A hashtable of tags to assign to the Resource Group.

.PARAMETER Rollback
    Optional. If specified, the script will not delete or modify the Resource Group.

.PARAMETER Force
    Optional. Skip confirmation prompt and proceed with operations immediately.

.EXAMPLE
    $rgParams = @{
        Name     = 'rg-my-resource-group'
        Location = 'westeurope'
        Tags     = @{
            'environment' = 'prd'
            'owner'       = 'e2egov'
        }
        Verbose  = $true
    }
    .\main.ps1 @rgParams

    Creates or updates the Resource Group 'rg-my-resource-group' in the 'westeurope' region with the specified tags.

.NOTES
    Does not perform actual resource group deletion despite the Remove-AzResourceGroup reference due to
    the current implementation focusing on creation and updating tags only.
#>
[CmdletBinding(SupportsShouldProcess)]
[OutputType([pscustomobject])]
param (
    [Parameter(Mandatory)]
    [string]$Name,

    [Parameter(Mandatory = $false)]
    [string]$Location = 'westeurope',

    [Parameter(Mandatory = $false)]
    [object]$Tags,

    [Parameter()]
    [switch]$Rollback,

    [Parameter()]
    [switch]$Force
)

begin {
    Write-Verbose ('[Enter]: .\src\res\shared\modules\resource-group\{0}' -f $MyInvocation.MyCommand.Name)
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
                if ($PSCmdlet.ShouldProcess("Call module 'Az.Resources' operation.", 'New-AzResourceGroup')) {
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
                    if ($PSCmdlet.ShouldProcess("Call module 'Az.Resources' operation.", 'Set-AzResourceGroup')) {
                        $rgSplat = @{
                            Name    = $Name
                            Tags    = $Tags
                            Verbose = $VerbosePreference
                        }

                        $rg = Set-AzResourceGroup @rgSplat -ErrorAction Stop
                    }
                } else {
                    Write-Verbose ("Exists. '/resourceGroup/{0}'" -f $rg.ResourceGroupName)
                }
            }
        }

        #endregion

        #region ROLLBACK

        if ($Rollback.IsPresent) {
            if ($null -eq $rg) {
                Write-Verbose ("Doesn't exist. '/resourceGroup/{0}'" -f $Name)
            } else {
                if ($PSCmdlet.ShouldProcess("None 'Az.Resources' operation.", 'Remove-AzResourceGroup')) {
                    Write-Verbose ("None. Will not remove '/resourceGroup/{0}'" -f $rg.ResourceGroupName)
                }
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
    Write-Verbose ('[Exit]: .\src\res\shared\modules\resource-group\{0}' -f $MyInvocation.MyCommand.Name)
}
