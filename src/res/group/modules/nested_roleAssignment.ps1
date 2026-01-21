[CmdletBinding(SupportsShouldProcess)]
param (
    [Parameter(Mandatory)]
    [string]$GroupId,

    [Parameter(Mandatory)]
    [string]$PrincipalId,

    [Parameter(Mandatory)]
    [object[]]$RoleAssignments,

    [Parameter()]
    [switch]$Remove
)

begin {
    Write-Verbose "[Enter]: .\$($MyInvocation.MyCommand.Name)"
}

process {
    try {
        $ErrorActionPreference = 'Stop'

        $RoleAssignments | ForEach-Object -Process {
            if ($GroupId -eq '[WhatIf-NotCreated]' -or $PrincipalId -eq '[WhatIf-NotCreated]') {

                # Skip if group or principal not created yet (WhatIf scenario)
                $roleAssign = $null
            } else {
                $roleAssignSplat = @{
                    Scope              = $_.scope
                    ObjectId           = $_.objectType -eq 'Group' ? $GroupId : $PrincipalId
                    RoleDefinitionName = $_.roleDefinitionName
                }

                $roleAssign = Get-AzRoleAssignment -Scope $roleAssignSplat.Scope | Where-Object {
                    $_.ObjectId -eq $roleAssignSplat.ObjectId -and
                    $_.RoleDefinitionName -eq $roleAssignSplat.RoleDefinitionName
                }
            }

            if ($null -eq $roleAssign -and -not $Remove.IsPresent) {
                if ($PSCmdlet.ShouldProcess("Call module 'Az.Resources'.", 'New-AzRoleAssignment')) {
                    New-AzRoleAssignment @roleAssignSplat -ErrorAction Stop | Out-Null
                }
            } else {
                if ($Remove.IsPresent -and $null -ne $roleAssign) {
                    if ($PSCmdlet.ShouldProcess("Call module 'Az.Resources'.", 'Remove-AzRoleAssignment')) {
                        Remove-AzRoleAssignment -RoleAssignmentId $roleAssign.Id -ErrorAction Stop | Out-Null
                    }
                } else {
                    Write-Verbose "NoChange: 'RESOURCE /roleAssignment/$($roleAssign.RoleDefinitionName) -> $($roleAssign.DisplayName)'"
                }
            }
        }

    } catch {
        throw $_
    }
}

end {
    Write-Verbose "[Exit]: .\$($MyInvocation.MyCommand.Name)"
}
