[CmdletBinding(SupportsShouldProcess)]
param (
    [Parameter()]
    [string]$TemplateFile = 'main.ps1',

    [Parameter()]
    [string]$TemplateParameterFile = 'params/main.parameters.json',

    [Parameter()]
    [string]$ConfigFile = 'config/main.config.json',

    [Parameter()]
    [switch]$Rollback
)

begin {
    Write-Verbose "[Enter]: ./$($MyInvocation.MyCommand.Name)"

    # Import utility functions
    . (Join-Path $PSScriptRoot -ChildPath '../../../..' 'utl/Set-PlaceholderValue.ps1' -ErrorAction Stop)
}

process {
    try {
        # Load configuration from JSON file
        $configAsJson = Get-Content -Path (Join-Path $PSScriptRoot -ChildPath '../../../../..' $ConfigFile) -Raw

        # Load parameters from JSON file
        $paramsAsJson = Get-Content -Path (Join-Path $PSScriptRoot -ChildPath $TemplateParameterFile) -Raw

        # Replace placeholders in parameters using utility function
        $paramsAsJson = Set-PlaceholderValue -ParamsJson $paramsAsJson -ConfigJson $configAsJson

        # Convert JSON string to PSCustomObject to preserve pipeline property binding
        $params = $paramsAsJson | ConvertFrom-Json

        Write-Verbose "Using params: $($params | ConvertTo-Json -Depth 5)"

        $collectionUri = $params.collectionUri
        if ([string]::IsNullOrWhiteSpace($collectionUri)) {
            throw 'collectionUri is required in the parameter file.'
        }

        $projects = $params.projects
        if ($null -eq $projects -or $projects.Count -eq 0) {
            throw 'No projects found in parameter file. At least one project entry is required.'
        }

        Write-Verbose "Processing $($projects.Count) project(s)..."

        foreach ($project in $projects) {

            $projectName = $project.projectName
            if ([string]::IsNullOrWhiteSpace($projectName)) {
                throw 'Each project entry must include a projectName.'
            }

            $repositoryName = $project.repositoryName
            if ([string]::IsNullOrWhiteSpace($repositoryName)) {
                throw "Project '$projectName' does not define a repository."
            }

            $files = $project.files
            if ($null -eq $files -or $files.Count -eq 0) {
                throw "Project '$projectName' does not define any files to push."
            }

            Write-Verbose "Processing repository '$repositoryName'..."

            # Prepare file contents for push operation
            $filesContent = @()
            foreach ($file in $files) {

                if ($file.contentType -eq 'rawtext') {
                    $content = Get-Content -Path (Join-Path $PSScriptRoot -ChildPath $file.content) -Raw

                } elseif ($file.contentType -eq 'base64encoded') {
                    $content = [Convert]::ToBase64String([IO.File]::ReadAllBytes(
                            (Join-Path $PSScriptRoot -ChildPath $file.content)
                        ))
                } else {
                    throw "Unsupported contentType '$($file.contentType)' for file '$($file.path)'. Supported types are 'rawtext' and 'base64encoded'."
                }

                $fileContent = @{
                    path        = $file.path
                    content     = $content
                    contentType = $file.contentType
                }
                $filesContent += $fileContent
            }

            $scriptParams = @{
                CollectionUri  = $collectionUri
                ProjectName    = $projectName
                RepositoryName = $repositoryName
                BranchName     = $project.branchName
                Message        = $project.message
                Files          = $filesContent
                Rollback       = $Rollback.IsPresent
                Confirm        = $ConfirmPreference
                WhatIf         = $WhatIfPreference
                Verbose        = $VerbosePreference
            }

            & (Join-Path $PSScriptRoot -ChildPath $TemplateFile) @scriptParams
        }
    } catch {
        throw $_
    }
}

end {
    Write-Verbose "[Exit]: ./$($MyInvocation.MyCommand.Name)"
}
