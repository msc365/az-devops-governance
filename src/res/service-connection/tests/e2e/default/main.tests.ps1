#region PARAMETERS

$params = @{
    Organization           = 'e2egov-org'
    ProjectId              = 'e2egov-prjHb72x9'
    serviceEndpointName    = 'rg-e2egov-prjHb72x9-tst-weu'
    Scope                  = '/subscriptions/00000000-0000-0000-0000-000000000000'
    ManagedServiceIdentity = @{
        Name              = 'id-e2egov-prjHb72x9-tst'
        SubscriptionId    = '00000000-0000-0000-0000-000000000000'
        ResourceGroupName = 'rg-e2egov-prjHb72x9-tst-weu'
        Location          = 'westeurope'
        Tags              = @{
            public      = 'false'
            service     = 'e2egov'
            environment = 'tst'
            security    = 'rbac'
            iac         = 'bicep'
            ci          = 'azure-pipelines'
        }
        roleAssignment    = @{
            roleDefinitionName = 'Headless Owner (DevOps CI/CD)'
            scope              = '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-e2egov-prjHb72x9-tst-weu'
        }
    }
}

#endregion

#region VARIABLES

$rootPath = (Get-Item $PSScriptRoot).Parent.Parent.Parent.FullName
$subscriptionId = (Get-AzContext).Subscription.Id

#endregion

#region OVERRIDES

$params['Scope'] = "/subscriptions/$subscriptionId"
$params['ManagedServiceIdentity']['SubscriptionId'] = $subscriptionId
$params['ManagedServiceIdentity']['roleAssignment']['scope'] = "/subscriptions/$subscriptionId/resourceGroups/rg-e2egov-prjHb72x9-tst-weu"

#endregion

#region TEST EXECUTION

& (Join-Path $rootPath -ChildPath 'main.ps1') @params -Verbose | Format-List *

#endregion
