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
    Write-Verbose ('Command : {0}' -f $MyInvocation.MyCommand.Name)
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
        & (Join-Path $PSScriptRoot -ChildPath $templateFile) @params -Remove:$Remove.IsPresent -Force:$Force.IsPresent

    } catch {
        throw $_
    }
}

end {
    Write-Verbose ('Exit : {0}' -f $MyInvocation.MyCommand.Name)
}
