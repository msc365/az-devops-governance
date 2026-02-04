[CmdletBinding(SupportsShouldProcess)]
param (
    [Parameter()]
    [string]$Location = "$($env:LOCATION)",

    [Parameter()]
    [string]$SubscriptionId = "$($env:SUBSCRIPTION_ID)",

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
    $params = [ordered]@{
        Location              = $Location
        SubscriptionId        = $SubscriptionId
        TemplateFile          = $TemplateFile
        TemplateParameterFile = $TemplateParameterFile
    } | ConvertTo-Json -Depth 3

    Write-Verbose "[Enter]: $($MyInvocation.MyCommand.Name) with parameters: $params"

    # Import utility functions
    . (Join-Path $PSScriptRoot -ChildPath '../../..' 'utl/Set-PlaceholderValue.ps1' -ErrorAction Stop)
}

process {
    try {
        # HACK: Explicitly set -WhatIf:$false, for switching targeted subscription in the context.
        Set-AzContext -TenantId (Get-AzContext).Tenant.Id -SubscriptionId $SubscriptionId -WhatIf:$false | Out-Null

        $ctx = Get-AzContext
        $ctxInfo = [ordered]@{
            Account      = $ctx.Account.Id
            Tenant       = $ctx.Tenant.Id
            Subscription = $ctx.Subscription.Name
        }
        Write-Verbose "Call Main.ps1 deployment with context: $($ctxInfo | ConvertTo-Json -Depth 3)"

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

            $endpoints = $project.endpoints
            if ($null -eq $endpoints -or $endpoints.Count -eq 0) {
                throw "Project '$projectName' does not define any endpoints."
            }

            Write-Verbose "Processing $($endpoints.Count) endpoint(s)..."

            $scriptParams = @{
                CollectionUri = $collectionUri
                ProjectName   = $projectName
                Rollback      = $Rollback.IsPresent
                Confirm       = $ConfirmPreference
                WhatIf        = $WhatIfPreference
                Verbose       = $VerbosePreference
            }

            $endpoints | & (Join-Path $PSScriptRoot -ChildPath $TemplateFile) @scriptParams
        }
    } catch {
        throw $_
    }
}

end {
    Write-Verbose "[Exit]: ./$($MyInvocation.MyCommand.Name)"
}
