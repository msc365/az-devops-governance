<#
.SYNOPSIS
    Update end-to-end tests for Azure DevOps project.

.DESCRIPTION
    This script executes end-to-end tests with updated properties for the Azure DevOps project configuration.

.NOTES
    File Name      : main.tests.ps1
    Prerequisite   : Azure PowerShell modules and authenticated Azure context
#>

#region PARAMETERS

$params = @{
    CollectionUri = 'https://dev.azure.com/e2egov-org'
    Name          = 'e2egov-prjE2eT3st'
    Description   = 'Updated project description'
    DefaultTeam   = 'Updated Team'
    Features      = @{
        'boards'    = 'enabled'
        'repos'     = 'disabled'
        'pipelines' = 'disabled'
        'testPlans' = 'disabled'
        'artifacts' = 'disabled'
    }
}

# endregion

#region INITIALIZE

$rootPath = (Get-Item $PSScriptRoot).Parent.Parent.Parent.FullName

#endregion

#region TEST EXECUTION

& (Join-Path $rootPath -ChildPath 'main.ps1') @params -Confirm:$false -Verbose | Format-List *

#endregion
