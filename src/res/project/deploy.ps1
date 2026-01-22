[CmdletBinding(SupportsShouldProcess)]
param (
    [Parameter()]
    [string]$TemplateFile = 'main.ps1',

    [Parameter()]
    [string]$TemplateParameterFile = 'params/main.parameters.json',

    [Parameter()]
    [string]$ConfigFile = '../../../config/main.config.json',

    [Parameter()]
    [switch]$Rollback
)

begin {
    Write-Verbose "[Enter]: ./$($MyInvocation.MyCommand.Name)"

    # Import utility functions
    . (Join-Path $PSScriptRoot -ChildPath '../../utl/Set-PlaceholderValue.ps1' -ErrorAction Stop)
}

process {
    try {
        # Load configuration from JSON file
        $configAsJson = Get-Content -Path (Join-Path $PSScriptRoot -ChildPath $ConfigFile) -Raw

        # Load parameters from JSON file
        $paramsAsJson = Get-Content -Path (Join-Path $PSScriptRoot -ChildPath $TemplateParameterFile) -Raw

        # Replace placeholders in parameters using utility function
        $paramsAsJson = Set-PlaceholderValue -ParamsJson $paramsAsJson -ConfigJson $configAsJson

        # Convert JSON string to Hashtable
        $params = $paramsAsJson | ConvertFrom-Json

        Write-Verbose "Using params: $($params | ConvertTo-Json -Depth 5)"

        # Extract common parameters
        $collectionUri = $params.collectionUri
        $projects = $params.projects

        if ($null -eq $projects -or $projects.Count -eq 0) {
            throw 'No projects found in parameter file. At least one project is required.'
        }

        Write-Verbose "Processing $($projects.Count) project(s) via pipeline..."

        # Convert PSCustomObject properties to Hashtables for pipeline binding
        $projects = $projects | ForEach-Object {
            if ($_.features -and $_.features -is [PSCustomObject]) {
                $features = @{}
                $_.features.PSObject.Properties | ForEach-Object {
                    $features[$_.Name] = $_.Value
                }
                $_.features = $features
            }; $_
        }

        # Prepare script parameters for common values
        $scriptParams = @{
            CollectionUri = $collectionUri
            Rollback      = $Rollback.IsPresent
            WhatIf        = $WhatIfPreference
            Confirm       = $ConfirmPreference
            Verbose       = $VerbosePreference
        }

        # Pipe projects to main.ps1
        $projects | & (Join-Path $PSScriptRoot -ChildPath $TemplateFile) @scriptParams
    } catch {
        throw $_
    }
}

end {
    Write-Verbose "[Exit]: ./$($MyInvocation.MyCommand.Name)"
}
