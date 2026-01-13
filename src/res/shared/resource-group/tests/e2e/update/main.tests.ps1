<#
.SYNOPSIS
    Update properties end-to-end tests for Azure DevOps resource group.

.DESCRIPTION
    This script executes end-to-end tests with updated properties for an Azure DevOps resource group configuration.

.NOTES
    File Name      : main.tests.ps1
    Prerequisite   : Azure PowerShell modules and authenticated Azure context
#>

#region PARAMETERS

$params = @{
    Name           = 'rg-e2egov-prjHb72x9-tst-weu'
    Location       = 'westeurope'
    SubscriptionId = '00000000-0000-0000-0000-000000000000'
    Tags           = @{
        public      = 'false'
        service     = 'e2egov'
        environment = 'tst'
        security    = 'rbac'
        iac         = 'bicep'
        ci          = 'azure-pipelines'
        updated     = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    }
}

# endregion

#region INITIALIZE

$rootPath = (Get-Item $PSScriptRoot).Parent.Parent.Parent.FullName

$subscriptionId = (Get-AzContext).Subscription.Id
$params['SubscriptionId'] = $subscriptionId

#endregion

#region TEST EXECUTION

& (Join-Path $rootPath -ChildPath 'main.ps1') @params -Verbose -Confirm:$false | Format-List *

#endregion
