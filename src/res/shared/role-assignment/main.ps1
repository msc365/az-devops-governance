#Requires -Version 7.0
<#PSScriptInfo
    .VERSION 0.1.0

    .GUID 8c4a3de2-9f7b-4c5e-a1d3-5e8b7f9c2a4d

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
    Manage Azure Role Assignments with Desired State Configuration.

.DESCRIPTION
    This script manages Azure Role Assignments using a desired state configuration approach.
    It compares the current state of role assignments against the desired state and:

    - Creates missing role assignments
    - Removes extra role assignments (when Enforce is enabled)
    - Keeps existing assignments that match the desired state

    This ensures idempotent deployments and prevents configuration drift.

.PARAMETER ObjectId
    Required. The Object ID of the principal (user, group, or service principal) to manage role assignments for.

.PARAMETER RoleAssignments
    Required. An array of PSCustomObjects defining the desired role assignments. Each object should contain: `roleDefinitionName`, `scope` See [Examples](#examples) for more information.

.PARAMETER EnforceDesiredState
    Optional. When specified, removes role assignments that exist but are not in the desired state. <br /> Without this flag, the script only ensures desired assignments exist (additive only).

.PARAMETER Rollback
    Optional. Switch to indicate if the operation should rollback (delete) the desired state. <br /> ⚠️ <b> WARNING! </b> <br /> Use with caution! Removing a role assignment is irreversible and may affect teams relying on it.

.PARAMETER Force
    Optional. Switch to force deletion without confirmation during rollback.

.EXAMPLE
    $RoleAssignments = @(
        @{
            roleDefinitionName = 'Contributor'
            scope              = '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-e2egov-prjHb72x9-tst-weu'
        },
        @{
            roleDefinitionName = 'Reader'
            scope              = '/subscriptions/00000000-0000-0000-0000-000000000000'
        }
    )

    $params = @{
        ObjectId                = '00000000-0000-0000-0000-000000000000'
        DesiredRoleAssignments  = $RoleAssignments
        EnforceDesiredState     = $true
        Verbose                 = $true
    }

    .\main2.ps1 @params

    Ensures the specified ObjectId has exactly the two role assignments defined, removing any others.

.EXAMPLE
    $params = @{
        ObjectId                = '00000000-0000-0000-0000-000000000000'
        DesiredRoleAssignments  = $RoleAssignments
        Rollback                = $true
        Force                   = $true
    }

    .\main2.ps1 @params

    Removes all role assignments defined in the desired state without confirmation.

.NOTES
    - When `EnforceDesiredState` is not specified, only missing assignments are created (safe mode).
    - When `EnforceDesiredState` is specified, extra assignments are removed (full enforcement).
#>
[CmdletBinding(SupportsShouldProcess)]
[OutputType([System.Collections.ArrayList])]
param (
    [Parameter(Mandatory)]
    [string]$ObjectId,

    [Parameter(Mandatory)]
    [AllowEmptyCollection()]
    [array]$RoleAssignments,

    [Parameter()]
    [switch]$EnforceDesiredState,

    [Parameter()]
    [switch]$Rollback,

    [Parameter()]
    [switch]$Force
)

begin {
    Write-Verbose "[Enter]: .\src\res\shared\role-assignment\$($MyInvocation.MyCommand.Name)"
}

process {
    try {
        $ErrorActionPreference = 'Stop'

        #region INITIALIZE

        # Variables
        $results = [System.Collections.ArrayList]::new()

        Write-Verbose "Retrieving current role assignments for ObjectId: $ObjectId"
        $currentRoleAssignments = Get-AzRoleAssignment -ObjectId $ObjectId -ErrorAction SilentlyContinue

        if ($null -eq $currentRoleAssignments) {
            $currentRoleAssignments = @()
        } elseif ($currentRoleAssignments -isnot [array]) {
            $currentRoleAssignments = @($currentRoleAssignments)
        }

        Write-Verbose "Found $($currentRoleAssignments.Count) current role assignment(s)"

        #endregion

        #region COMPARE

        # Filter current assignments to only those in managed scopes
        $managedScopes = $RoleAssignments.scope | Select-Object -Unique

        $currentManagedAssignments = $currentRoleAssignments | Where-Object {
            $_.Scope -in $managedScopes
        }

        Write-Verbose "Filtering to $($currentManagedAssignments.Count) assignment(s) in managed scopes"

        # Determine assignments to create (in desired but not in current)
        $assignmentsToCreate = @()
        foreach ($desired in $RoleAssignments) {

            $exists = $currentManagedAssignments | Where-Object {
                $_.RoleDefinitionName -eq $desired.roleDefinitionName -and
                $_.Scope -eq $desired.scope
            }

            if (-not $exists) {
                $assignmentsToCreate += $desired
                Write-Verbose "To Create: $($desired.roleDefinitionName) at $($desired.scope)"

            } else {
                Write-Verbose "Exists: $($desired.roleDefinitionName) at $($desired.scope)"
            }
        }

        # Determine assignments to remove (in current but not in desired)
        $assignmentsToRemove = @()
        if ($EnforceDesiredState.IsPresent -or $Rollback.IsPresent) {
            foreach ($current in $currentManagedAssignments) {

                $isDesired = $RoleAssignments | Where-Object {
                    $_.roleDefinitionName -eq $current.RoleDefinitionName -and
                    $_.scope -eq $current.Scope
                }

                if (-not $isDesired) {
                    $assignmentsToRemove += $current
                    Write-Verbose "To Remove: $($current.RoleDefinitionName) at $($current.Scope)"
                }
            }
        }

        #endregion

        #region DEPLOYMENT

        if (-not $Rollback.IsPresent) {
            foreach ($assignment in $assignmentsToCreate) {
                if ($PSCmdlet.ShouldProcess("roleAssignment/$($assignment.roleDefinitionName)/$($ObjectId)", 'Create')) {

                    Write-Verbose "Creating role assignment: $($assignment.roleDefinitionName) at $($assignment.scope)"

                    $raSplat = @{
                        ObjectId           = $ObjectId
                        RoleDefinitionName = $assignment.roleDefinitionName
                        Scope              = $assignment.scope
                        Verbose            = $VerbosePreference
                    }

                    $ra = New-AzRoleAssignment @raSplat -ErrorAction Stop
                    [void]$results.Add($ra)

                    Write-Verbose "Created: 'roleAssignment/$($ra.RoleDefinitionName)/$($ra.DisplayName)'"
                }
            }

            if ($EnforceDesiredState.IsPresent) {
                foreach ($assignment in $assignmentsToRemove) {
                    if ($PSCmdlet.ShouldProcess("roleAssignment/$($assignment.RoleDefinitionName)/$($assignment.DisplayName)", 'Delete')) {
                        if (-not $Force.IsPresent) {
                            $prompt = @(
                                "Enforcing desired state will delete 'roleAssignment/$($assignment.RoleDefinitionName)/$($assignment.DisplayName)'."
                                'This assignment is not in the desired configuration.'
                                "Do you want to continue? 'Yes [Y]' 'No [N]'"
                            ) -join "`n"

                            $result = Read-Host -Prompt $prompt
                            $result = $result.ToLower()

                            if ($result -ne 'y' -and $result -ne 'yes') {
                                Write-Warning 'Operation cancelled by user'
                                continue
                            }
                        }

                        Write-Verbose "Removing undesired role assignment: $($assignment.RoleDefinitionName) at $($assignment.Scope)"

                        Remove-AzRoleAssignment -InputObject $assignment -ErrorAction Stop | Out-Null
                        Write-Verbose "Deleted: 'roleAssignment/$($assignment.RoleDefinitionName)/$($assignment.DisplayName)'"
                    }
                }
            }

            # Add existing assignments that match desired state to results
            foreach ($desired in $RoleAssignments) {
                $existing = $currentManagedAssignments | Where-Object {
                    $_.RoleDefinitionName -eq $desired.roleDefinitionName -and
                    $_.Scope -eq $desired.scope
                }

                if ($existing -and $existing -notin $results) {
                    [void]$results.Add($existing)
                }
            }
        }

        #endregion

        #region ROLLBACK

        if ($Rollback.IsPresent) {
            # Remove all assignments in desired state
            foreach ($desired in $RoleAssignments) {
                $existing = $currentManagedAssignments | Where-Object {
                    $_.RoleDefinitionName -eq $desired.roleDefinitionName -and
                    $_.Scope -eq $desired.scope
                }

                if ($existing) {
                    if ($PSCmdlet.ShouldProcess("roleAssignment/$($existing.RoleDefinitionName)/$($existing.DisplayName)", 'Delete')) {
                        if (-not $Force.IsPresent) {
                            $prompt = @(
                                "This will delete 'roleAssignment/$($existing.RoleDefinitionName)/$($existing.DisplayName)'."
                                "Do you want to continue? 'Yes [Y]' 'No [N]'"
                            ) -join "`n"

                            $result = Read-Host -Prompt $prompt
                            $result = $result.ToLower()

                            if ($result -ne 'y' -and $result -ne 'yes') {
                                Write-Warning 'Operation cancelled by user'
                                continue
                            }
                        }

                        Write-Verbose "Rolling back role assignment: $($existing.RoleDefinitionName) at $($existing.Scope)"
                        $removed = Remove-AzRoleAssignment -InputObject $existing -ErrorAction Stop
                        [void]$results.Add($removed)

                        Write-Verbose "Deleted: 'roleAssignment/$($existing.RoleDefinitionName)/$($existing.DisplayName)'"
                    }
                } else {
                    Write-Warning "Doesn't exist: 'roleAssignment/$($desired.roleDefinitionName)' at scope '$($desired.scope)'"
                }
            }
        }

        #endregion

        #region OUTPUT

        Write-Verbose "Operation completed. Processed $($results.Count) role assignment(s)"
        return $results

        #endregion

    } catch {
        throw $_
    }
}

end {
    Write-Verbose "[Exit]: .\src\res\shared\role-assignment\$($MyInvocation.MyCommand.Name)"
}
