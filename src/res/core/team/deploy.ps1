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
    . (Join-Path $PSScriptRoot -ChildPath '../../..' 'utl/Set-PlaceholderValue.ps1' -ErrorAction Stop)
}

process {
    try {
        # Load configuration from JSON file
        $configAsJson = Get-Content -Path (Join-Path $PSScriptRoot -ChildPath '../../..' $ConfigFile) -Raw

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

            $teams = $project.teams
            if ($null -eq $teams -or $teams.Count -eq 0) {
                throw "Project '$projectName' does not define any teams."
            }

            Write-Verbose "Processing $($teams.Count) team(s)..."

            $scriptParams = @{
                CollectionUri = $collectionUri
                ProjectName   = $projectName
                Rollback      = $Rollback.IsPresent
                Confirm       = $ConfirmPreference
                WhatIf        = $WhatIfPreference
                Verbose       = $VerbosePreference
            }

            $teams | & (Join-Path $PSScriptRoot -ChildPath $TemplateFile) @scriptParams
        }
    } catch {
        throw $_
    }
}

end {
    Write-Verbose "[Exit]: ./$($MyInvocation.MyCommand.Name)"
}
