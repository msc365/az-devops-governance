
<#
.SYNOPSIS
    Configures iteration paths for a given Azure DevOps team.

.DESCRIPTION
    This script retrieves the current iteration paths for the specified team and adds any missing iteration paths from the project.
    It only applies changes if there are iteration paths in the project that are not already assigned to the team.
.PARAMETER Project
    Required. The Azure DevOps project object.

.PARAMETER Team
    Required. The Azure DevOps team object.

.EXAMPLE
    $project = Get-AdoProject -Project 'e2egov-prjHb72x9'
    $team = Get-AdoTeam -Project $project.Id -TeamId 'Default Team'

    .\modules\nested_iterationPaths.ps1 -Project $project -Team $team

    This example retrieves a project and team, and applies iteration paths to the team using the script.
#>
[CmdletBinding(SupportsShouldProcess)]
[OutputType([PSCustomObject])]
param (
    [Parameter(Mandatory)]
    [object]$Project,

    [Parameter(Mandatory)]
    [object]$Team
)

begin {
    Write-Verbose ("[Enter]: ./modules/$($MyInvocation.MyCommand.Name)")
}

process {
    try {
        $ErrorActionPreference = 'Stop'

        #region INITIALIZE

        # Variables
        $status = 'NoChange'

        # Team Iterations
        $teamIterationSplat = @{
            Project = $Project.Id
            TeamId  = $Team.Name
        }

        Write-Verbose 'Processing: team\iterationPaths'

        $teamIterations = Get-AdoTeamIterationList @teamIterationSplat -ErrorAction Stop

        #endregion

        #region DEPLOYMENTS

        if ($null -eq $teamIterations -or $teamIterations.Count -eq 0) {
            # Get project iterations as default to add to team
            $projectIteration = Get-AdoTeamIterationList -Project $Project.Id -ErrorAction Stop

            if ($null -ne $projectIteration.Value) {

                $projectIteration.Value | ForEach-Object -Process {
                    if ($PSCmdlet.ShouldProcess("team\iterationPath\$($_.Path)", 'Set')) {

                        Write-Debug "Setting: team\iterationPath\$($_.Path)"

                        $setIterationSplat = @{
                            Project     = $Project.Id
                            TeamId      = $Team.Name
                            IterationId = $_.Id
                            Verbose     = $VerbosePreference
                        }

                        Set-AdoTeamIteration @setIterationSplat | Out-Null
                        $script:status = 'Succeeded'

                        Write-Verbose "- Set: $($_.Path)"
                    }
                }
            }
        } else {
            $teamIterations.Value | ForEach-Object -Process {
                Write-Verbose "- NoChange: $($_.Path)"
            }
        }

        #endregion

        #region OUTPUTS

        if (-not $WhatIfPreference) {
            if ($status -eq 'Succeeded') {
                # Refresh team iterations
                $teamIterations = Get-AdoTeamIterationList @teamIterationSplat -ErrorAction Stop
            }

            $output = [PSCustomObject]@{
                Project        = $Project.Id
                TeamId         = $Team.Id
                TeamIterations = $teamIterations
                Status         = $status
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
    Write-Verbose ("[Exit]: ./modules/$($MyInvocation.MyCommand.Name)")
}

