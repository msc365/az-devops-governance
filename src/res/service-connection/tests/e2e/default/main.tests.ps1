#region PARAMETERS

$params = @{
    Organization           = 'msc365'
    ProjectId              = 'my-project'
    serviceEndpointName    = 'my-project-tst-weu'
    Scope                  = '/subscriptions/00000000-0000-0000-0000-000000000000'
    ManagedServiceIdentity = @{
        Name              = 'id-my-project-tst-weu'
        SubscriptionId    = '00000000-0000-0000-0000-000000000000'
        ResourceGroupName = 'rg-my-project-tst-weu'
        Location          = 'westeurope'
        Tags              = @{
            public      = 'false'
            service     = 'my-project'
            environment = 'tst'
            security    = 'rbac'
            iac         = 'bicep'
            ci          = 'azure-pipelines'
        }
        roleAssignment    = @{
            roleDefinitionName = 'Headless Owner (DevOps CI/CD)'
            scope              = '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-my-project-tst-weu'
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
$params['ManagedServiceIdentity']['roleAssignment']['scope'] = "/subscriptions/$subscriptionId/resourceGroups/rg-my-project-tst-weu"

$params['Verbose'] = $true

#endregion

#region TEST EXECUTION

& (Join-Path $rootPath -ChildPath 'main.ps1') @params

#endregion
