[CmdletBinding(SupportsShouldProcess)]
param (
    [Parameter(Mandatory)]
    [string]$Project,

    [Parameter(Mandatory)]
    [string]$GroupId,

    [Parameter(Mandatory)]
    [string[]]$GroupMembership
)

begin {
    Write-Verbose "[Enter]: ./$($MyInvocation.MyCommand.Name)"
}

process {
    try {
        $ErrorActionPreference = 'Stop'

        # Get project's built-in groups
        $builtInGroupDescriptors = (Get-AdoDescriptor -StorageKey $Project -Verbose:$VerbosePreference).value
        $builtInGroups = (Get-AdoGroupList -ScopeDescriptor $builtInGroupDescriptors -SubjectTypes 'vssgp' -Verbose:$VerbosePreference).value

        $GroupMembership | ForEach-Object -Process {

            if ($GroupId -eq '[WhatIf-NotCreated]') {
                # Skip if group not created yet (WhatIf scenario)
                $membership = $null

            } else {
                # Get the ADO group by its Entra Id
                $groupDescriptors = (Get-AdoGroupList -SubjectTypes 'aadgp' -Verbose:$VerbosePreference).value

                # Find the group with the specified Entra Id
                $group = $groupDescriptors | Where-Object originId -EQ $GroupId

                # Check if membership already exists
                if ($null -ne $group) {
                    $membershipSplat = @{
                        subjectDescriptor   = $group.descriptor
                        containerDescriptor = ($builtInGroups | Where-Object displayName -EQ $_).descriptor
                    }

                    $membership = Get-AdoMembership @membershipSplat -Verbose:$VerbosePreference
                } else {
                    $membership = $null
                }

                if ($null -eq $membership) {
                    if ($PSCmdlet.ShouldProcess("Call module 'Azure.DevOps.PSModule' operation.", 'New-AdoGroup, Materialize Membership')) {
                        $shpSplat = @{
                            GroupDescriptor = ($builtInGroups | Where-Object displayName -EQ $_).descriptor
                            GroupId         = $GroupId
                        }

                        New-AdoGroup @shpSplat -Verbose:$VerbosePreference | Out-Null
                    }
                }
            }
        }
    } catch {
        throw $_
    }
}

end {
    Write-Verbose "[Exit]: ./$($MyInvocation.MyCommand.Name)"
}
