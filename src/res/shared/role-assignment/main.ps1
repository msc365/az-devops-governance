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

    - Creates missing role assignments (additive only)
    - Keeps existing assignments that match the desired state
    - To remove assignments: use -Rollback with the same assignments, then deploy new desired state

    This ensures safe, explicit operations and prevents accidental deletion of role assignments.

.PARAMETER ObjectId
    Required. The Object ID of the principal (user, group, or service principal) to manage role assignments for.

.PARAMETER RoleAssignments
    Required. An array of hashtables defining the desired role assignments. Each object should contain:
    - roleDefinitionName: The name of the role (e.g.: 'Contributor', 'Reader')
    - scope: The resource scope (e.g.: subscription or resource group)

.PARAMETER Rollback
    Optional. Switch to indicate if the operation should rollback (delete) the desired state.

.EXAMPLE
    $roleAssignments = @(
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
        ObjectId        = '00000000-0000-0000-0000-000000000000'
        RoleAssignments = $roleAssignments
        Verbose         = $true
    }

    .\main.ps1 @params

    Ensures the specified ObjectId has the two role assignments defined. Existing assignments are preserved.

.EXAMPLE
    $params = @{
        ObjectId        = '00000000-0000-0000-0000-000000000000'
        RoleAssignments = $roleAssignments
        Rollback        = $true
    }

    .\main.ps1 @params -Confirm:$false

    Removes all role assignments defined in the desired state without confirmation prompts.

.NOTES
    - Deployment mode is always additive - only creates missing assignments, never removes.
    - To remove assignments: first rollback with same RoleAssignments, then deploy new desired state.
    - Only manages assignments where ObjectId + Scope + Role match the RoleAssignments parameter.
    - Uses `SupportsShouldProcess` for confirmation prompts on destructive operations (Rollback).
    - Script is scoped to specific `-ObjectId` and assignments in `-RoleAssignments` only.
    - Does not affect other principals or assignments outside the defined scope.
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
[OutputType([PSCustomObject[]])]
param (
    [Parameter(Mandatory)]
    [string]$ObjectId,

    [Parameter(Mandatory)]
    [AllowEmptyCollection()]
    [array]$RoleAssignments,

    [Parameter()]
    [switch]$Rollback
)

begin {
    Write-Verbose "[Enter]: ./src/res/shared/role-assignment/$($MyInvocation.MyCommand.Name)"
}

process {
    try {
        $ErrorActionPreference = 'Stop'

        $RESOURCE_TYPE = 'RoleAssignment'

        #region HELPER

        function New-RoleAssignmentResult {
            param(
                [Parameter(Mandatory)]
                [object]$Assignment,

                [Parameter(Mandatory)]
                [string]$Status
            )

            [PSCustomObject]@{
                objectId           = $Assignment.ObjectId
                displayName        = $Assignment.DisplayName
                roleDefinitionName = $Assignment.RoleDefinitionName
                scope              = $Assignment.Scope
                roleAssignmentId   = $Assignment.RoleAssignmentId
                resourceType       = $RESOURCE_TYPE
                status             = $Status
            }
        }

        #endregion

        #region VALIDATE

        # Validate ObjectId format
        if (-not [System.Guid]::TryParse($ObjectId, [ref][System.Guid]::Empty)) {
            throw "Invalid ObjectId format: '$ObjectId'. Expected a valid GUID (e.g.: '00000000-0000-0000-0000-000000000000')"
        }

        # Validate RoleAssignments structure and scope formats
        foreach ($assignment in $RoleAssignments) {
            # Check required properties
            if ([string]::IsNullOrWhiteSpace($assignment.roleDefinitionName)) {
                throw "Invalid role assignment: 'roleDefinitionName' property is required and cannot be empty. Assignment: $($assignment | ConvertTo-Json -Compress)"
            }
            if ([string]::IsNullOrWhiteSpace($assignment.scope)) {
                throw "Invalid role assignment: 'scope' property is required and cannot be empty. Assignment: $($assignment | ConvertTo-Json -Compress)"
            }

            # Validate scope format - supports Management Group, Subscription, and Resource Group
            $isManagementGroup = $assignment.scope -match '^/providers/Microsoft\.Management/managementGroups/[\w\-\.]+$'
            $isSubscription = $assignment.scope -match '^/subscriptions/[a-f0-9-]{36}$'
            $isResourceGroup = $assignment.scope -match '^/subscriptions/[a-f0-9-]{36}/resourceGroups/[\w\-\.\(\)]+$'

            if (-not ($isManagementGroup -or $isSubscription -or $isResourceGroup)) {
                $msg = @(
                    "Invalid scope format: '$($assignment.scope)'."
                    'Expected one of:'
                    '- Management Group: /providers/Microsoft.Management/managementGroups/{groupId}'
                    '- Subscription: /subscriptions/{guid}'
                    '- Resource Group: /subscriptions/{guid}/resourceGroups/{name}'
                ) -join "`n"
                throw $msg
            }
        }

        Write-Debug "Input validation passed ObjectId and $($RoleAssignments.Count) role assignments"

        #endregion

        #region INITIALIZE

        # Status tracking
        $results = @()

        # Note: Azure PowerShell doesn't support scope filtering in Get-AzRoleAssignment
        # All assignments for the ObjectId are retrieved, then filtered to managed scopes client-side
        Write-Debug "Retrieving current role assignments for ObjectId: $ObjectId"
        $existingRoleAssignments = @(Get-AzRoleAssignment -ObjectId $ObjectId -ErrorAction SilentlyContinue)

        Write-Verbose "Found $($existingRoleAssignments.Count) existing role assignment(s)"

        #endregion

        #region COMPARE

        # Always filter to managed scopes (assignments defined in RoleAssignments parameter)
        # Only manage assignments where ObjectId + Scope + Role match the desired state
        $managedScopes = $RoleAssignments.scope | Select-Object -Unique

        # Use hashtable for O(1) scope lookups
        $managedScopesLookup = @{}
        foreach ($scope in $managedScopes) {
            $managedScopesLookup[$scope.ToLowerInvariant()] = $true
        }

        $currentScopedAssignments = $existingRoleAssignments | Where-Object {
            $managedScopesLookup.ContainsKey($_.Scope.ToLowerInvariant())
        }

        $modeDescription = if ($Rollback.IsPresent) { 'Rollback' } else { 'Deployment' }
        Write-Debug "$modeDescription mode: evaluating $($currentScopedAssignments.Count) assignment(s) in managed scopes"

        # Build lookup dictionary for O(1) comparisons: "rolename|scope" -> assignment object
        $currentLookup = @{}
        foreach ($current in $currentScopedAssignments) {
            $key = "$($current.RoleDefinitionName)|$($current.Scope)".ToLowerInvariant()
            $currentLookup[$key] = $current
        }

        # Determine assignments to create (in desired but not in current) and track matches
        $assignmentsToCreate = @()
        $matchedAssignments = @{}

        foreach ($desired in $RoleAssignments) {
            $key = "$($desired.roleDefinitionName)|$($desired.scope)".ToLowerInvariant()

            if (-not $currentLookup.ContainsKey($key)) {
                if (-not $Rollback.IsPresent) {
                    $assignmentsToCreate += $desired
                    Write-Verbose "[TO CREATE] Role assignment: '$($desired.roleDefinitionName)' at scope: $($desired.scope)"
                }
            } else {
                $matchedAssignments[$key] = $currentLookup[$key]
                if ($Rollback.IsPresent) {
                    Write-Verbose "[TO REMOVE] Role assignment: '$($desired.roleDefinitionName)' at scope: $($desired.scope)"
                } else {
                    Write-Verbose "[NOCHANGE] Role assignment: '$($desired.roleDefinitionName)' at scope: $($desired.scope)"
                }
            }
        }

        #endregion

        #region DEPLOYMENTS

        if (-not $Rollback.IsPresent) {
            foreach ($assignment in $assignmentsToCreate) {
                $raSplat = @{
                    ObjectId           = $ObjectId
                    RoleDefinitionName = $assignment.roleDefinitionName
                    Scope              = $assignment.scope
                }

                if ($PSCmdlet.ShouldProcess($ObjectId, "Create role assignment: $($assignment.roleDefinitionName)")) {

                    $ra = New-AzRoleAssignment @raSplat -Verbose:$false -ErrorAction Stop

                    $resultObj = New-RoleAssignmentResult -Assignment $ra -Status 'Created'
                    $results += $resultObj

                    Write-Verbose "[CREATED] Role assignment: '$($ra.RoleDefinitionName)' for '$($ra.DisplayName)' at scope: $($ra.Scope)"
                } else {
                    # WhatIf mode: create placeholder result object
                    $whatIfAssignment = [PSCustomObject]@{
                        ObjectId           = $ObjectId
                        DisplayName        = '(WhatIf)'
                        RoleDefinitionName = $assignment.roleDefinitionName
                        Scope              = $assignment.scope
                        RoleAssignmentId   = '(WhatIf)'
                    }

                    $resultObj = New-RoleAssignmentResult -Assignment $whatIfAssignment -Status 'WouldCreate'
                    $results += $resultObj

                    Write-Verbose "[WHATIF] Call New-AzRoleAssignment with parameters: $($raSplat | ConvertTo-Json -Depth 5)"
                }
            }

            # Add existing assignments that match desired state to results (from cached matches)
            foreach ($matched in $matchedAssignments.Values) {
                $alreadyInResults = $results | Where-Object {
                    $_.roleAssignmentId -eq $matched.RoleAssignmentId
                }

                if (-not $alreadyInResults) {
                    $resultObj = New-RoleAssignmentResult -Assignment $matched -Status 'NoChange'
                    $results += $resultObj
                }
            }
        }

        #endregion

        #region ROLLBACK

        if ($Rollback.IsPresent) {
            # Remove all assignments in desired state (use lookup from comparison phase)
            foreach ($desired in $RoleAssignments) {
                $key = "$($desired.roleDefinitionName)|$($desired.scope)".ToLowerInvariant()
                $existing = $currentLookup[$key]

                if ($existing) {
                    if ($PSCmdlet.ShouldProcess($ObjectId, "Remove role assignment: $($existing.RoleDefinitionName)")) {

                        Remove-AzRoleAssignment -InputObject $existing -Confirm:$false -Verbose:$false -ErrorAction Stop | Out-Null

                        $resultObj = New-RoleAssignmentResult -Assignment $existing -Status 'Removed'
                        $results += $resultObj

                        Write-Verbose "[REMOVE] Role assignment: '$($existing.RoleDefinitionName)' for '$($existing.DisplayName)' at scope: $($existing.Scope)"
                    } else {

                        $resultObj = New-RoleAssignmentResult -Assignment $existing -Status 'WouldRemove'
                        $results += $resultObj

                        Write-Verbose "[WHATIF] Call Remove-AzRoleAssignment with parameters: $([ordered]@{
                            objectId = $existing.ObjectId
                            roleDefinitionName = $existing.RoleDefinitionName
                            scope = $existing.Scope
                        } | ConvertTo-Json -Depth 5)"
                    }
                } else {
                    Write-Warning "[NOTFOUND] Role assignment: '$($desired.roleDefinitionName)' at scope: $($desired.scope)"
                }
            }
        }

        #endregion

        #region OUTPUTS

        $results

        #endregion

    } catch {
        throw $_
    }
}

end {
    Write-Verbose "[Exit]: ./src/res/shared/role-assignment/$($MyInvocation.MyCommand.Name)"
}
