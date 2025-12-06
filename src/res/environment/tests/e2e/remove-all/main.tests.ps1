# ========== #
# Parameters #
# ========== #

$params = @{
    Name          = 'my-project-tst'
    ResourceGroup = @{
        Name           = 'rg-my-project-tst-weu'
        SubscriptionId = '00000000-0000-0000-0000-000000000000'
    }
    Remove        = $true
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
