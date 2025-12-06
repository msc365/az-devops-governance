[CmdletBinding(SupportsShouldProcess)]
param (
    [Parameter(Mandatory)]
    [string]$Name,

    [Parameter(Mandatory)]
    [string]$Location,

    [Parameter(Mandatory = $false)]
    [object]$Tags,

    [Parameter()]
    [switch]$Remove,

    [Parameter()]
    [switch]$Force
)

begin {
    Write-Verbose ('Command : {0}' -f $MyInvocation.MyCommand.Name)
}

process {
    try {
        $ErrorActionPreference = 'Stop'

        $rg = Get-AzResourceGroup -Name $Name -ErrorAction SilentlyContinue

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
            $tagsDiff = $false
            foreach ($key in $Tags.Keys) {
                if (-not $rg.Tags.ContainsKey($key) -or $rg.Tags[$key] -ne $Tags[$key]) {
                    $tagsDiff = $true
                    break
                }
            }

            if ($tagsDiff) {
                if ($PSCmdlet.ShouldProcess("Call module 'Az.Resources' operation.", 'Set-AzResourceGroup')) {
                    $rgSplat = @{
                        Name    = $Name
                        Tags    = $Tags
                        Verbose = $VerbosePreference
                    }

                    $rg = Set-AzResourceGroup @rgSplat -ErrorAction Stop
                }
            }
        }

        return -not $WhatIfPreference ? $rg : $null

    } catch {
        throw $_
    }
}

end {
    Write-Verbose ('Exit : {0}' -f $MyInvocation.MyCommand.Name)
}
