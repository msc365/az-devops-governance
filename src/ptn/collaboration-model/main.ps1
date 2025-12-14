<#PSScriptInfo
    .VERSION 0.1.0

    .GUID bf313957-a1c0-4ba4-8dc6-b5848781ed6c

    .AUTHOR Martin Swinkels

    .COMPANYNAME MSc365.eu

    .COPYRIGHT 2025 (c) MSc365.eu, Martin Swinkels

    .TAGS 'Azure', 'Security', 'Governance', 'DevOps', 'Platform', 'RBAC'

    .LICENSEURI https://github.com/msc365/az-devops-governance/blob/main/LICENSE

    .PROJECTURI https://github.com/msc365/az-devops-governance

    .ICONURI https://raw.githubusercontent.com/msc365/az-devops-governance/main/.assets/icon.png

    .EXTERNALMODULEDEPENDENCIES Az.Accounts, Azure.DevOps.PSModule
#>
[CmdletBinding()]
param (
    [Parameter()]
    [object[]]$Projects,

    [Parameter()]
    [object[]]$Teams,

    [Parameter()]
    [object[]]$Environments,

    [Parameter()]
    [switch]$Remove,

    [Parameter()]
    [switch]$Force
)

begin {

    if ($null -eq (Get-AzContext)) {
        Write-Error 'No Azure context found. Please login using Connect-AzAccount.'
        return
    }

    # Import required modules
    $modules = @(
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

        Write-Verbose 'Processing projects...'

        $Projects | ForEach-Object -Process {
            # Prepare splat for project deployment
            $projectSplat = $_
            # Add Remove switch
            $projectSplat['Remove'] = $Remove.IsPresent
            # Add Force switch
            $projectSplat['Force'] = $Force.IsPresent

            Write-Verbose ("Processing project '{0}'." -f $_.name)
            & (Join-Path $PSScriptRoot -ChildPath '..\..\res\project\main.ps1') @projectSplat -Verbose:$VerbosePreference
        }

        if (-not $Remove.IsPresent) {
            Write-Verbose 'Processing teams...'

            $Teams | ForEach-Object -Process {
                # Prepare splat for team deployment
                $teamSplat = $_

                Write-Verbose ("Processing team '{0}'." -f $_.teamId)
                & (Join-Path $PSScriptRoot -ChildPath '..\..\res\team\main.ps1') @teamSplat -Verbose:$VerbosePreference
            }
        }

        Write-Verbose 'Processing environments...'
        $Environments | ForEach-Object -Process {
            # Prepare splat for environment deployment
            $environmentSplat = $_
            # Add Remove switch
            $environmentSplat['Remove'] = $Remove.IsPresent
            # Add Force switch
            $environmentSplat['Force'] = $Force.IsPresent

            Write-Verbose ("Processing environment '{0}'." -f $_.Name)
            & (Join-Path $PSScriptRoot -ChildPath '..\..\res\environment\main.ps1') @environmentSplat -Verbose:$VerbosePreference
        }

    } catch {
        throw $_
    }
}

end {
    Write-Verbose ('[Exit]: .\{0}' -f $MyInvocation.MyCommand.Name)
}
