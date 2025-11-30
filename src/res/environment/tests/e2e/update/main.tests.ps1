# ========== #
# Parameters #
# ========== #

$params = @{
    Name           = 'my-project-prd'
    SubscriptionId = '00000000-0000-0000-0000-000000000000'
    ResourceGroup  = @{
        Name     = 'rg-my-project-prd-weu'
        Location = 'westeurope'
        Tags     = @{
            public      = 'false'
            service     = 'my-project'
            environment = 'prd'
            security    = 'rbac'
            iac         = 'bicep'
            ci          = 'azure-pipelines'
            test        = 'updated' # << ADD TAG >>
        }
    }
}

# ========= #
# Variables #
# ========= #

$rootPath = (Get-Item $PSScriptRoot).Parent.Parent.Parent.FullName

$subscriptionId = (Get-AdoContext).Subscription.Id
$params['SubscriptionId'] = $subscriptionId

# ============== #
# Test Execution #
# ============== #

& (Join-Path $rootPath -ChildPath 'main.ps1') @params
