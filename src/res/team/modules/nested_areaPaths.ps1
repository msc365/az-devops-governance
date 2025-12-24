<#
.SYNOPSIS
    Configures area paths for a given Azure DevOps team.

.DESCRIPTION
    This script retrieves the current area paths for the specified team and creates a new area path for the team if it does not exist.
    It also updates the team's default area path if it is not set to the newly created area path.

.PARAMETER Project
    Required. The Azure DevOps project object.

.PARAMETER Team
    Required. The Azure DevOps team object.

.EXAMPLE
    $project = Get-AdoProject -ProjectId 'e2egov-prjHb72x9'
    $team = Get-AdoTeam -ProjectId $project.Id -TeamId 'Default Team'

    .\modules\nested_areaPaths.ps1 -Project $project -Team $team

    This example retrieves a project and team, and applies area paths to the team using the script.
#>
[CmdletBinding(SupportsShouldProcess)]
[OutputType([PSCustomObject])]
param (
    [Parameter(Mandatory)]
    [object]$Project,

    [Parameter(Mandatory)]
    [object]$Team,

    [Parameter()]
    [switch]$Rollback,

    [Parameter()]
    [switch]$Force
)

begin {
    Write-Verbose ("[Enter]: .\$($MyInvocation.MyCommand.Name)")
}

process {
    try {
        $ErrorActionPreference = 'Stop'

        #region INITIALIZE

        # Variables
        $status = 'NoChange'

        #endregion

        #region DEPLOYMENTS

        if (-not $Rollback.IsPresent) {
            # Team area path
            $fieldValue = Get-AdoTeamFieldValue -ProjectId $Project.Id -Team $Team.Id -ErrorAction Stop

            if ($null -eq $fieldValue.DefaultValue) {
                if ($PSCmdlet.ShouldProcess("team\areaPath\$($Project.Name)\$($Team.Name)", 'Set')) {

                    Write-Debug "Setting: team\areaPath\$($Project.Name)\$($Team.Name)"

                    $defaultValue = "$($Project.Name)\$($Team.Name)"
                    $values = @(
                        @{
                            value           = $defaultValue
                            includeChildren = $false
                        }
                    )

                    $teamFieldSplat = @{
                        ProjectId    = $Project.Id
                        Team         = $Team.Id
                        DefaultValue = $defaultValue
                        Values       = $values
                        Verbose      = $VerbosePreference
                    }

                    $fieldValue = Set-AdoTeamFieldValue @teamFieldSplat -ErrorAction Stop
                    $status = 'Succeeded'

                    Write-Verbose "Set: team\areaPath\$($Project.Name)\$($Team.Name)"
                }
            } else {
                Write-Verbose "NoChange: team\areaPath\$($Project.Name)\$($Team.Name)"
            }
        }

        #endregion

        #region OUTPUTS

        $output = [PSCustomObject]@{
            ProjectId    = $Project.Id
            TeamId       = $Team.Id
            DefaultValue = $fieldValue.DefaultValue
            Values       = $fieldValue.Values | ForEach-Object { $_ | Select-Object -Property * }
            Status       = $status
        }

        return $output

        #endregion

    } catch {
        throw $_
    }
}

end {
    Write-Verbose ("[Exit]: .\$($MyInvocation.MyCommand.Name)")
}
