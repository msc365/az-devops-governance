[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
[OutputType([PSCustomObject])]
param (
    [Parameter()]
    [string]$CollectionUri = $env:DefaultAdoCollectionUri,

    [Parameter(Mandatory)]
    [object]$Project,

    [Parameter(Mandatory)]
    [object]$Team,

    [Parameter()]
    [object]$TeamSettings
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

        $ts = $null

        # Team settings
        $tsSplat = [ordered]@{
            CollectionUri = $CollectionUri
            ProjectName   = $Project.Name
            TeamId        = $Team.Id
        }
        $ts = Get-AdoTeamSettings @tsSplat -Verbose:$false

        if ($ts.backlogIteration.id -eq '00000000-0000-0000-0000-000000000000') {
            Write-Verbose 'Get default team settings for backlogIteration restoration.'

            $dtsSplat = [ordered]@{
                CollectionUri = $CollectionUri
                ProjectName   = $Project.Name
                TeamId        = $Project.DefaultTeam.Id
            }
            $defaultTeamSettings = Get-AdoTeamSettings @dtsSplat -Verbose:$false
        }

        # Prepare current settings as hashtable
        $currentTeamSettings = [hashtable]@{
            backlogIteration    = $ts.backlogIteration.id
            backlogVisibilities = ($ts.backlogVisibilities | ConvertTo-Json -Depth 5 | ConvertFrom-Json -AsHashtable)
            bugsBehavior        = $ts.bugsBehavior
            workingDays         = $ts.workingDays
        }
        if ($null -ne $ts.defaultIterationMacro) {
            $currentTeamSettings['defaultIterationMacro'] = $ts.defaultIterationMacro
        } else {
            $currentTeamSettings['defaultIteration'] = $ts.defaultIteration.id
        }

        # Process provided team settings
        $mergedTeamSettings = @{}
        $backlogIterationHasChanges, $backlogVisibilitiesHasChanges,
        $bugsBehaviorHasChanges, $defaultIterationHasChanges,
        $defaultIterationMacroHasChanges, $workingDaysHasChanges = $false

        foreach ($key in $currentTeamSettings.Keys) {
            switch ($key) {
                'backlogIteration' {
                    # Special case: always restore if backlog iteration is the zero GUID
                    if ($currentTeamSettings[$key] -eq '00000000-0000-0000-0000-000000000000') {
                        # Restore to default backlog iteration
                        $mergedTeamSettings[$key] = $defaultTeamSettings.backlogIteration.id
                        $backlogIterationHasChanges = $true
                        Write-Verbose "[RESTORED]: $key -> $($mergedTeamSettings[$key])"
                    }
                    # Only update if TeamSettings is provided and value is different
                    elseif ($null -ne $TeamSettings -and
                        $null -ne $TeamSettings[$key] -and
                        $currentTeamSettings[$key] -ne $TeamSettings[$key]) {
                        # Update to provided backlog iteration
                        $mergedTeamSettings[$key] = $TeamSettings[$key]
                        $backlogIterationHasChanges = $true
                        Write-Verbose "[UPDATED]: $key -> $($mergedTeamSettings[$key])"
                    } else {
                        Write-Verbose "[NOCHANGE]: $key"
                    }
                }
                'backlogVisibilities' {
                    # Only process if TeamSettings is provided and has this key
                    if ($null -ne $TeamSettings -and $null -ne $TeamSettings[$key]) {
                        $backlogVisibilitiesHasChanges = $false

                        # Merge backlogVisibilities as hashtable
                        $mergedBacklogVisibilities = $currentTeamSettings[$key].Clone()
                        foreach ($bvKey in $TeamSettings[$key].Keys) {
                            if ($mergedBacklogVisibilities[$bvKey] -ne $TeamSettings[$key][$bvKey]) {
                                $mergedBacklogVisibilities[$bvKey] = $TeamSettings[$key][$bvKey]
                                $backlogVisibilitiesHasChanges = $true
                                Write-Verbose "[UPDATED]: $key -> $bvKey\$($TeamSettings[$key][$bvKey])"
                            }
                        }

                        # Only update if different
                        if ($backlogVisibilitiesHasChanges) {
                            $mergedTeamSettings[$key] = $mergedBacklogVisibilities
                        } else {
                            Write-Verbose "[NOCHANGE]: $key"
                        }
                    } else {
                        Write-Verbose "[NOCHANGE]: $key"
                    }
                }
                'workingDays' {
                    # Only process if TeamSettings is provided and has this key
                    if ($null -ne $TeamSettings -and $null -ne $TeamSettings[$key]) {
                        $workingDaysHasChanges = $false

                        # Merge workingDays array
                        $mergedWorkingDays = $currentTeamSettings[$key] | Select-Object -Unique

                        # Add missing working days from $TeamSettings
                        foreach ($day in $TeamSettings[$key]) {
                            if (-not ($mergedWorkingDays -contains $day)) {
                                $mergedWorkingDays += $day
                                $workingDaysHasChanges = $true
                            }
                        }

                        # Remove extra working days not in $TeamSettings
                        foreach ($day in $mergedWorkingDays.Clone()) {
                            if (-not ($TeamSettings[$key] -contains $day)) {
                                $mergedWorkingDays = $mergedWorkingDays | Where-Object { $_ -ne $day }
                                $workingDaysHasChanges = $true
                            }
                        }

                        if ($workingDaysHasChanges) {
                            $mergedTeamSettings[$key] = $mergedWorkingDays
                            Write-Verbose "[UPDATED]: $key -> $($mergedWorkingDays -join ', ')"
                        } else {
                            Write-Verbose "[NOCHANGE]: $key"
                        }
                    } else {
                        Write-Verbose "[NOCHANGE]: $key"
                    }
                }

                default {
                    # Only update if TeamSettings is provided and value is different
                    if ($null -ne $TeamSettings -and
                        $null -ne $TeamSettings[$key] -and
                        $currentTeamSettings[$key] -ne $TeamSettings[$key]) {

                        $mergedTeamSettings[$key] = $TeamSettings[$key]

                        switch ($key) {
                            'bugsBehavior' { $bugsBehaviorHasChanges = $true }
                            'defaultIteration' { $defaultIterationHasChanges = $true }
                            'defaultIterationMacro' { $defaultIterationMacroHasChanges = $true }
                        }

                        Write-Verbose "[UPDATED]: $key -> $($mergedTeamSettings[$key])"
                    } else {
                        Write-Verbose "[NOCHANGE]: $key"
                    }
                }
            }
        }

        #endregion

        #region DEPLOYMENTS

        if ($backlogIterationHasChanges -or $backlogVisibilitiesHasChanges -or
            $bugsBehaviorHasChanges -or $defaultIterationHasChanges -or
            $defaultIterationMacroHasChanges -or $workingDaysHasChanges) {

            # Only update changed team settings
            if ($backlogIterationHasChanges) {
                $tsSplat['BacklogIteration'] = $mergedTeamSettings['backlogIteration']
            }
            if ($backlogVisibilitiesHasChanges) {
                $tsSplat['BacklogVisibilities'] = $mergedTeamSettings['backlogVisibilities']
            }
            if ($bugsBehaviorHasChanges) {
                $tsSplat['BugsBehavior'] = $mergedTeamSettings['bugsBehavior']
            }
            if ($defaultIterationHasChanges) {
                $tsSplat['DefaultIteration'] = $mergedTeamSettings['defaultIteration']
            }
            if ($defaultIterationMacroHasChanges) {
                $tsSplat['DefaultIterationMacro'] = $mergedTeamSettings['defaultIterationMacro']
            }
            if ($workingDaysHasChanges) {
                $tsSplat['WorkingDays'] = $mergedTeamSettings['workingDays']
            }

            if ($PSCmdlet.ShouldProcess($($Team.Name), 'Update team settings')) {

                $ts = Set-AdoTeamSettings @tsSplat -Confirm:$false

                $status = 'Succeeded'
                Write-Verbose "[UPDATED]: Team settings '$($Team.Name)' (ID: $($Team.Id))"
            } else {
                $status = 'WouldUpdate'
                Write-Verbose "[WHATIF]: Call Set-AdoTeamSettings with parameters: $($tsSplat | ConvertTo-Json -Depth 5)"
            }
        } else {
            $status = 'NoChange'
            Write-Verbose "[NOCHANGE]: Team settings '$($Team.Name)' (ID: $($Team.Id))"
        }

        #endregion

        #region OUTPUTS

        $ts | Select-Object -ExcludeProperty collectionUri, projectName -Property *,
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













