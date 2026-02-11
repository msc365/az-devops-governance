<#
.SYNOPSIS
    Create end-to-end tests for Azure DevOps initial commit.

.DESCRIPTION
    This script executes end-to-end tests with default properties for an Azure DevOps initial commit.

.NOTES
    File Name      : main.tests.ps1
    Prerequisite   : Azure PowerShell modules and authenticated Azure context
#>

#region INITIALIZE

$rootPath = (Get-Item $PSScriptRoot).Parent.Parent.Parent.FullName

#endregion

#region PARAMETERS

$params = @{
    CollectionUri  = 'https://dev.azure.com/e2egov-org'
    ProjectName    = 'e2egov-prjE2eT3st'
    RepositoryName = 'e2egov-repoE2eT3st'
    BranchName     = 'main'
    Message        = 'Initial commit'
    Files          = @(
        @{
            path        = '/README.md'
            content     = (Get-Content -Path (Join-Path $rootPath -ChildPath 'assets/README.md') -Raw)
            contentType = 'rawtext'
        },
        @{
            path        = '/devops/pipeline/ci.yml'
            content     = (Get-Content -Path (Join-Path $rootPath -ChildPath 'assets/ci.yml') -Raw)
            contentType = 'rawtext'
        },
        @{
            path        = '/.assets/tools.zip'
            content     = [Convert]::ToBase64String([IO.File]::ReadAllBytes((Join-Path $rootPath -ChildPath 'assets/tools.zip')))
            contentType = 'base64encoded'
        }
    )
}

# endregion

#region TEST EXECUTION

& (Join-Path $rootPath -ChildPath 'main.ps1') @params -Confirm:$false | Format-List *

#endregion
