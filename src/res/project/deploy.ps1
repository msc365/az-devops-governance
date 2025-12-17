[CmdletBinding(SupportsShouldProcess)]
param (
    [Parameter()]
    [string]$templateFile = 'main.ps1',

    [Parameter()]
    [string]$templateParameterFile = 'params\main.parameters.json',

    [Parameter()]
    [string]$ConfigFile = '..\..\cfg\main.config.json',

    [Parameter()]
    [switch]$Rollback,

    [Parameter()]
    [switch]$Force
)

begin {
    Write-Verbose ('[Enter]: .\{0}' -f $MyInvocation.MyCommand.Name)

    # Import utility functions
    . (Join-Path $PSScriptRoot -ChildPath '..\..\utl\Set-PlaceholderValue.ps1' -ErrorAction Stop)
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
        $params = $paramsAsJson | ConvertFrom-Json -AsHashtable

        # Remove $schema key if it exists
        if ($params.ContainsKey('$schema')) {
            $params.Remove('$schema') | Out-Null
        }

        Write-Verbose 'Using params:'
        Write-Verbose ($params | ConvertTo-Json -Depth 5)

        # Execute the deployment template with parameters
        $params += @{
            Rollback = $Rollback.IsPresent
            Force    = $Force.IsPresent
            WhatIf   = $WhatIfPreference
            Verbose  = $VerbosePreference
        }

        & (Join-Path $PSScriptRoot -ChildPath $TemplateFile) @params

    } catch {
        throw $_
    }
}

end {
    Write-Verbose ('[Exit]: .\{0}' -f $MyInvocation.MyCommand.Name)
}
