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

        # Convert JSON string to PSCustomObject to preserve pipeline property binding
        $params = $paramsAsJson | ConvertFrom-Json

        Write-Verbose "Using params: $($params | ConvertTo-Json -Depth 5)"

        # Extract common parameters
        $collectionUri = $params.collectionUri
        $projectName = $params.projectName
        $teams = $params.teams

        if ($null -eq $teams -or $teams.Count -eq 0) {
            throw 'No teams found in parameter file. At least one team is required.'
        }

        Write-Verbose "Processing $($teams.Count) team(s) via pipeline..."

        # Prepare script parameters for common values
        $scriptParams = @{
            CollectionUri = $collectionUri
            ProjectName   = $projectName
            Rollback      = $Rollback.IsPresent
            WhatIf        = $WhatIfPreference
            Confirm       = $ConfirmPreference
            Verbose       = $VerbosePreference
        }

        # Pipe teams to main.ps1
        $teams | & (Join-Path $PSScriptRoot -ChildPath $TemplateFile) @scriptParams
    } catch {
        throw $_
    }
}

end {
    Write-Verbose "[Exit]: ./$($MyInvocation.MyCommand.Name)"
}
