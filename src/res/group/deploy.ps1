[CmdletBinding(SupportsShouldProcess)]
param (
    [Parameter()]
    [string]$templateFile = 'main.ps1',

    [Parameter()]
    [string]$templateParameterFile = 'params\main.parameters.json',

    [Parameter()]
    [switch]$Remove,

    [Parameter()]
    [switch]$Force
)

begin {
    Write-Verbose "[Enter]: .\$($MyInvocation.MyCommand.Name)"
}

process {
    try {
        # Load parameters from JSON file
        $paramsFromJson = Get-Content -Path (Join-Path $PSScriptRoot -ChildPath $templateParameterFile) -Raw

        Write-Verbose 'Using params:'
        Write-Verbose $paramsFromJson

        # Convert JSON string to Hashtable
        $params = $paramsFromJson | ConvertFrom-Json -AsHashtable

        # Remove $schema key if it exists
        if ($params.ContainsKey('$schema')) {
            $params.Remove('$schema') | Out-Null
        }

        # Execute the deployment template with parameters
        $params += @{
            Remove  = $Remove.IsPresent
            Force   = $Force.IsPresent
            WhatIf  = $WhatIfPreference
            Verbose = $VerbosePreference
        }

        & (Join-Path $PSScriptRoot -ChildPath $templateFile) @params

    } catch {
        throw $_
    }
}

end {
    Write-Verbose "[Exit]: .\$($MyInvocation.MyCommand.Name)"
}
