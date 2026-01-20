[CmdletBinding(SupportsShouldProcess)]
[OutputType([string])]
param (
    [Parameter()]
    [string]$CustomRoleDefinitionId = "$($env:CUSTOM_ROLE_DEFINITION_ID)",

    [Parameter()]
    [string]$Location = "$($env:LOCATION)",

    [Parameter()]
    [string]$SubscriptionId = "$($env:SUBSCRIPTION_ID)",

    [Parameter()]
    [string]$TemplateFile = 'iac\res\authorization\role-assignment\rg-scope\main.bicep',

    [Parameter()]
    [string]$TemplateParameterFile = 'iac\res\authorization\role-assignment\rg-scope\params\main.bicepparam'
)

begin {
    $params = [ordered]@{
        CustomRoleDefinitionId = $CustomRoleDefinitionId
        Location               = $Location
        SubscriptionId         = $SubscriptionId
        TemplateFile           = $TemplateFile
        TemplateParameterFile  = $TemplateParameterFile
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

        $deploymentName = -join ('dep-e2egov-rarg{0:yyyyMMdd-HHmmss}' -f (Get-Date))[0..63]

        $params = @{
            Name                   = $deploymentName
            Location               = $Location
            TemplateFile           = $TemplateFile
            TemplateParameterFile  = $TemplateParameterFile
            CustomRoleDefinitionId = $CustomRoleDefinitionId
            WhatIf                 = $WhatIfPreference
            Verbose                = $VerbosePreference
        }

        New-AzDeployment @params

    } catch {
        throw $_
    }
}

end {
    Write-Verbose "[Exit]: $($MyInvocation.MyCommand.Name)"
}
