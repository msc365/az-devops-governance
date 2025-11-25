# ========== #
# Parameters #
# ========== #

$params = @{
    Organization = 'my-org'
    ProjectId    = 'my-project'
    TeamId       = 'my-other-team'
    Description  = 'My other team description updated'
    Settings     = @{
        bugsBehavior          = 'asRequirements'
        backlogVisibilities   = @{
            'Microsoft.EpicCategory'        = $true
            'Microsoft.FeatureCategory'     = $true
            'Microsoft.RequirementCategory' = $true
        }
        defaultIterationMacro = '@currentIteration'
        workingDays           = @(
            'monday'
            'tuesday'
            'wednesday'
        )
    }
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
