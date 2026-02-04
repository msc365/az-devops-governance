#region PARAMETERS

$params = @{
    CollectionUri   = 'https://dev.azure.com/e2egov-org'
    ProjectName     = 'e2egov-prjE2eT3st'
    Name            = 'rg-e2egov-prjE2eT3st-tst-weu'
    ManagedIdentity = @{
        Name                        = 'id-e2egov-prjE2eT3st-tst'
        SubscriptionId              = '00000000-0000-0000-0000-000000000000'
        ResourceGroupName           = 'rg-e2egov-prjE2eT3st-tst-weu'
        FederatedIdentityCredential = @{
            Name = 'fic-e2egov-prjE2eT3st-tst'
        }
    }
}

#endregion

#region VARIABLES

$rootPath = (Get-Item $PSScriptRoot).Parent.Parent.Parent.FullName
$subscriptionId = (Get-AzContext).Subscription.Id

#endregion

#region OVERRIDES

$params['ManagedIdentity']['SubscriptionId'] = $subscriptionId

#endregion

#region TEST EXECUTION

& (Join-Path $rootPath -ChildPath 'main.ps1') @params -Verbose | Format-List *

#endregion
