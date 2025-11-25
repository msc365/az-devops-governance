# ========== #
# Parameters #
# ========== #

$params = @{
    Organization     = 'my-org'
    ProjectId        = 'my-project'
    TeamId           = 'my-other-team'
    RemoveDeployment = $true
}

# ========= #
# Variables #
# ========= #

$rootPath = (Get-Item $PSScriptRoot).Parent.Parent.Parent.FullName

$organization = ((Get-AdoContext).Organization).Split('/')[-1]
$params['Organization'] = $organization

# ============== #
# Test Execution #
# ============== #

& (Join-Path $rootPath -ChildPath 'main.ps1') @params
