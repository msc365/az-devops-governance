[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
[OutputType([PSCustomObject])]
param (
    [Parameter()]
    [string]$CollectionUri = $env:DefaultAdoCollectionUri,

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
        $status = 'Unknown'

        $tmPaths = $null

        # Team Iteration Paths
        $tmPathsSplat = [ordered]@{
            CollectionUri = $CollectionUri
            ProjectName   = $Project.Name
            TeamName      = $Team.Name
        }
        $tmPaths = Get-AdoTeamIteration @tmPathsSplat -Verbose:$false

        #endregion

        #region DEPLOYMENTS

        if ($null -eq $tmPaths -or $tmPaths.Length -eq 0) {
            # Project iteration paths as default to add to team
            $prjPathsSplat = [ordered]@{
                CollectionUri  = $CollectionUri
                ProjectName    = $Project.Name
                StructureGroup = 'Iterations'
                Depth          = 2
            }
            $prjPaths = Get-AdoClassificationNode @prjPathsSplat -Verbose:$false

            if ($null -ne $prjPaths -and $prjPaths.hasChildren) {

                $tmPaths = @()
                foreach ($path in $prjPaths.children) {

                    # Add each project iteration path to team
                    $tmPathsSplat['IterationId'] = $path.identifier

                    if ($PSCmdlet.ShouldProcess($Team.Name, "Add iteration path: $($path.path) (ID: $($path.id))")) {

                        $tmPaths += (Add-AdoTeamIteration @tmPathsSplat -Confirm:$false -Verbose:$false)

                        $status = 'Succeeded'
                        Write-Verbose "[ADDED]: Iteration path '$($path.path)' (ID: $($path.id))"
                    } else {
                        $status = 'WouldAdd'
                        Write-Verbose "[WHATIF]: Call Add-AdoTeamIteration with parameters: $($tmPathsSplat | ConvertTo-Json -Depth 5)"
                    }
                }
            }
        } else {
            $status = 'NoChange'
            foreach ($path in $tmPaths) {
                Write-Verbose "[NOCHANGE]: $($path.name) (ID: $($path.id))"
            }
        }

        #endregion

        #region OUTPUTS

        $tmPaths | Select-Object -ExcludeProperty collectionUri, projectName, teamName -Property *,
        @{Name = 'teamName'; Expression = { $Team.Name } },
        @{Name = 'projectName'; Expression = { $Project.Name } },
        @{Name = 'collectionUri'; Expression = { $CollectionUri } },
        @{Name = 'status'; Expression = { $status } }

        #endregion

    } catch {
        throw $_
    }
}

end {
    Write-Verbose ("[Exit]: ./modules/$($MyInvocation.MyCommand.Name)")
}














