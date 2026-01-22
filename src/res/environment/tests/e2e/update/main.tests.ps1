<#
.SYNOPSIS
    Update end-to-end tests for Azure DevOps environment resource.

.DESCRIPTION
    This script executes end-to-end tests with updated properties for an Azure DevOps environment configuration.

.NOTES
    File Name      : main.tests.ps1
    Prerequisite   : Azure PowerShell modules and authenticated Azure context
#>

#region PARAMETERS

$params = @{
    CollectionUri = 'https://dev.azure.com/e2egov-org'
    ProjectName   = 'e2egov-prjHb72x9'
    Name          = 'env-e2egov-prjHb72x9-tst'
    Description   = 'Updated environment description'
}

# endregion

#region INITIALIZE

$rootPath = (Get-Item $PSScriptRoot).Parent.Parent.Parent.FullName

$subscriptionId = (Get-AzContext).Subscription.Id
$params['SubscriptionId'] = $subscriptionId

#endregion

#region TEST EXECUTION

& (Join-Path $rootPath -ChildPath 'main.ps1') @params -Confirm:$false | Format-List *

#endregion
