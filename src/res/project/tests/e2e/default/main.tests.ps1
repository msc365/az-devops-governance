# ========== #
# Parameters #
# ========== #

$params = @{
    Organization = 'MyOrg'
    Name         = 'MyProject'
    DefaultTeam  = 'MyTeam'
    Description  = 'My project description'
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
