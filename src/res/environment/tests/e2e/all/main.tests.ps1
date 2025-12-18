<#
.SYNOPSIS
    All properties end-to-end tests for Azure DevOps environment.

.DESCRIPTION
    This script executes end-to-end tests with all properties for an Azure DevOps environment configuration.

.NOTES
    File Name      : main.tests.ps1
    Prerequisite   : Azure PowerShell modules and authenticated Azure context
#>

#region PARAMETERS

$params = @{
    Organization  = 'e2egov-org'
    ProjectId     = 'e2egov-prjHb72x9'
    Name          = 'env-prjHb72x9-tst'
    Description   = 'Default e2e governance description'
    ResourceGroup = @{
        Name           = 'rg-e2egov-prjHb72x9-tst-weu'
        Location       = 'westeurope'
        SubscriptionId = '00000000-0000-0000-0000-000000000000'
        Tags           = @{
            public      = 'false'
            service     = 'e2egov'
            environment = 'prd'
            security    = 'rbac'
            iac         = 'bicep'
            ci          = 'azure-pipelines'
        }
    }
}

# endregion

#region INITIALIZE

$rootPath = (Get-Item $PSScriptRoot).Parent.Parent.Parent.FullName

$subscriptionId = (Get-AzContext).Subscription.Id
$params['ResourceGroup']['SubscriptionId'] = $subscriptionId

#endregion

#region TEST EXECUTION

& (Join-Path $rootPath -ChildPath 'main.ps1') @params -Verbose

#endregion
