<#
.SYNOPSIS
    Create end-to-end tests for Azure DevOps project.

.DESCRIPTION
    This script executes end-to-end tests with all properties for the Azure DevOps project configuration.

.NOTES
    File Name      : main.tests.ps1
    Prerequisite   : Azure PowerShell modules and authenticated Azure context
#>

#region PARAMETERS

$params = @{
    Organization  = 'e2egov-org'
    Name          = 'e2egov-prjHb72x9'
    Description   = 'Default e2e governance description'
    DefaultTeam   = 'Default Team'
    Process       = 'Agile'
    SourceControl = 'Git'
    Visibility    = 'Private'
    Features      = @{
        'Boards'    = 'enabled'
        'Repos'     = 'enabled'
        'Pipelines' = 'enabled'
        'TestPlans' = 'disabled'
        'Artifacts' = 'enabled'
    }
}

# endregion

#region INITIALIZE

$rootPath = (Get-Item $PSScriptRoot).Parent.Parent.Parent.FullName

#endregion

#region TEST EXECUTION

& (Join-Path $rootPath -ChildPath 'main.ps1') @params -Verbose | Format-List *

#endregion
