#Requires -Version 7.0
<#PSScriptInfo
    .VERSION 0.1.0

    .GUID 2d16a205-57da-4734-91fa-cb9f2310899d

    .AUTHOR Martin Swinkels

    .COMPANYNAME MSc365.eu

    .COPYRIGHT 2025 (c) MSc365.eu, Martin Swinkels

    .TAGS 'Azure', 'Security', 'Governance', 'DevOps', 'Platform', 'RBAC'

    .LICENSEURI https://github.com/msc365/az-devops-governance/blob/main/LICENSE

    .PROJECTURI https://github.com/msc365/az-devops-governance

    .ICONURI https://raw.githubusercontent.com/msc365/az-devops-governance/main/.assets/icon.png

    .EXTERNALMODULEDEPENDENCIES Az.Accounts, Az.Resources, Az.ManagedServiceIdentity, Microsoft.Graph.Groups, Azure.DevOps.PSModule
#>
[CmdletBinding(SupportsShouldProcess)]
param (
    [Parameter(Mandatory)]
    [string]$Organization,

    [Parameter(Mandatory)]
    [string]$Project,

    [Parameter(Mandatory)]
    [string]$MailNickname,

    [Parameter(Mandatory)]
    [string]$DisplayName,

    [Parameter(Mandatory)]
    [string]$Description,

    [Parameter(Mandatory = $false)]
    [bool]$MailEnabled = $false,

    [Parameter(Mandatory = $false)]
    [bool]$SecurityEnabled = $true,

    [Parameter(Mandatory = $false)]
    [bool]$IsAssignableToRole = $true,

    [Parameter(Mandatory = $false)]
    [string]$Visibility = 'Private',

    [Parameter(Mandatory = $false)]
    [object]$ManagedIdentity,

    [Parameter(Mandatory = $false)]
    [object]$ServiceConnection,

    [Parameter(Mandatory = $false)]
    [string[]]$GroupMembership = @(),

    [Parameter(Mandatory = $false)]
    [object[]]$RoleAssignments = @(),

    [Parameter()]
    [switch]$Remove,

    [Parameter()]
    [switch]$Force
)

begin {
    Write-Verbose "[Enter]: .\$($MyInvocation.MyCommand.Name)"

    if ($null -eq (Get-AzContext)) {
        throw 'No Azure context found. Please login using Connect-AzAccount.'
    }

    # Import required modules
    $modules = @(
        'Az.Accounts'
        'Az.Resources'
        'Az.ManagedServiceIdentity'
        'Microsoft.Graph.Groups'
        'Azure.DevOps.PSModule'
    )

    $modules | ForEach-Object {
        if (-not (Get-Module -Name $_)) {
            if (Get-Module -Name $_ -ListAvailable) {
                Import-Module $_ -Force -Verbose:$false -ErrorAction Stop
            } else {
                throw "Required module '$_' is not installed. Please install it first."
            }
        }
    }

    # Connect to Azure DevOps Organization
    if ($null -eq (Get-AdoContext)) {
        Connect-AdoOrganization -Organization $Organization -Verbose:$VerbosePreference
    }

    # Connect to Microsoft Graph
    if ($null -eq (Get-MgContext)) {
        throw 'No Microsoft Graph context found. Please login using Connect-MgGraph'
    }
}

process {
    try {
        $ErrorActionPreference = 'Stop'
        $Error.Clear()

        ## --------- ##
        ## VARIABLES ##
        ## --------- ##

        $prj, $grp, $msi, $svc, $sync = $null

        ## ------------ ##
        ## DEPENDENCIES ##
        ## ------------ ##

        $prj = Get-AdoProject -Project $Project -ErrorAction SilentlyContinue

        if ($null -eq $prj) {
            throw "Resource Doesn't exist: '/projects/$($Project)' ."
        }

        if ($null -ne $ManagedIdentity) {
            $contextSub = (Get-AzContext).Subscription

            if ($contextSub.Id -ne $ManagedIdentity.subscriptionId) {
                $targetSub = (Set-AzContext -SubscriptionId $ManagedIdentity.subscriptionId -WhatIf:$false).Subscription
            }
        }

        ## --------- ##
        ## RESOURCES ##
        ## --------- ##

        $grp = Get-MgGroup -Filter "mailNickname eq '$($MailNickname)'" -Property Id, MailNickname, DisplayName, Description -ErrorAction SilentlyContinue

        if ($Remove.IsPresent) {
            if ($null -ne $grp) {
                if ($PSCmdlet.ShouldProcess("Call remote 'Remove /groups/$($grp.Id)' operation.", 'Remove-MgGroup')) {

                    if (-not $Force.IsPresent) {
                        $prompt = @(
                            "This script will permanently Remove group '$($DisplayName)'."
                            'All related resources like managed identity, service connection and role assignments will be lost.'
                            "Do you want to continue? 'Yes [Y]' 'No [N]'"
                        ) -join "`n"

                        $result = Read-Host -Prompt $prompt
                        $result = $result.ToLower()

                        if ($result -ne 'y' -and $result -ne 'yes') {
                            Write-Verbose 'Operation cancelled by user'
                            return
                        }
                    }

                    Remove-MgGroup -GroupId $grp.Id -ErrorAction Stop

                    # TODO: Remove nested resources like managed identity, service connection and role assignments
                }
            } else {
                Write-Warning "Doesn't exist: 'RESOURCE /groups/$($MailNickname)'"
            }
            return
        }

        if ($null -eq $grp) {
            if ($PSCmdlet.ShouldProcess("Call remote 'POST /groups' operation.", 'New-MgGroup')) {
                $groupSplat = @{
                    DisplayName        = $DisplayName
                    MailNickname       = $MailNickname
                    Description        = $Description
                    MailEnabled        = $MailEnabled
                    SecurityEnabled    = $SecurityEnabled
                    IsAssignableToRole = $IsAssignableToRole
                    Visibility         = $Visibility
                }

                $grp = New-MgGroup @groupSplat -ErrorAction Stop
                $sync = $true
            }
        } else {
            if ($DisplayName -ne $grp.DisplayName -or
                $Description -ne $grp.Description) {

                if ($PSCmdlet.ShouldProcess("Call remote 'PATCH /groups/$($grp.Id)' operation.", 'Update-MgGroup')) {
                    $updateSplat = @{
                        GroupId     = $grp.Id
                        DisplayName = $DisplayName
                        Description = $Description
                    }

                    Update-MgGroup @updateSplat -ErrorAction Stop

                    $grp = Get-MgGroup -GroupId $grp.Id -ErrorAction Stop
                }
            } else {
                Write-Verbose "Exists. No updates. 'RESOURCE /groups/$($MailNickname)'"
            }
        }

        if ($sync) {
            # Wait for Entra ID security group synchronization
            for ($i = 0; $i -le 15; $i++) {
                Write-Progress -Activity 'Waiting Entra ID Sync' -Status ('{0} seconds remaining' -f (15 - $i)) -PercentComplete (($i / 15) * 100)
                Start-Sleep -Seconds 1
            }

            Write-Progress -Activity 'Waiting Entra ID Sync' -Status 'Completed' -Completed
        }

        ## ---------------- ##
        ## NESTED RESOURCES ##
        ## ---------------- ##

        ## Resource Group ##
        ## -------------- ##

        if ($null -ne $ManagedIdentity) {
            $rgSplat = @{
                Name     = $ManagedIdentity.resourceGroupName
                Location = $ManagedIdentity.location
                Tags     = $ManagedIdentity.tags
                WhatIf   = $WhatIfPreference
                Verbose  = $VerbosePreference
            }

            & (Join-Path -Path $PSScriptRoot -ChildPath '..\shared\nested_resourceGroup.ps1') @rgSplat | Out-Null

        } else {
            Write-Verbose ("Null. 'PARAMETER /ResourceGroup'")
        }

        ## Managed Identity ##
        ## ---------------- ##

        if ($null -ne $ManagedIdentity) {
            $msiSplat = @{
                Name              = $ManagedIdentity.name
                ResourceGroupName = $ManagedIdentity.resourceGroupName
                SubscriptionId    = $ManagedIdentity.subscriptionId
                Location          = $ManagedIdentity.location
                Tags              = $ManagedIdentity.tags
                WhatIf            = $WhatIfPreference
                Verbose           = $VerbosePreference
            }

            $msi = & (Join-Path -Path $PSScriptRoot -ChildPath 'modules\nested_managedIdentity.ps1') @msiSplat

        } else {
            Write-Verbose ("Null. 'PARAMETER /ManagedIdentity'")
        }

        ## Service Connection ##
        ## ------------------ ##

        if ($null -ne $ServiceConnection) {
            $svcSplat = @{
                EndPointName     = $ServiceConnection.name
                ProjectRef       = @{
                    Id   = $prj.id
                    Name = $prj.name
                }
                AuthorizationRef = @{
                    ServiceprincipalId = ($msi.ClientId) ?? ($WhatIfPreference ? '[WhatIf-NotCreated]' : $null)
                    TenantId           = ($msi.TenantId) ?? ($WhatIfPreference ? '[WhatIf-NotCreated]' : $null)
                    Scope              = $ServiceConnection.scope
                }
                IdentityRef      = @{
                    IdentityName      = $ManagedIdentity.name
                    SubscriptionId    = $ManagedIdentity.subscriptionId
                    ResourceGroupName = $ManagedIdentity.resourceGroupName
                }
                WhatIf           = $WhatIfPreference
                Verbose          = $VerbosePreference
            }

            $svc = & (Join-Path -Path $PSScriptRoot -ChildPath 'modules\nested_serviceConnection.ps1') @svcSplat

        } else {
            Write-Verbose ("Null. 'PARAMETER /ServiceConnection'" )
        }

        ## Group Membership ##
        ## ---------------- ##

        if ($null -ne $GroupMembership -and $GroupMembership.Count -gt 0) {

            $shpSplat = @{
                Project         = $prj.Id
                GroupId         = ($grp.Id) ?? ($WhatIfPreference ? '[WhatIf-NotCreated]' : $null)
                GroupMembership = $GroupMembership
                WhatIf          = $WhatIfPreference
                Verbose         = $VerbosePreference
            }

            & (Join-Path -Path $PSScriptRoot -ChildPath 'modules\nested_groupMembership.ps1') @shpSplat

        } else {
            Write-Verbose ("Null. 'PARAMETER /GroupMembership'" )
        }

        ## Role Assignments ##
        ## ---------------- ##

        if ($null -ne $RoleAssignments -and $RoleAssignments.Count -gt 0) {

            $roleAssignSplat = @{
                GroupId         = ($grp.Id) ?? ($WhatIfPreference ? '[WhatIf-NotCreated]' : $null)
                PrincipalId     = ($msi.PrincipalId) ?? ($WhatIfPreference ? '[WhatIf-NotCreated]' : $null)
                RoleAssignments = $RoleAssignments
                WhatIf          = $WhatIfPreference
                Verbose         = $VerbosePreference
            }

            & (Join-Path -Path $PSScriptRoot -ChildPath 'modules\nested_roleAssignment.ps1') @roleAssignSplat

        } else {
            Write-Verbose ("Null. 'PARAMETER /RoleAssignments'" )
        }

        ## ------- ##
        ## OUTPUTS ##
        ## ------- ##

        $output = [PSCustomObject]@{
            groupId           = ($grp.Id) ?? '[Unknown]'
            mailNickname      = ($grp.MailNickname) ?? $MailNickname
            displayName       = ($grp.DisplayName) ?? $DisplayName
            description       = ($grp.Description) ?? $Description
            managedIdentity   = ($msi | Select-Object -Property *) ?? '[Unknown]'
            serviceConnection = ($svc | Select-Object -Property *) ?? '[Unknown]'
        }

        return $output

    } catch {
        throw $_
    }

    finally {
        if ($null -ne $contextSub -and $null -ne $targetSub) {
            Set-AzContext -SubscriptionId $contextSub.Id -Verbose:$false | Out-Null
        }

        Write-Progress -Activity 'Progress' -Status 'Completed' -Completed
    }
}

end {
    Write-Verbose "[Exit]: .\$($MyInvocation.MyCommand.Name)"
}
