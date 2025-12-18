<#
.SYNOPSIS
    Rollback end-to-end tests for Azure DevOps environment.

.DESCRIPTION
    This script executes end-to-end tests with rollback properties for an Azure DevOps environment configuration.

.NOTES
    File Name      : main.tests.ps1
    Prerequisite   : Azure PowerShell modules and authenticated Azure context
#>

#region PARAMETERS

$params = @{
    Organization = 'e2egov-org'
    ProjectId    = 'e2egov-prjHb72x9'
    Name         = 'env-prjHb72x9-tst'
    Rollback     = $true
    Force        = $true
}

# endregion

#region INITIALIZE

$rootPath = (Get-Item $PSScriptRoot).Parent.Parent.Parent.FullName

#endregion

#region TEST EXECUTION

& (Join-Path $rootPath -ChildPath 'main.ps1') @params -Verbose

#endregion
