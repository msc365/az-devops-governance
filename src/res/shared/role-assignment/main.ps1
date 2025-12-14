<#PSScriptInfo
    .VERSION 0.1.0

    .GUID 3faa2ff1-d06e-48d7-a03b-ab84299e0039

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
    Create Azure Role Assignments.

.DESCRIPTION
    This script creates new Azure Role Assignments or removes existing ones based on the provided parameters.

.PARAMETER ObjectId
    Required. The Object ID of the principal (user, group, or service principal) to assign the role to.

.PARAMETER roleDefinitionName
    Required. The name of the role definition to assign (e.g., 'Owner', 'Contributor', 'Reader', 'CustomRole').

.PARAMETER scope
    Required. The scope at which the role assignment applies (e.g., subscription, resource group, resource).

.PARAMETER Rollback
    Optional. If specified, the script will remove the role assignment instead of creating it.

.PARAMETER Force
    Optional. If specified during rollback, the script will not prompt for confirmation before removing the role assignment.

.EXAMPLE
    $roleAssignmentParams = @{
        ObjectId           = '00000000-0000-0000-0000-000000000000'
        roleDefinitionName = 'Contributor'
        scope              = '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/MyResourceGroup'
        Verbose            = $true
    }

    .\main.ps1 @roleAssignmentParams

    Creates a Contributor role assignment for the specified ObjectId at the given resource group scope.

.EXAMPLE
    $roleAssignmentParams = @{
        ObjectId           = '00000000-0000-0000-0000-000000000000'
        roleDefinitionName = 'Contributor'
        scope              = '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/MyResourceGroup'
        Rollback           = $true
        Force              = $true
    }

    .\main.ps1 @roleAssignmentParams

    Removes the Contributor role assignment for the specified ObjectId at the given resource group scope without confirmation.
#>
[CmdletBinding(SupportsShouldProcess)]
[OutputType([pscustomobject])]
param (
    [Parameter(Mandatory)]
    [string]$ObjectId,

    [Parameter(Mandatory)]
    [string]$roleDefinitionName,

    [Parameter(Mandatory)]
    [string]$scope,

    [Parameter()]
    [switch]$Rollback,

    [Parameter()]
    [switch]$Force

)

begin {
    Write-Verbose ('[Enter]: .\src\res\shared\role-assignment\{0}' -f $MyInvocation.MyCommand.Name)
}

process {
    try {
        $ErrorActionPreference = 'Stop'

        #region INITIALIZE

        # Variables
        $ra = $null

        # Role Assignment
        $ra = Get-AzRoleAssignment -Scope $Scope | Where-Object {
            $_.ObjectId -eq $ObjectId -and
            $_.RoleDefinitionName -eq $roleDefinitionName
        }

        #endregion

        #region DEPLOYMENT

        if (-not $Rollback.IsPresent) {
            if ($null -eq $ra) {
                if ($PSCmdlet.ShouldProcess("Call module 'Az.Resources'.", 'New-AzRoleAssignment')) {

                    $raSplat = @{
                        ObjectId           = $ObjectId
                        RoleDefinitionName = $roleDefinitionName
                        Scope              = $scope
                        Verbose            = $VerbosePreference
                    }

                    $ra = New-AzRoleAssignment @raSplat -ErrorAction Stop
                }
            } else {
                Write-Verbose ("Exists. '/roleAssignment/{0}/{1}'" -f $ra.RoleDefinitionName, $ra.DisplayName)
            }
        }

        #endregion

        #region ROLLBACK

        if ($Rollback.IsPresent) {
            if ($null -ne $ra) {
                if ($PSCmdlet.ShouldProcess("Call module 'Az.Resources'.", 'Remove-AzRoleAssignment')) {
                    if (-not $Force.IsPresent) {
                        $prompt = @(
                            "This will delete '/roleAssignment/$($ra.RoleDefinitionName)/$($ra.DisplayName)'."
                            "Do you want to continue? 'Yes [Y]' 'No [N]'"
                        ) -join "`n"

                        $result = Read-Host -Prompt $prompt
                        $result = $result.ToLower()

                        if ($result -ne 'y' -and $result -ne 'yes') {
                            Write-Warning 'Operation cancelled by user'
                            return
                        }
                    }

                    Write-Verbose ("Removing '/roleAssignment/{0}/{1}'..." -f $ra.RoleDefinitionName, $ra.DisplayName)

                    $ra = Remove-AzRoleAssignment -InputObject $ra -ErrorAction Stop
                    Write-Verbose ("Deleted. '/roleAssignment/{0}/{1}'" -f $ra.RoleDefinitionName, $ra.DisplayName)
                }
            } else {
                Write-Warning ("Doesn't exist. '/roleAssignment/{0}/{1}'" -f $roleDefinitionName, $ObjectId)
            }
        }

        #endregion

        #region OUTPUT

        return $ra

        #endregion

    } catch {
        throw $_
    }
}

end {
    Write-Verbose ('[Exit]: .\src\res\shared\role-assignment\{0}' -f $MyInvocation.MyCommand.Name)
}
