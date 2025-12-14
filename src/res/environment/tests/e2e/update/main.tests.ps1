# ========== #
# Parameters #
# ========== #

$params = @{
    Name          = 'my-project-tst'
    Description   = 'Test environment for my-project - Updated'
    ResourceGroup = @{
        Name           = 'rg-my-project-tst-weu'
        Location       = 'westeurope'
        SubscriptionId = '00000000-0000-0000-0000-000000000000'
        Tags           = @{
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

$subscriptionId = (Get-AzContext).Subscription.Id
$params['SubscriptionId'] = $subscriptionId

# ============== #
# Test Execution #
# ============== #

& (Join-Path $rootPath -ChildPath 'main.ps1') @params
