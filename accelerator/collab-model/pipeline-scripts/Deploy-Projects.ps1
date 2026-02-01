[CmdletBinding(SupportsShouldProcess)]
param (
    [Parameter()]
    [string]$TemplateFile = 'src/res/core/project/main.ps1',

    [Parameter()]
    [string]$TemplateParameterFile = 'params/core_project.main.json',

    [Parameter()]
    [string]$ConfigFile = 'config/main.config.json',

    [Parameter()]
    [switch]$Rollback
)

begin {
    Write-Verbose "[Enter]: ./$($MyInvocation.MyCommand.Name)"

    # Import utility functions
    . (Join-Path $PSScriptRoot -ChildPath '../../..' 'src/utl/Set-PlaceholderValue.ps1')
    . (Join-Path $PSScriptRoot -ChildPath '../../..' 'src/utl/ConvertTo-Hashtable.ps1')
}

process {
    try {
        # Load configuration from JSON file
        $configAsJson = Get-Content -Path (Join-Path $PSScriptRoot -ChildPath '..' $ConfigFile) -Raw

        # Load parameters from JSON file
        $paramsAsJson = Get-Content -Path (Join-Path $PSScriptRoot -ChildPath '..' $TemplateParameterFile) -Raw

        # Replace placeholders in parameters using utility function
        $paramsAsJson = Set-PlaceholderValue -ParamsJson $paramsAsJson -ConfigJson $configAsJson

        # Convert JSON string to Hashtable
        $params = $paramsAsJson | ConvertFrom-Json

        # Normalize feature definitions so downstream scripts always receive a hashtable
        foreach ($project in $params.projects) {
            if ($null -ne $project.features) {
                $project.features = ConvertTo-Hashtable -InputObject $project.features
            }
        }

        Write-Verbose "Using params: $($params | ConvertTo-Json -Depth 5)"

        # Extract common parameters
        $collectionUri = $params.collectionUri
        $projects = $params.projects

        if ($null -eq $projects -or $projects.Count -eq 0) {
            throw 'No projects found in parameter file. At least one project is required.'
        }

        Write-Verbose "Processing $($projects.Count) project(s) via pipeline..."

        # Prepare script parameters for common values
        $scriptParams = @{
            CollectionUri = $collectionUri
            Rollback      = $Rollback.IsPresent
            WhatIf        = $WhatIfPreference
            Confirm       = $ConfirmPreference
            Verbose       = $VerbosePreference
        }

        # Pipe projects to main.ps1
        $projects | & (Join-Path $PSScriptRoot -ChildPath '../../..' $TemplateFile) @scriptParams

    } catch {
        throw $_
    }
}

end {
    Write-Verbose "[Exit]: ./$($MyInvocation.MyCommand.Name)"
}
