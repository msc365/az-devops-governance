[CmdletBinding()]
param (
    [Parameter()]
    [switch]$RemoveDeployment
)

begin {
    Write-Debug ('Command : {0}' -f $MyInvocation.MyCommand.Name)

    $templateFile = 'main.ps1'
    $templateParameterFile = 'params\main.parameters.json'
}

process {
    try {
        # Load parameters from JSON file
        $paramsFromJson = Get-Content -Path (Join-Path $PSScriptRoot -ChildPath $templateParameterFile) -Raw

        Write-Verbose 'Using params:'
        Write-Verbose $paramsFromJson

        # Convert JSON string to Hashtable
        $params = $paramsFromJson | ConvertFrom-Json -AsHashtable

        # Execute the deployment template with parameters
        & (Join-Path $PSScriptRoot -ChildPath $templateFile) @params -RemoveDeployment:$RemoveDeployment.IsPresent

    } catch {
        throw $_
    }
}

end {
    Write-Debug ('Exit : {0}' -f $MyInvocation.MyCommand.Name)
}
