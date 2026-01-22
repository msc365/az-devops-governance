<#
.SYNOPSIS
    Configures nested team settings for a given Azure DevOps team.

.DESCRIPTION
    This script retrieves the default team settings for the specified project and merges them with the provided team settings.
    It only applies changes if there are differences between the current settings and the provided settings.

.PARAMETER Project
    Required. The Azure DevOps project object.

.PARAMETER Team
    Required. The Azure DevOps team object.

.PARAMETER TeamSettings
    Required. A hashtable of team settings to apply.

.EXAMPLE
    $project = Get-AdoProject -Project 'e2egov-prjHb72x9'

    $team = Get-AdoTeam -Project $project.Id -TeamId 'Default Team'

    $teamSettings = @{
        backlogVisibilities = @{
            "Microsoft.EpicCategory" = $false
            "Microsoft.FeatureCategory" = $true
            "Microsoft.RequirementCategory" = $true
        }
        bugsBehavior = "asRequirements"
        defaultIterationMacro = "@currentIteration"
        workingDays = @(
            "monday",
            "tuesday",
            "wednesday",
            "thursday",
            "friday"
        )
    }

    .\modules\nested_teamSettings.ps1 -Project $project -Team $team -TeamSettings $teamSettings

    This example retrieves a project and team, defines new team settings, and applies them using the script.
#>
[CmdletBinding(SupportsShouldProcess)]
[OutputType([PSCustomObject])]
param (
    [Parameter(Mandatory)]
    [object]$Project,

    [Parameter(Mandatory)]
    [object]$Team,

    [Parameter(Mandatory)]
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

        # Team settings
        Write-Verbose 'Processing: team\teamSettings'
        $settings = Get-AdoTeamSettings -Project $Project.Id -TeamId $Team.Id -ErrorAction Stop

        if ($settings.backlogIteration.id -eq '00000000-0000-0000-0000-000000000000') {
            Write-Debug 'Getting: Default team settings for backlogIteration restoration.'

            $defaultSettings = Get-AdoTeamSettings -Project $Project.Id -TeamId $Project.DefaultTeam.Id -ErrorAction Stop
        }

        # Prepare current settings as hashtable
        $currentSettings = [hashtable]@{
            backlogIteration    = $settings.backlogIteration.id
            backlogVisibilities = ($settings.backlogVisibilities | ConvertTo-Json -Depth 5 | ConvertFrom-Json -AsHashtable)
            bugsBehavior        = $settings.bugsBehavior
            workingDays         = $settings.workingDays
        }
        if ($null -ne $settings.defaultIterationMacro) {
            $currentSettings['defaultIterationMacro'] = $settings.defaultIterationMacro
        } else {
            $currentSettings['defaultIteration'] = $settings.defaultIteration.id
        }

        # Process provided team settings
        $mergedSettings = @{}
        foreach ($key in $currentSettings.Keys) {
            switch ($key) {
                'backlogVisibilities' {
                    # Merge backlogVisibilities as hashtable
                    $mergedVisibilities = $currentSettings[$key].Clone()
                    foreach ($visibilityKey in $TeamSettings[$key].Keys) {
                        $mergedVisibilities[$visibilityKey] = $TeamSettings[$key][$visibilityKey]

                        if ($mergedVisibilities[$visibilityKey] -ne $TeamSettings[$key][$visibilityKey]) {
                            $setBacklogVisibilities = $true

                            Write-Verbose "- Updated : $key -> $visibilityKey\$($TeamSettings[$key][$visibilityKey])"
                        }
                    }

                    # Only update if different
                    if ($setBacklogVisibilities) {
                        $mergedSettings[$key] = $mergedVisibilities
                    } else {
                        Write-Verbose "- NoChange: $key"
                    }
                }
                'workingDays' {
                    # Merge workingDays array
                    $mergedDays = $currentSettings[$key] | Select-Object -Unique

                    # Add missing working days from $TeamSettings
                    foreach ($day in $TeamSettings[$key]) {
                        if (-not ($mergedDays -contains $day)) {
                            $mergedDays += $day
                            $setWorkingDays = $true
                        }
                    }

                    # Remove extra working days not in $TeamSettings
                    if ($null -ne $TeamSettings[$key]) {
                        foreach ($day in $mergedDays.Clone()) {
                            if (-not ($TeamSettings[$key] -contains $day)) {
                                $mergedDays = $mergedDays | Where-Object { $_ -ne $day }
                                $setWorkingDays = $true
                            }

                        }
                    }

                    if ($setWorkingDays) {
                        $mergedSettings[$key] = $mergedDays
                        Write-Verbose "- Updated : $key -> $($mergedDays -join ', ')"
                    } else {
                        Write-Verbose "- NoChange: $key"
                    }
                }
                'backlogIteration' {
                    # Only update if different
                    if ($null -eq $TeamSettings -or $null -eq $TeamSettings[$key] -or ($currentSettings[$key] -ne $TeamSettings[$key])) {

                        if ($null -eq $TeamSettings[$key] -and ($currentSettings[$key] -eq '00000000-0000-0000-0000-000000000000')) {
                            # Restore to default backlog iteration
                            $mergedSettings[$key] = $defaultSettings.backlogIteration.id
                            $setBacklogIteration = $true

                            Write-Verbose "- Restored: $key -> $($mergedSettings[$key])"

                        } elseif ($null -ne $TeamSettings[$key]) {
                            # Update to provided backlog iteration
                            $mergedSettings[$key] = $TeamSettings[$key]
                            $setBacklogIteration = $true

                            Write-Verbose "- Updated : $key -> $($mergedSettings[$key])"
                        } else {
                            Write-Verbose "- NoChange: $key"
                        }
                    }

                }
                default {
                    # Only update if different
                    if ($null -ne $TeamSettings[$key] -and ($currentSettings[$key] -ne $TeamSettings[$key])) {
                        $mergedSettings[$key] = $TeamSettings[$key]
                        $setDefault = $true

                        Write-Verbose "- Updated : $key -> $($mergedSettings[$key])"
                    } else {
                        Write-Verbose "- NoChange: $key"
                    }
                }
            }
        }

        #endregion

        #region DEPLOYMENTS

        if ($setDefault -or $setBacklogIteration -or $setWorkingDays -or $setBacklogVisibilities) {
            if ($PSCmdlet.ShouldProcess("teamSettings\$($Team.Name)", 'Update')) {

                Write-Debug "Updating: teamSettings\$($Team.Name)"

                $settingsSplat = @{
                    Project      = $Project.Id
                    TeamId       = $Team.Id
                    TeamSettings = ($mergedSettings | ConvertTo-Json -Depth 5 -Compress)
                    Verbose      = $VerbosePreference
                }

                $settings = Set-AdoTeamSettings @settingsSplat -ErrorAction Stop
                $status = 'Succeeded'

                Write-Verbose "Updated: teamSettings\$($Team.Name) -> $($settings | Select-Object backlogIteration,
                    bugsBehavior, workingDays, backlogVisibilities,
                    defaultIteration, defaultIterationMacro | ConvertTo-Json -Depth 5)"
            }
        }

        #endregion

        #region OUTPUTS

        if (-not $WhatIfPreference) {
            $output = [PSCustomObject]@{
                Project      = $Project.Id
                TeamId       = $Team.Id
                TeamSettings = $settings
                Status       = $status
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
