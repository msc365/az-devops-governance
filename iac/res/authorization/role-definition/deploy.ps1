[CmdletBinding(SupportsShouldProcess)]
param (
    [Parameter()]
    [String]$ManagementGroupId = 'mg-alz-intermediate-prd',

    [Parameter()]
    [string]$Location = 'westeurope',

    [Parameter()]
    [String]$TemplateFile = 'iac\authorization\role-definition\main.bicep',

    [Parameter()]
    [string]$TemplateParameterFile = 'iac\authorization\role-definition\main.bicepparam'
)

begin {
    Write-Verbose ('{0} entered' -f $MyInvocation.MyCommand.Name)
    Write-Verbose '------ START SCRIPT ------' -Verbose
}

process {
    try {

        $ctx = Get-AzContext
        Write-Host 'Context'
        Write-Host ('- Account      : {0}' -f $ctx.Account)
        Write-Host ('- Tenant       : {0}' -f $ctx.Tenant.Id)
        Write-Host ('- Subscription : {0}' -f $ctx.Subscription.Name)

        Write-Verbose '------------------------------' -Verbose
        Write-Verbose 'Deploy [Role Definitions]     ' -Verbose
        Write-Verbose '------------------------------' -Verbose

        $params = @{
            Name                  = -join ('e2egov-cpdfs-deploy-{0}' -f (Get-Date -Format 'yyyyMMdd-hhmmss'))[0..63]
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
    Write-Verbose '------- END SCRIPT -------' -Verbose
    Write-Verbose ('{0} exited' -f $MyInvocation.MyCommand.Name)
}
