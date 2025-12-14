[CmdletBinding(SupportsShouldProcess)]
param (
    [Parameter()]
    [string]$TemplateFile = 'main.ps1',

    [Parameter()]
    [string]$TemplateParameterFile = 'params\main.parameters.json',

    [Parameter()]
    [switch]$Rollback,

    [Parameter()]
    [switch]$Force
)

begin {
    Write-Verbose ('[Enter] .\src\res\service-connection\{0}' -f $MyInvocation.MyCommand.Name)
}

process {
    try {
        # Load parameters from JSON file
        $paramsFromJson = Get-Content -Path (Join-Path $PSScriptRoot -ChildPath $TemplateParameterFile) -Raw

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
    Write-Verbose ('[Exit]: .\src\res\service-connection\{0}' -f $MyInvocation.MyCommand.Name)
}
