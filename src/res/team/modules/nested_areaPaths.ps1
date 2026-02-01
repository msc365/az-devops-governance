[CmdletBinding(SupportsShouldProcess)]
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

    # Root area path
    $rapSplat = [ordered]@{
        CollectionUri  = $CollectionUri
        ProjectName    = $Project.Name
        StructureGroup = 'Areas'
        Depth          = 2
    }
    $rap = Get-AdoClassificationNode @rapSplat -ErrorAction SilentlyContinue

    if ($null -eq $rap) {
        throw "Root area path for project $($Project.Name) does not exist, cannot proceed."
    }
}

process {
    try {
        $ErrorActionPreference = 'Stop'

        #region INITIALIZE

        # Variables
        $status = 'Unknown'

        $tmfv, $ap = $null

        # Team area path, project-level
        if ($rap.HasChildren) {
            $ap = $rap.Children | Where-Object {
                $_.Name -eq $Team.Name
            }
        }

        # Team area path, team-level
        $tmfvSplat = [ordered]@{
            CollectionUri = $CollectionUri
            ProjectName   = $Project.Name
            TeamName      = $Team.Name
        }
        $tmfv = Get-AdoTeamFieldValue @tmfvSplat -Verbose:$false

        #endregion

        #region DEPLOYMENTS

        # Project area path
        if ($null -eq $ap) {
            $apSplat = [ordered]@{
                CollectionUri  = $CollectionUri
                ProjectName    = $Project.Name
                Name           = $Team.Name
                StructureGroup = 'Areas'
            }

            if ($PSCmdlet.ShouldProcess($Project.Name, "Create project area path: $($Project.Name)\$($Team.Name)")) {

                $ap = New-AdoClassificationNode @apSplat -Verbose:$false

                $status = 'Succeeded'
                Write-Verbose "[CREATED]: Project area path '$($ap.path)'"
            } else {
                $status = 'WouldCreate'
                Write-Verbose "[WHATIF]: Call New-AdoClassificationNode with parameters: $($apSplat | ConvertTo-Json -Depth 5)"
            }
        } else {
            $status = 'NoChange'
            Write-Verbose "[NOCHANGE]: Project area path '$($ap.path)'"
        }

        # Team area path
        if ($null -eq $tmfv -or $tmfv.DefaultValue -ne "$($Project.Name)\$($Team.Name)") {

            $defaultValue = "$($Project.Name)\$($Team.Name)"
            $values = @(
                [ordered]@{
                    value           = $defaultValue
                    includeChildren = $false
                }
            )
            $tmfvSplat['DefaultValue'] = $defaultValue
            $tmfvSplat['Values'] = $values

            if ($PSCmdlet.ShouldProcess($Team.Name, "Add team area path: $($Project.Name)\$($Team.Name)")) {

                if ($null -eq $ap) {
                    throw "Root area path '$($Project.Name)\$($Team.Name)' does not exist, cannot proceed."
                }

                $tmfv = Set-AdoTeamFieldValue @tmfvSplat -Confirm:$false -Verbose:$false

                $status = 'Succeeded'
                Write-Verbose "[ADDED]: Team area path '$($tmfv.defaultValue)'"
            } else {
                $status = 'WouldAdd'
                Write-Verbose "[WHATIF]: Call Set-AdoTeamFieldValue with parameters: $($tmfvSplat | ConvertTo-Json -Depth 5)"
            }
        } else {
            $status = 'NoChange'
            Write-Verbose "[NOCHANGE]: Team area path '$($tmfv.defaultValue)'."
        }

        #endregion

        #region OUTPUTS

        $tmfv | Select-Object -ExcludeProperty collectionUri, projectName, teamName -Property *,
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














