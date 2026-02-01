<#
.SYNOPSIS
    All properties end-to-end tests for Azure DevOps team.

.DESCRIPTION
    This script executes end-to-end tests with all properties for an Azure DevOps team configuration.

.NOTES
    File Name      : main.tests.ps1
    Prerequisite   : Azure PowerShell modules and authenticated Azure context
#>

#region PARAMETERS

$params = @{
    CollectionUri = 'https://dev.azure.com/e2egov-org'
    ProjectName   = 'e2egov-prjE2eT3st'
    Name          = 'Test Team A'
    Rollback      = $true
}

# endregion

#region INITIALIZE

$rootPath = (Get-Item $PSScriptRoot).Parent.Parent.Parent.FullName

#endregion

#region TEST EXECUTION

& (Join-Path $rootPath -ChildPath 'main.ps1') @params -Confirm:$false -Verbose | Format-List *

#endregion
