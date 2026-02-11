#Requires -Version 7.0
<#PSScriptInfo
    .VERSION 0.1.0

    .GUID f7afc5a2-c2bd-443f-9542-31763f714ca6

    .AUTHOR Martin Swinkels

    .COMPANYNAME MSc365.eu

    .COPYRIGHT 2025 (c) MSc365.eu, Martin Swinkels

    .TAGS 'Azure', 'Security', 'Governance', 'DevOps', 'Platform', 'RBAC'

    .LICENSEURI https://github.com/msc365/az-devops-governance/blob/main/LICENSE

    .PROJECTURI https://github.com/msc365/az-devops-governance

    .ICONURI https://raw.githubusercontent.com/msc365/az-devops-governance/main/.assets/icon.png

    .EXTERNALMODULEDEPENDENCIES Az.Accounts, Azure.DevOps.PSModule
#>
<#
.SYNOPSIS
    Creates a new initial commit in a specified Azure DevOps repository including specified files.

.DESCRIPTION
    This cmdlet allows you to create an initial commit in a specified Azure DevOps repository.
    You can specify the content of the commit, the commit message, and the branch to which the commit will be pushed.

.PARAMETER CollectionUri
    Optional. The collection URI of the Azure DevOps collection/organization, e.g., `https://dev.azure.com/my-org`.

.PARAMETER ProjectName
    Optional. The Azure DevOps project ID or Name where the environment will be created.

.PARAMETER RepositoryName
    Required. The name of the Azure DevOps repository to which the initial commit will be pushed.

.PARAMETER BranchName
    Optional. The name of the branch to which the initial commit will be pushed. Default is 'main'.

.PARAMETER Message
    Optional. The commit message for the initial commit. Default is 'Initial commit'.

.PARAMETER Files
    Optional. An array of file objects to be included in the initial commit. Each file object should have the following properties:
    - `path`: The file path in the repository (e.g., 'src/index.js').
    - `content`: The content of the file as a string. This can be either raw text or a base64 encoded string.
    - `contentType`: A string indicating the content type, either 'rawtext' or 'base64encoded'.

.PARAMETER Rollback
    Optional. Switch to indicate if the operation should be rolled back (i.e., remove the specified group memberships).
    ⚠️ Note: Rollback functionality is not yet implemented.

.OUTPUTS
    PSCustomObject representing the result of the push operation.

    [PSCustomObject]@{
        pushId         = The ID of the push operation.
        commits        = The commits included in the push.
        refUpdates     = The reference updates for the push.
        pushedBy       = The user who initiated the push.
        date           = The date and time of the push.
        repositoryName = The name of the repository.
        projectName    = The name of the project.
        collectionUri  = The URI of the Azure DevOps collection.
        status         = The status of the push operation.
                         Possible values: 'Pushed', 'Failed', 'WouldPush', 'NotImplemented'
    }

.EXAMPLE
    $deploySplat = @{
        TemplateFile          = 'main.ps1'
        TemplateParameterFile = 'params/main.parameters.json'
    }

    .\deploy.ps1 @deploySplat -Verbose

    Deploys the group membership using the specified template and parameters.

.EXAMPLE
    $customSplat = @{
        TemplateFile          = 'main.ps1'
        TemplateParameterFile = 'params\custom.parameters.json'
    }

    .\deploy.ps1 @customSplat -Verbose

    Deploys the group membership using the specified template and custom parameters.

.EXAMPLE
    $params = @{
        CollectionUri  = 'https://dev.azure.com/my-org'
        ProjectName    = 'my-project-1'
        RepositoryName = 'my-repository-1'
        BranchName     = 'main'
        Message        = 'Initial commit'
        Files          = @(
            @{
                path        = '/README.md'
                content     = (Get-Content -Path 'assets/README.md' -Raw)
                contentType = 'rawtext'
            },
            @{
                path        = '/devops/pipeline/ci.yml'
                content     = (Get-Content -Path 'assets/ci.yml' -Raw)
                contentType = 'rawtext'
            },
            @{
                path        = '/.assets/tools.zip'
                content     = [Convert]::ToBase64String([IO.File]::ReadAllBytes('assets/tools.zip'))
                contentType = 'base64encoded'
            }
        )
    }
    New-AdoPushInitialCommit @params

    Creates a new initial commit with the specified content in the specified repository and branch.
#>
[CmdletBinding(SupportsShouldProcess)]
[OutputType([PSCustomObject])]
param (
    [Parameter()]
    [string]$CollectionUri = $env:DefaultAdoCollectionUri,

    [Parameter()]
    [string]$ProjectName = $env:DefaultAdoProjectName,

    [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
    [string]$RepositoryName,

    [Parameter(ValueFromPipelineByPropertyName)]
    [string]$BranchName = 'main',

    [Parameter(ValueFromPipelineByPropertyName)]
    [string]$Message = 'Initial commit',

    [Parameter(ValueFromPipelineByPropertyName)]
    [object[]]$Files = @(),

    [Parameter()]
    [switch]$Rollback
)

begin {
    Write-Verbose ("[Enter]: ./src/res/git/push/initial $($MyInvocation.MyCommand.Name)")

    # Validate required parameters
    if ([string]::IsNullOrWhiteSpace($CollectionUri)) {
        throw "CollectionUri is required. Provide via parameter or use Set-AdoDefault to set '`$env:DefaultAdoCollectionUri'."
    }

    if ([string]::IsNullOrWhiteSpace($ProjectName)) {
        throw "ProjectName is required. Provide via parameter or use Set-AdoDefault to set '`$env:DefaultAdoProjectName'."
    }

    # Validate Azure context
    $currentContext = Get-AzContext
    if ($null -eq $currentContext) {
        throw 'No Azure context found. Please login using Connect-AzAccount.'
    }

    # Import required module if not already loaded
    $requiredModule = 'Azure.DevOps.PSModule'

    if (-not (Get-Module -Name $requiredModule)) {
        Import-Module $requiredModule -Force -Verbose:$false -ErrorAction Stop
        Write-Verbose "Module '$requiredModule' imported successfully."
    }

    # Project
    $prjSplat = @{
        CollectionUri = $CollectionUri
        Project       = $ProjectName
    }
    $prj = Get-AdoProject @prjSplat -Verbose:$false -ErrorAction SilentlyContinue

    if ($null -eq $prj) {
        throw "Project with ID $ProjectName does not exist, cannot proceed."
    }

    # Repository
    $repoSplat = @{
        CollectionUri  = $CollectionUri
        ProjectName    = $ProjectName
        RepositoryName = $RepositoryName
    }
    $repo = Get-AdoRepository @repoSplat -Verbose:$false -ErrorAction SilentlyContinue

    if ($null -eq $repo) {
        throw "Repository with name $RepositoryName does not exist, cannot proceed."
    }
}

process {
    try {
        $ErrorActionPreference = 'Stop'

        #region INITIALIZE

        # Status
        $status = 'Unknown'

        #endregion

        #region DEPLOYMENTS

        if (-not $Rollback.IsPresent) {
            $pushSplat = [ordered]@{
                CollectionUri  = $CollectionUri
                ProjectName    = $ProjectName
                RepositoryName = $RepositoryName
                BranchName     = $BranchName
                Message        = $Message
                Files          = $Files
            }

            if ($PSCmdlet.ShouldProcess("$RepositoryName", "Push initial commit on $BranchName")) {

                $push = New-AdoPushInitialCommit @pushSplat -Verbose:$false

                if ($push) {
                    $status = 'Pushed'
                    Write-Verbose "[PUSHED]: Commit '$Message' (Branch: $BranchName)"
                } else {
                    $status = 'Failed'
                    Write-Verbose "[FAILED]: Failed to push commit '$Message' (Branch: $BranchName)"
                }
            } else {
                $status = 'WouldPush'
                Write-Verbose "[WHATIF]: Call New-AdoPushInitialCommit with parameters: $($pushSplat | ConvertTo-Json -Depth 10)"
            }
        }

        #endregion

        #region ROLLBACK

        if ($Rollback.IsPresent) {
            $status = 'NotImplemented'
            Write-Warning "[NOTIMPLEMENTED]: Push rollback '$Message' (Branch: $BranchName)"
        }

        #endregion

        #region OUTPUTS

        $push | Select-Object -ExcludeProperty collectionUri, projectName -Property *,
        @{ Name = 'repositoryName'; Expression = { $RepositoryName } },
        @{ Name = 'projectName'; Expression = { $ProjectName } },
        @{ Name = 'collectionUri'; Expression = { $CollectionUri } },
        @{ Name = 'status'; Expression = { $status } }

        #endregion

    } catch {
        throw $_
    }
}

end {
    Write-Verbose ("[Exit]: ./src/res/git/push/initial $($MyInvocation.MyCommand.Name)")
}
