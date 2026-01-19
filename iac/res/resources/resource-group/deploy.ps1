[CmdletBinding(SupportsShouldProcess)]
[OutputType([string])]
param (
    [Parameter()]
    [string]$Location = "$($env:LOCATION)",

    [Parameter()]
    [string]$SubscriptionId = "$($env:SUBSCRIPTION_ID)",

    [Parameter()]
    [string]$TemplateFile = 'iac\res\resources\resource-group\main.bicep',

    [Parameter()]
    [string]$TemplateParameterFile = 'iac\res\resources\resource-group\params\main.bicepparam'
)

begin {
    Write-Verbose "[Enter]: $($MyInvocation.MyCommand.Name)"
    Write-Verbose "Location: $($Location)"
    Write-Verbose "SubscriptionId: $($SubscriptionId)"
    Write-Verbose "TemplateFile: $($TemplateFile)"
    Write-Verbose "TemplateParameterFile: $($TemplateParameterFile)"
}

process {
    try {
        # HACK: Explicitly set -WhatIf:$false, for switching targeted subscription in the context.
        Set-AzContext -TenantId (Get-AzContext).Tenant.Id -SubscriptionId $SubscriptionId -WhatIf:$false | Out-Null

        $ctx = Get-AzContext
        $ctxInfo = @{
            Account      = $ctx.Account.Id
            Tenant       = $ctx.Tenant.Id
            Subscription = $ctx.Subscription.Name
        }
        Write-Verbose "Call New-AzDeployment within context: $($ctxInfo | ConvertTo-Json -Depth 3)"

        $deploymentName = -join ('dep-e2egov-rrg{0:yyyyMMdd-HHmmss}' -f (Get-Date))[0..63]

        $params = @{
            Name                  = $deploymentName
            Location              = $Location
            TemplateFile          = $TemplateFile
            TemplateParameterFile = $TemplateParameterFile
            WhatIf                = $WhatIfPreference
            Verbose               = $VerbosePreference
        }

        New-AzDeployment @params

    } catch {
        throw $_
    }
}

end {
    Write-Verbose "[Exit]: $($MyInvocation.MyCommand.Name)"
}
