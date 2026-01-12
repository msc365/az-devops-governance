#Requires -Version 7.0

BeforeAll {
    # Import the script under test
    $script:scriptPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\main.ps1'

    # Create mock functions for Azure DevOps cmdlets before importing the script
    function Get-AdoProject { }
    function New-AdoProject { }
    function Set-AdoProject { }
    function Set-AdoTeam { }
    function Remove-AdoProject { }
    function Get-AdoFeatureState { }
    function Set-AdoFeatureState { }

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
    Mock -CommandName Get-AdoProject
    Mock -CommandName New-AdoProject
    Mock -CommandName Set-AdoProject
    Mock -CommandName Set-AdoTeam
    Mock -CommandName Remove-AdoProject
    Mock -CommandName Get-AdoFeatureState
    Mock -CommandName Set-AdoFeatureState
}

Describe 'Project DSC Script - Core Functionality' {

    Context 'DSC Scenario: Create - Project Does Not Exist' {
        It 'Should create new project with minimal parameters' {
            # Arrange
            $script:callCount = 0
            Mock -CommandName Get-AdoProject -MockWith {
                $script:callCount++
                if ($script:callCount -eq 1) {
                    $null
                } else {
                    [PSCustomObject]@{
                        Id          = 'proj-guid-123'
                        Name        = 'TestProject'
                        Description = ''
                        Visibility  = 'Private'
                        DefaultTeam = @{ Id = 'team-guid'; Name = 'TestProject Team' }
                    }
                }
            }
            Mock -CommandName New-AdoProject -MockWith {
                [PSCustomObject]@{
                    Id          = 'proj-guid-123'
                    Name        = 'TestProject'
                    Description = ''
                    Visibility  = 'Private'
                    DefaultTeam = @{ Id = 'team-guid'; Name = 'TestProject Team' }
                }
            }
            Mock -CommandName Get-AdoFeatureState -MockWith {
                @(
                    [PSCustomObject]@{ feature = 'boards'; state = 'enabled' }
                    [PSCustomObject]@{ feature = 'repos'; state = 'enabled' }
                )
            }

            $params = @{
                CollectionUri = 'https://dev.azure.com/test-org'
                Name          = 'TestProject'
                Confirm       = $false
            }

            # Act
            $result = & $script:scriptPath @params

            # Assert
            $result.id | Should -Be 'proj-guid-123'
            $result.name | Should -Be 'TestProject'
            $result.status | Should -Be 'Created'
            Should -Invoke -CommandName New-AdoProject -Times 1
        }

        It 'Should create project with all optional parameters' {
            # Arrange
            $script:callCount = 0
            Mock -CommandName Get-AdoProject -MockWith {
                $script:callCount++
                if ($script:callCount -eq 1) {
                    $null
                } else {
                    [PSCustomObject]@{
                        Id          = 'proj-guid-456'
                        Name        = 'FullProject'
                        Description = 'Test Description'
                        Visibility  = 'Public'
                        DefaultTeam = @{ Id = 'team-guid'; Name = 'Custom Team' }
                    }
                }
            }
            Mock -CommandName New-AdoProject -MockWith {
                [PSCustomObject]@{
                    Id          = 'proj-guid-456'
                    Name        = 'FullProject'
                    Description = 'Test Description'
                    Visibility  = 'Public'
                    DefaultTeam = @{ Id = 'team-guid'; Name = 'FullProject Team' }
                }
            }
            Mock -CommandName Set-AdoTeam
            Mock -CommandName Get-AdoFeatureState -MockWith {
                @(
                    [PSCustomObject]@{ feature = 'boards'; state = 'enabled' }
                    [PSCustomObject]@{ feature = 'pipelines'; state = 'disabled' }
                )
            }

            $params = @{
                CollectionUri = 'https://dev.azure.com/test-org'
                Name          = 'FullProject'
                Description   = 'Test Description'
                DefaultTeam   = 'Custom Team'
                Process       = 'Agile'
                SourceControl = 'Git'
                Visibility    = 'Public'
                Features      = @{
                    boards    = 'enabled'
                    pipelines = 'disabled'
                }
                Confirm       = $false
            }

            # Act
            $result = & $script:scriptPath @params

            # Assert
            $result.status | Should -Be 'Created'
            $result.visibility | Should -Be 'Public'
            Should -Invoke -CommandName New-AdoProject -Times 1
            Should -Invoke -CommandName Set-AdoTeam -Times 1
        }
    }

    Context 'DSC Scenario: Update - Project Exists with Different Properties' {
        BeforeEach {
            Mock -CommandName Get-AdoFeatureState -MockWith {
                @(
                    [PSCustomObject]@{ feature = 'boards'; state = 'enabled' }
                )
            }
        }

        It 'Should update project description when changed' {
            # Arrange
            $script:callCount = 0
            Mock -CommandName Get-AdoProject -MockWith {
                $script:callCount++
                if ($script:callCount -eq 1) {
                    [PSCustomObject]@{
                        Id          = 'proj-guid-789'
                        Name        = 'ExistingProject'
                        Description = 'Old Description'
                        Visibility  = 'Private'
                        DefaultTeam = @{ Id = 'team-guid'; Name = 'ExistingProject Team' }
                    }
                } else {
                    [PSCustomObject]@{
                        Id          = 'proj-guid-789'
                        Name        = 'ExistingProject'
                        Description = 'New Description'
                        Visibility  = 'Private'
                        DefaultTeam = @{ Id = 'team-guid'; Name = 'ExistingProject Team' }
                    }
                }
            }
            Mock -CommandName Set-AdoProject

            $params = @{
                CollectionUri = 'https://dev.azure.com/test-org'
                Name          = 'ExistingProject'
                Description   = 'New Description'
                Confirm       = $false
            }

            # Act
            $result = & $script:scriptPath @params

            # Assert
            $result.status | Should -Be 'Updated'
            Should -Invoke -CommandName Set-AdoProject -Times 1
        }

        It 'Should update project visibility when changed' {
            # Arrange
            $script:callCount = 0
            Mock -CommandName Get-AdoProject -MockWith {
                $script:callCount++
                if ($script:callCount -eq 1) {
                    [PSCustomObject]@{
                        Id          = 'proj-guid-111'
                        Name        = 'PrivateProject'
                        Description = 'Description'
                        Visibility  = 'Private'
                        DefaultTeam = @{ Id = 'team-guid'; Name = 'PrivateProject Team' }
                    }
                } else {
                    [PSCustomObject]@{
                        Id          = 'proj-guid-111'
                        Name        = 'PrivateProject'
                        Description = 'Description'
                        Visibility  = 'Public'
                        DefaultTeam = @{ Id = 'team-guid'; Name = 'PrivateProject Team' }
                    }
                }
            }
            Mock -CommandName Set-AdoProject

            $params = @{
                CollectionUri = 'https://dev.azure.com/test-org'
                Name          = 'PrivateProject'
                Visibility    = 'Public'
                Confirm       = $false
            }

            # Act
            $result = & $script:scriptPath @params

            # Assert
            $result.status | Should -Be 'Updated'
            Should -Invoke -CommandName Set-AdoProject -Times 1
        }

        It 'Should update default team name when changed' {
            # Arrange
            $script:callCount = 0
            Mock -CommandName Get-AdoProject -MockWith {
                $script:callCount++
                if ($script:callCount -eq 1) {
                    [PSCustomObject]@{
                        Id          = 'proj-guid-222'
                        Name        = 'TeamProject'
                        Description = ''
                        Visibility  = 'Private'
                        DefaultTeam = @{ Id = 'team-guid-old'; Name = 'Old Team' }
                    }
                } else {
                    [PSCustomObject]@{
                        Id          = 'proj-guid-222'
                        Name        = 'TeamProject'
                        Description = ''
                        Visibility  = 'Private'
                        DefaultTeam = @{ Id = 'team-guid-old'; Name = 'New Team' }
                    }
                }
            }
            Mock -CommandName Set-AdoTeam

            $params = @{
                CollectionUri = 'https://dev.azure.com/test-org'
                Name          = 'TeamProject'
                DefaultTeam   = 'New Team'
                Confirm       = $false
            }

            # Act
            $result = & $script:scriptPath @params

            # Assert
            $result.status | Should -Be 'Updated'
            Should -Invoke -CommandName Set-AdoTeam -Times 1
        }

        It 'Should update feature states when changed' {
            # Arrange
            Mock -CommandName Get-AdoProject -MockWith {
                [PSCustomObject]@{
                    Id          = 'proj-guid-333'
                    Name        = 'FeatureProject'
                    Description = ''
                    Visibility  = 'Private'
                    DefaultTeam = @{ Id = 'team-guid'; Name = 'FeatureProject Team' }
                }
            }
            Mock -CommandName Get-AdoFeatureState -MockWith {
                @(
                    [PSCustomObject]@{ feature = 'boards'; state = 'enabled'; featureId = 'f1' }
                    [PSCustomObject]@{ feature = 'repos'; state = 'disabled'; featureId = 'f2' }
                )
            }
            Mock -CommandName Set-AdoFeatureState
            Mock -CommandName Get-AdoProject -MockWith {
                [PSCustomObject]@{
                    Id          = 'proj-guid-333'
                    Name        = 'FeatureProject'
                    Description = ''
                    Visibility  = 'Private'
                    DefaultTeam = @{ Id = 'team-guid'; Name = 'FeatureProject Team' }
                }
            } -ParameterFilter { $Name -eq 'FeatureProject' }

            $params = @{
                CollectionUri = 'https://dev.azure.com/test-org'
                Name          = 'FeatureProject'
                Features      = @{
                    boards = 'disabled'
                    repos  = 'enabled'
                }
                Confirm       = $false
            }

            # Act
            $result = & $script:scriptPath @params

            # Assert
            $result.status | Should -Be 'Updated'
            Should -Invoke -CommandName Set-AdoFeatureState -Times 2
        }
    }

    Context 'DSC Scenario: UnChanged - Project Exists with Same Properties' {
        BeforeEach {
            Mock -CommandName Get-AdoFeatureState -MockWith { @() }
        }

        It 'Should not update when description matches' {
            # Arrange
            Mock -CommandName Get-AdoProject -MockWith {
                [PSCustomObject]@{
                    Id          = 'proj-guid-444'
                    Name        = 'SameProject'
                    Description = 'Same Description'
                    Visibility  = 'Private'
                    DefaultTeam = @{ Id = 'team-guid'; Name = 'SameProject Team' }
                }
            }

            $params = @{
                CollectionUri = 'https://dev.azure.com/test-org'
                Name          = 'SameProject'
                Description   = 'Same Description'
                Confirm       = $false
            }

            # Act
            $result = & $script:scriptPath @params

            # Assert
            $result.status | Should -Be 'UnChanged'
            Should -Invoke -CommandName Set-AdoProject -Times 0
        }

        It 'Should not update when all properties match' {
            # Arrange
            Mock -CommandName Get-AdoProject -MockWith {
                [PSCustomObject]@{
                    Id          = 'proj-guid-555'
                    Name        = 'MatchProject'
                    Description = 'Match'
                    Visibility  = 'Public'
                    DefaultTeam = @{ Id = 'team-guid'; Name = 'Match Team' }
                }
            }
            Mock -CommandName Get-AdoFeatureState -MockWith {
                @(
                    [PSCustomObject]@{ feature = 'boards'; state = 'enabled'; featureId = 'f1' }
                )
            }

            $params = @{
                CollectionUri = 'https://dev.azure.com/test-org'
                Name          = 'MatchProject'
                Description   = 'Match'
                Visibility    = 'Public'
                DefaultTeam   = 'Match Team'
                Features      = @{ boards = 'enabled' }
                Confirm       = $false
            }

            # Act
            $result = & $script:scriptPath @params

            # Assert
            $result.status | Should -Be 'UnChanged'
            Should -Invoke -CommandName Set-AdoProject -Times 0
            Should -Invoke -CommandName Set-AdoTeam -Times 0
            Should -Invoke -CommandName Set-AdoFeatureState -Times 0
        }
    }

    Context 'DSC Scenario: Rollback - Remove Project' {
        It 'Should remove existing project when Rollback is specified' {
            # Arrange
            Mock -CommandName Get-AdoProject -MockWith {
                [PSCustomObject]@{
                    Id          = 'proj-guid-666'
                    Name        = 'RemoveProject'
                    Description = ''
                    Visibility  = 'Private'
                    DefaultTeam = @{ Id = 'team-guid'; Name = 'RemoveProject Team' }
                }
            }
            Mock -CommandName Remove-AdoProject

            $params = @{
                CollectionUri = 'https://dev.azure.com/test-org'
                Name          = 'RemoveProject'
                Rollback      = $true
                Confirm       = $false
            }

            # Act
            $result = & $script:scriptPath @params

            # Assert
            $result.status | Should -Be 'Removed'
            $result.action | Should -Be 'Rollback'
            Should -Invoke -CommandName Remove-AdoProject -Times 1
        }

        It 'Should return NotFound when project does not exist during rollback' {
            # Arrange
            Mock -CommandName Get-AdoProject -MockWith { $null }

            $params = @{
                CollectionUri = 'https://dev.azure.com/test-org'
                Name          = 'NonExistentProject'
                Rollback      = $true
                Confirm       = $false
            }

            # Act
            $result = & $script:scriptPath @params

            # Assert
            $result.status | Should -Be 'NotFound'
            $result.action | Should -Be 'Rollback'
            Should -Invoke -CommandName Remove-AdoProject -Times 0
        }
    }
}

Describe 'Project DSC Script - Parameter Validation' {

    Context 'When required parameters are missing' {
        BeforeEach {
            # Clear environment variables to test parameter validation
            $env:DefaultAdoCollectionUri = $null
        }

        AfterEach {
            # Restore environment variables
            $env:DefaultAdoCollectionUri = 'https://dev.azure.com/test-org'
        }

        It 'Should throw when CollectionUri is missing and env var not set' {
            # Arrange
            $params = @{
                Name    = 'Test'
                Confirm = $false
            }

            # Act & Assert
            { & $script:scriptPath @params } | Should -Throw -ExpectedMessage '*CollectionUri is required*'
        }

        It 'Should validate Name parameter is mandatory via metadata' {
            # Arrange
            $metadata = (Get-Command $script:scriptPath).Parameters['Name']

            # Assert
            $metadata.Attributes.Mandatory | Should -Contain $true
        }

        It 'Should accept valid Features hashtable' {
            # Arrange
            Mock -CommandName Get-AdoProject -MockWith { $null }
            Mock -CommandName New-AdoProject -MockWith {
                [PSCustomObject]@{
                    Id          = 'test-guid'
                    Name        = 'Test'
                    DefaultTeam = @{ Id = 'team'; Name = 'Team' }
                }
            }
            Mock -CommandName Get-AdoFeatureState -MockWith { @() }

            $features = @{
                boards    = 'enabled'
                repos     = 'disabled'
                pipelines = 'enabled'
                artifacts = 'disabled'
                testPlans = 'enabled'
            }

            $params = @{
                CollectionUri = 'https://dev.azure.com/test-org'
                Name          = 'Test'
                Features      = $features
                Confirm       = $false
            }

            # Act & Assert
            { & $script:scriptPath @params } | Should -Not -Throw
        }
    }
}

Describe 'Project DSC Script - Azure Context Validation' {

    Context 'When Azure context is invalid' {
        It 'Should throw when Azure context is not available' {
            # Arrange
            Mock -CommandName Get-AzContext -MockWith { $null }

            $params = @{
                CollectionUri = 'https://dev.azure.com/test-org'
                Name          = 'Test'
                Confirm       = $false
            }

            # Act & Assert
            { & $script:scriptPath @params } | Should -Throw -ExpectedMessage '*No Azure context found*'
        }

        It 'Should throw when no active subscription in context' {
            # Arrange
            Mock -CommandName Get-AzContext -MockWith {
                [PSCustomObject]@{
                    Tenant       = @{ Id = 'tenant-guid' }
                    Subscription = $null
                }
            }

            $params = @{
                CollectionUri = 'https://dev.azure.com/test-org'
                Name          = 'Test'
                Confirm       = $false
            }

            # Act & Assert
            { & $script:scriptPath @params } | Should -Throw -ExpectedMessage '*No active Azure subscription*'
        }
    }
}
