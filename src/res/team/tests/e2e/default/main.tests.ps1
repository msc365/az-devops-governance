<#
.SYNOPSIS
    Create end-to-end tests for Azure DevOps team.

.DESCRIPTION
    This script executes end-to-end tests with default properties for the Azure DevOps team configuration.

.NOTES
    File Name      : main.tests.ps1
    Prerequisite   : Azure PowerShell modules and authenticated Azure context
#>

#region PARAMETERS

$params = @{
    ProjectId = 'e2egov-prjHb72x9'
    TeamId    = 'Test Team'
}

# endregion

#region INITIALIZE

$rootPath = (Get-Item $PSScriptRoot).Parent.Parent.Parent.FullName

#endregion

#region TEST EXECUTION

& (Join-Path $rootPath -ChildPath 'main.ps1') @params -Verbose | Format-List *

#endregion
