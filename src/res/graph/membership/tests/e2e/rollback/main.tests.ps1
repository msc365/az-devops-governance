<#
.SYNOPSIS
    Rollback end-to-end tests for Azure DevOps group membership.

.DESCRIPTION
    This script executes end-to-end tests with rollback properties for an Azure DevOps group membership configuration.

.NOTES
    File Name      : main.tests.ps1
    Prerequisite   : Azure PowerShell modules and authenticated Azure context
#>

#region PARAMETERS

$params = @{
    CollectionUri   = 'https://dev.azure.com/e2egov-org'
    ProjectName     = 'e2egov-prjE2eT3st'
    UniqueName      = 'e2egov-prjE2eT3st-devs'
    GroupMembership = 'Contributors'
    Rollback        = $true
}

# endregion

#region INITIALIZE

$rootPath = (Get-Item $PSScriptRoot).Parent.Parent.Parent.FullName

#endregion

#region TEST EXECUTION

& (Join-Path $rootPath -ChildPath 'main.ps1') @params -Confirm:$false | Format-List *

#endregion
