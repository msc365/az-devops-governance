[CmdletBinding(SupportsShouldProcess)]
[OutputType([string])]
param (
    [Parameter()]
    [string]$Location = "$($env:LOCATION)",

    [Parameter()]
    [string]$SubscriptionId = "$($env:SUBSCRIPTION_ID)",

    [Parameter()]
    [string]$TemplateFile = 'iac/ptn/resources/resource-group/main.bicep',

    [Parameter()]
    [string]$TemplateParameterFile = 'params/azure/resources_resource-group.main.bicepparam'
)

begin {
    $params = [ordered]@{
        Location              = $Location
        SubscriptionId        = $SubscriptionId
        TemplateFile          = $TemplateFile
        TemplateParameterFile = $TemplateParameterFile
    } | ConvertTo-Json -Depth 3

    Write-Verbose "[Enter]: $($MyInvocation.MyCommand.Name) with parameters: $params"
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
        Write-Verbose "Call New-AzDeployment with context: $($ctxInfo | ConvertTo-Json -Depth 3)"

        $deploymentName = -join ('dep-e2egov-rrg{0:yyyyMMdd-HHmmss}' -f (Get-Date))[0..63]

        $params = @{
            Name                  = $deploymentName
            Location              = $Location
            TemplateFile          = (Join-Path $PSScriptRoot -ChildPath '../../../' $TemplateFile)
            TemplateParameterFile = (Join-Path $PSScriptRoot -ChildPath '../' $TemplateParameterFile)
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
