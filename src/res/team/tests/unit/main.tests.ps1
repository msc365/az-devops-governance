#Requires -Version 7.0

BeforeAll {
    # Import the script under test
    $script:scriptPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\main.ps1'

    # Create mock functions for Azure DevOps cmdlets before importing the script
    function Get-AdoProject { }
    function Get-AdoTeam { }
    function New-AdoTeam { }
    function Set-AdoTeam { }
    function Remove-AdoTeam { }

    # Mock all external dependencies
    Mock -CommandName Get-AzContext -MockWith {
        [PSCustomObject]@{
            Tenant       = @{ Id = '11111111-1111-1111-1111-111111111111' }
            Subscription = @{
                Id   = '22222222-2222-2222-2222-222222222222'
                Name = 'Test Subscription'
            }
        }
    }

    Mock -CommandName Import-Module
    Mock -CommandName Get-Module -MockWith { $true }
    Mock -CommandName Start-Sleep

    Mock -CommandName Get-AdoProject -MockWith {
        [PSCustomObject]@{
            id          = 'proj-123'
            name        = 'test-project'
            defaultTeam = @{
                id   = 'default-team-456'
                name = 'test-project Team'
            }
        }
    }

    # Store original nested scripts and create mock versions
    $modulesPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\modules'
    $script:originalScripts = @{}

    # Backup and mock nested_teamSettings.ps1
    $teamSettingsPath = Join-Path -Path $modulesPath -ChildPath 'nested_teamSettings.ps1'
    if (Test-Path $teamSettingsPath) {
        $script:originalScripts['teamSettings'] = Get-Content -Path $teamSettingsPath -Raw
        @'
[CmdletBinding(SupportsShouldProcess)]
param($CollectionUri, $Project, $Team, $TeamSettings)
[PSCustomObject]@{ status = 'NoChange' }
'@ | Set-Content -Path $teamSettingsPath -Force
    }

    # Backup and mock nested_iterationPaths.ps1
    $iterationPathsPath = Join-Path -Path $modulesPath -ChildPath 'nested_iterationPaths.ps1'
    if (Test-Path $iterationPathsPath) {
        $script:originalScripts['iterationPaths'] = Get-Content -Path $iterationPathsPath -Raw
        @'
[CmdletBinding(SupportsShouldProcess)]
param($CollectionUri, $Project, $Team)
[PSCustomObject]@{ status = 'NoChange' }
'@ | Set-Content -Path $iterationPathsPath -Force
    }

    # Backup and mock nested_areaPaths.ps1
    $areaPathsPath = Join-Path -Path $modulesPath -ChildPath 'nested_areaPaths.ps1'
    if (Test-Path $areaPathsPath) {
        $script:originalScripts['areaPaths'] = Get-Content -Path $areaPathsPath -Raw
        @'
[CmdletBinding(SupportsShouldProcess)]
param($CollectionUri, $Project, $Team)
[PSCustomObject]@{ status = 'NoChange' }
'@ | Set-Content -Path $areaPathsPath -Force
    }
}

AfterAll {
    # Restore original nested scripts
    $modulesPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\modules'

    if ($script:originalScripts['teamSettings']) {
        $teamSettingsPath = Join-Path -Path $modulesPath -ChildPath 'nested_teamSettings.ps1'
        $script:originalScripts['teamSettings'] | Set-Content -Path $teamSettingsPath -Force
    }

    if ($script:originalScripts['iterationPaths']) {
        $iterationPathsPath = Join-Path -Path $modulesPath -ChildPath 'nested_iterationPaths.ps1'
        $script:originalScripts['iterationPaths'] | Set-Content -Path $iterationPathsPath -Force
    }

    if ($script:originalScripts['areaPaths']) {
        $areaPathsPath = Join-Path -Path $modulesPath -ChildPath 'nested_areaPaths.ps1'
        $script:originalScripts['areaPaths'] | Set-Content -Path $areaPathsPath -Force
    }

    # Clean up any .mock files if they exist
    Get-ChildItem -Path $modulesPath -Filter '*.mock' -ErrorAction SilentlyContinue | Remove-Item -Force
}

Describe 'Team DSC Script - Core Functionality' {

    Context 'DSC Scenario: Create - Team Does Not Exist' {
        BeforeEach {
            Mock -CommandName Get-AdoTeam -MockWith { $null }
            Mock -CommandName New-AdoTeam -MockWith {
                [PSCustomObject]@{
                    id          = 'team-789'
                    name        = 'Test Team'
                    description = 'Test team description'
                }
            }
            Mock -CommandName Invoke-Expression -MockWith {
                [PSCustomObject]@{
                    status = 'NoChange'
                }
            }
        }

        It 'Should create team when it does not exist' {
            # Arrange
            $params = @{
                CollectionUri = 'https://dev.azure.com/test-org'
                ProjectName   = 'test-project'
                TeamName      = 'Test Team'
                Description   = 'Test team description'
                Confirm       = $false
            }

            # Act
            $result = & $script:scriptPath @params

            # Assert
            $result.status | Should -Be 'Created'
            $result.id | Should -Be 'team-789'
            $result.name | Should -Be 'Test Team'
            $result.description | Should -Be 'Test team description'
            $result.projectName | Should -Be 'test-project'
            $result.collectionUri | Should -Be 'https://dev.azure.com/test-org'
            Should -Invoke -CommandName New-AdoTeam -Times 1
        }

        It 'Should create team with team settings' {
            # Arrange
            $teamSettings = @{
                backlogVisibilities   = @{
                    'Microsoft.EpicCategory'        = $false
                    'Microsoft.FeatureCategory'     = $true
                    'Microsoft.RequirementCategory' = $true
                }
                bugsBehavior          = 'asRequirements'
                defaultIterationMacro = '@currentIteration'
                workingDays           = @('monday', 'tuesday', 'wednesday', 'thursday', 'friday')
            }

            $params = @{
                CollectionUri = 'https://dev.azure.com/test-org'
                ProjectName   = 'test-project'
                TeamName      = 'Test Team'
                Description   = 'Test team description'
                TeamSettings  = $teamSettings
                Confirm       = $false
            }

            # Act
            $result = & $script:scriptPath @params

            # Assert
            $result.status | Should -Be 'Created'
            $result.id | Should -Be 'team-789'
            Should -Invoke -CommandName New-AdoTeam -Times 1
        }
    }

    Context 'DSC Scenario: Update - Team Exists with Different Description' {
        BeforeEach {
            Mock -CommandName Get-AdoTeam -MockWith {
                [PSCustomObject]@{
                    id          = 'team-789'
                    name        = 'Test Team'
                    description = 'Old description'
                }
            }
            Mock -CommandName Set-AdoTeam -MockWith {
                [PSCustomObject]@{
                    id          = 'team-789'
                    name        = 'Test Team'
                    description = 'New description'
                }
            }
            Mock -CommandName Invoke-Expression -MockWith {
                [PSCustomObject]@{
                    status = 'NoChange'
                }
            }
        }

        It 'Should update team description when it changes' {
            # Arrange
            $params = @{
                CollectionUri = 'https://dev.azure.com/test-org'
                ProjectName   = 'test-project'
                TeamName      = 'Test Team'
                Description   = 'New description'
                Confirm       = $false
            }

            # Act
            $result = & $script:scriptPath @params

            # Assert
            $result.status | Should -Be 'Updated'
            $result.id | Should -Be 'team-789'
            $result.description | Should -Be 'New description'
            Should -Invoke -CommandName Set-AdoTeam -Times 1
        }
    }

    Context 'DSC Scenario: NoChange - Team Exists with Same Configuration' {
        BeforeEach {
            Mock -CommandName Get-AdoTeam -MockWith {
                [PSCustomObject]@{
                    id          = 'team-789'
                    name        = 'Test Team'
                    description = 'Test team description'
                }
            }
            Mock -CommandName Set-AdoTeam
            Mock -CommandName New-AdoTeam
        }

        It 'Should return NoChange when team exists with same description' {
            # Arrange
            $params = @{
                CollectionUri = 'https://dev.azure.com/test-org'
                ProjectName   = 'test-project'
                TeamName      = 'Test Team'
                Description   = 'Test team description'
                Confirm       = $false
            }

            # Act
            $result = & $script:scriptPath @params

            # Assert
            $result.status | Should -Be 'NoChange'
            $result.id | Should -Be 'team-789'
            Should -Invoke -CommandName Set-AdoTeam -Times 0
            Should -Invoke -CommandName New-AdoTeam -Times 0
        }

        It 'Should not update when description is not provided and team exists' {
            # Arrange
            $params = @{
                CollectionUri = 'https://dev.azure.com/test-org'
                ProjectName   = 'test-project'
                TeamName      = 'Test Team'
                Confirm       = $false
            }

            # Act
            $result = & $script:scriptPath @params

            # Assert
            $result.status | Should -Be 'NoChange'
            Should -Invoke -CommandName Set-AdoTeam -Times 0
        }
    }

    Context 'DSC Scenario: Rollback - Remove Existing Team' {
        BeforeEach {
            Mock -CommandName Get-AdoTeam -MockWith {
                [PSCustomObject]@{
                    id          = 'team-789'
                    name        = 'Test Team'
                    description = 'Test team description'
                }
            }
            Mock -CommandName Remove-AdoTeam
        }

        It 'Should remove team when rollback is requested' {
            # Arrange
            $params = @{
                CollectionUri = 'https://dev.azure.com/test-org'
                ProjectName   = 'test-project'
                TeamName      = 'Test Team'
                Rollback      = $true
                Confirm       = $false
            }

            # Act
            $result = & $script:scriptPath @params

            # Assert
            $result.status | Should -Be 'Removed'
            $result.id | Should -Be 'team-789'
            $result.name | Should -Be 'Test Team'
            Should -Invoke -CommandName Remove-AdoTeam -Times 1
        }

        It 'Should return NotFound when team does not exist during rollback' {
            # Arrange
            Mock -CommandName Get-AdoTeam -MockWith { $null }
            $params = @{
                CollectionUri = 'https://dev.azure.com/test-org'
                ProjectName   = 'test-project'
                TeamName      = 'Test Team'
                Rollback      = $true
                Confirm       = $false
            }

            # Act
            $result = & $script:scriptPath @params

            # Assert
            $result.status | Should -Be 'NotFound'
            $result.name | Should -Be 'Test Team'
            $result.id | Should -BeNullOrEmpty
            Should -Invoke -CommandName Remove-AdoTeam -Times 0
        }
    }
}

Describe 'Team DSC Script - Parameter Validation' {

    Context 'When required parameters are missing' {
        BeforeEach {
            # Clear environment variables to test parameter validation
            $env:DefaultAdoCollectionUri = $null
            $env:DefaultAdoProjectName = $null
        }

        AfterEach {
            # Restore environment variables
            $env:DefaultAdoCollectionUri = 'https://dev.azure.com/test-org'
            $env:DefaultAdoProjectName = 'test-project'
        }

        It 'Should throw when CollectionUri is not provided' {
            # Arrange
            $params = @{
                ProjectName = 'test-project'
                TeamName    = 'Test Team'
                Confirm     = $false
            }

            # Act & Assert
            { & $script:scriptPath @params } | Should -Throw -ExpectedMessage '*CollectionUri is required*'
        }

        It 'Should throw when ProjectName is not provided' {
            # Arrange
            $params = @{
                CollectionUri = 'https://dev.azure.com/test-org'
                TeamName      = 'Test Team'
                Confirm       = $false
            }

            # Act & Assert
            { & $script:scriptPath @params } | Should -Throw -ExpectedMessage '*ProjectName is required*'
        }

        It 'Should validate TeamName parameter is mandatory via metadata' {
            # Arrange
            $metadata = (Get-Command $script:scriptPath).Parameters['TeamName']

            # Assert
            $metadata.Attributes.Mandatory | Should -Contain $true
        }
    }
}

Describe 'Team DSC Script - Azure Context Validation' {

    Context 'When Azure context is invalid' {
        It 'Should throw when no Azure context exists' {
            # Arrange
            Mock -CommandName Get-AzContext -MockWith { $null }
            $params = @{
                CollectionUri = 'https://dev.azure.com/test-org'
                ProjectName   = 'test-project'
                TeamName      = 'Test Team'
                Confirm       = $false
            }

            # Act & Assert
            { & $script:scriptPath @params } | Should -Throw -ExpectedMessage '*No Azure context found*'
        }
    }
}

Describe 'Team DSC Script - Project Validation' {

    Context 'When project does not exist' {
        It 'Should throw when project is not found' {
            # Arrange
            Mock -CommandName Get-AdoProject -MockWith { $null }
            $params = @{
                CollectionUri = 'https://dev.azure.com/test-org'
                ProjectName   = 'nonexistent-project'
                TeamName      = 'Test Team'
                Confirm       = $false
            }

            # Act & Assert
            { & $script:scriptPath @params } | Should -Throw -ExpectedMessage '*Project with ID nonexistent-project does not exist*'
        }
    }
}
