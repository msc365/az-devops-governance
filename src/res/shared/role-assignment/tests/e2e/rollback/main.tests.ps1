<#
.SYNOPSIS
    Rollback end-to-end tests for Azure role assignment.

.DESCRIPTION
    This script executes end-to-end rollback tests for Azure role assignment configuration.

.NOTES
    File Name      : main.tests.ps1
    Prerequisite   : Azure PowerShell modules and authenticated Azure context
#>

#region PARAMETERS

$params = @{
    ObjectId        = '00000000-0000-0000-0000-000000000000'
    RoleAssignments = @(
        @{
            roleDefinitionName = 'Reader'
            scope              = '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-e2egov-prjHb72x9-tst-weu'
        }
    )
    Rollback        = $true
}

# endregion

#region INITIALIZE

$rootPath = (Get-Item $PSScriptRoot).Parent.Parent.Parent.FullName

$subscriptionId = (Get-AzContext).Subscription.Id

$identitySplat = @{
    Name              = 'id-e2egov-prjHb72x9-tst'
    ResourceGroupName = 'rg-e2egov-prjHb72x9-tst-weu'
    SubscriptionId    = $subscriptionId
}

$identity = Get-AzUserAssignedIdentity @identitySplat -ErrorAction Stop

# Set ObjectId to the actual principal ID
$params['ObjectId'] = $identity.PrincipalId

# Update scope with actual subscription ID
$params['RoleAssignments'][0].scope = $params['RoleAssignments'][0].scope -replace '00000000-0000-0000-0000-000000000000', $subscriptionId

#endregion

#region TEST EXECUTION

& (Join-Path $rootPath -ChildPath 'main.ps1') @params -Verbose -Confirm:$false | Format-List *

#endregion
