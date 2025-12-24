<#
.SYNOPSIS
    Create end-to-end tests for Azure DevOps project.

.DESCRIPTION
    This script executes end-to-end tests with default properties for the Azure DevOps project configuration.

.NOTES
    File Name      : main.tests.ps1
    Prerequisite   : Azure PowerShell modules and authenticated Azure context
#>

#region PARAMETERS

$params = [hashtable]@{
    ProjectId       = 'e2egov-prjHb72x9'
    TeamId          = 'Test Team'
    Description     = 'Test team description'
    TeamSettings    = @{
        backlogVisibilities   = @{
            'Microsoft.EpicCategory'        = $false
            'Microsoft.FeatureCategory'     = $true
            'Microsoft.RequirementCategory' = $true
        }
        bugsBehavior          = 'asTasks'
        defaultIterationMacro = '@currentIteration'
        workingDays           = @(
            'monday'
            'tuesday'
            'wednesday'
            'thursday'
            'friday'
        )
    }
    GroupMembership = @(
        'Contributors'
    )
}

# endregion

#region INITIALIZE

$rootPath = (Get-Item $PSScriptRoot).Parent.Parent.Parent.FullName

#endregion

#region TEST EXECUTION

& (Join-Path $rootPath -ChildPath 'main.ps1') @params -Verbose | Format-List *

#endregion
