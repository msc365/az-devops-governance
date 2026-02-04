[CmdletBinding(SupportsShouldProcess)]
param (
    [Parameter()]
    [string]$Location = "$($env:LOCATION)",

    [Parameter()]
    [String]$ManagementGroupId = "$($env:MANAGEMENT_GROUP_ID)",

    [Parameter()]
    [String]$TemplateFile = 'iac/ptn/authorization/role-definition/main.bicep',

    [Parameter()]
    [string]$TemplateParameterFile = 'iac/ptn/authorization/role-definition/params/main.bicepparam'
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

        $ctx = Get-AzContext
        $ctxInfo = [ordered]@{
            Account      = $ctx.Account.Id
            Tenant       = $ctx.Tenant.Id
            Subscription = $ctx.Subscription.Name
        }
        Write-Verbose "Call New-AzDeployment with context: $($ctxInfo | ConvertTo-Json -Depth 3)"

        $params = @{
            Name                  = -join ('dep-e2egov-rdf{0:yyyyMMdd-HHmmss}' -f (Get-Date))[0..63]
            Location              = $Location
            ManagementGroupId     = $ManagementGroupId
            TemplateFile          = $TemplateFile
            TemplateParameterFile = $TemplateParameterFile
            Verbose               = $VerbosePreference
            WhatIf                = $WhatIfPreference
        }

        New-AzManagementGroupDeployment @params -Verbose

    } catch {
        throw $_
    }
}

end {
    Write-Verbose "[Exit]: $($MyInvocation.MyCommand.Name)"
}
