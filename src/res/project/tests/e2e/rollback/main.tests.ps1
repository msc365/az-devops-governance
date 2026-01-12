<#
.SYNOPSIS
    Rollback end-to-end tests for Azure DevOps project.

.DESCRIPTION
    This script executes end-to-end tests with rollback properties for the Azure DevOps project configuration.

.NOTES
    File Name      : main.tests.ps1
    Prerequisite   : Azure PowerShell modules and authenticated Azure context
#>

#region PARAMETERS

$params = @{
    CollectionUri = 'https://dev.azure.com/e2egov-org'
    Name          = 'e2egov-prjHb72x9'
    Rollback      = $true
}

# endregion

#region INITIALIZE

$rootPath = (Get-Item $PSScriptRoot).Parent.Parent.Parent.FullName

#endregion

#region TEST EXECUTION

& (Join-Path $rootPath -ChildPath 'main.ps1') @params -Confirm:$false -Verbose

#endregion
