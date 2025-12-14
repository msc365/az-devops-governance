# ========== #
# Parameters #
# ========== #

$params = @{
    Name        = 'my-project-tst'
    Description = 'Test environment for my-project'
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
