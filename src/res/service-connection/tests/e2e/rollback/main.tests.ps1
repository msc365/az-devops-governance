#region PARAMETERS

$params = @{
    CollectionUri          = 'https://dev.azure.com/e2egov-org'
    ProjectName            = 'e2egov-prjHb72x9'
    Name                   = 'rg-e2egov-prjHb72x9-tst-weu'
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
        RoleAssignments   = @(
            @{
                RoleDefinitionName = 'Reader'
                Scope              = '/subscriptions/00000000-0000-0000-0000-000000000000'
            }
            @{
                RoleDefinitionName = 'Headless Owner (DevOps CI/CD)'
                Scope              = '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-e2egov-prjHb72x9-tst-weu'
            }
        )
    }
    Rollback               = $true
    Force                  = $true
}

#endregion

#region VARIABLES

$rootPath = (Get-Item $PSScriptRoot).Parent.Parent.Parent.FullName
$subscriptionId = (Get-AzContext).Subscription.Id

#endregion

#region OVERRIDES

$params['Scope'] = "/subscriptions/$subscriptionId"
$params['ManagedServiceIdentity']['SubscriptionId'] = $subscriptionId
$params['ManagedServiceIdentity']['RoleAssignments'][0]['Scope'] = "/subscriptions/$subscriptionId"
$params['ManagedServiceIdentity']['RoleAssignments'][1]['Scope'] = "/subscriptions/$subscriptionId/resourceGroups/rg-e2egov-prjHb72x9-tst-weu"

#endregion

#region TEST EXECUTION

& (Join-Path $rootPath -ChildPath 'main.ps1') @params -Verbose | Format-List *

#endregion
