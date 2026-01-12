#Requires -Version 7.0

BeforeAll {
    # Import the script under test
    $script:scriptPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\main.ps1'

    # Create mock functions for Azure DevOps cmdlets before importing the script
    function Get-AdoEnvironment { }
    function New-AdoEnvironment { }
    function Set-AdoEnvironment { }
    function Remove-AdoEnvironment { }

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

    Mock -CommandName Set-AzContext -MockWith {
        param($TenantId, $SubscriptionId)
        [PSCustomObject]@{
            Tenant       = @{ Id = $TenantId }
            Subscription = @{
                Id   = $SubscriptionId
                Name = 'Switched Subscription'
            }
        }
    }

    Mock -CommandName Import-Module
    Mock -CommandName Get-Module -MockWith { $true }
    Mock -CommandName Start-Sleep
    Mock -CommandName Get-AdoEnvironment
    Mock -CommandName New-AdoEnvironment
    Mock -CommandName Set-AdoEnvironment
    Mock -CommandName Remove-AdoEnvironment
    Mock -CommandName Join-Path -ParameterFilter { $Path -like '*resource-group*' } -MockWith {
        # Return a path that we'll intercept with a function mock
        'MockResourceGroupScript'
    }

    # Create a mock function that will be called instead of the actual script
    function MockResourceGroupScript {
        param($Name, $Location, $Rollback, $WhatIf, $Verbose, $Tags, $Confirm)
        [PSCustomObject]@{
            ResourceGroupName = $Name
            Location          = $Location
            ResourceId        = "/subscriptions/33333333-3333-3333-3333-333333333333/resourceGroups/$Name"
            SubscriptionId    = '33333333-3333-3333-3333-333333333333'
        }
    }

    Mock -CommandName Invoke-Expression -MockWith { }
}

Describe 'Environment DSC Script - Core Functionality' {

    Context 'DSC Scenario: Create - Environment Does Not Exist' {
        BeforeEach {
            Mock -CommandName Get-AdoEnvironment -MockWith { $null }
            Mock -CommandName New-AdoEnvironment -MockWith {
                [PSCustomObject]@{
                    id             = 123
                    name           = 'env-test'
                    description    = 'Test environment'
                    createdBy      = 'test@example.com'
                    createdOn      = '2026-01-11T10:00:00Z'
                    lastModifiedBy = 'test@example.com'
                    lastModifiedOn = '2026-01-11T10:00:00Z'
                }
            }
        }

        It 'Should create environment with required parameters' {
            # Arrange
            $params = @{
                CollectionUri = 'https://dev.azure.com/test-org'
                ProjectName   = 'test-project'
                Name          = 'env-test'
                Confirm       = $false
            }

            # Act
            $result = & $script:scriptPath @params

            # Assert
            $result.id | Should -Be 123
            $result.name | Should -Be 'env-test'
            $result.status | Should -Be 'Created'
            Should -Invoke -CommandName New-AdoEnvironment -Times 1
        }

        It 'Should create environment with description' {
            # Arrange
            $params = @{
                CollectionUri = 'https://dev.azure.com/test-org'
                ProjectName   = 'test-project'
                Name          = 'env-test'
                Description   = 'Test description'
                Confirm       = $false
            }

            # Act
            $result = & $script:scriptPath @params

            # Assert
            $result.description | Should -Be 'Test environment'
            Should -Invoke -CommandName New-AdoEnvironment -Times 1
        }
    }

    Context 'DSC Scenario: Update - Environment Exists with Different Properties' {
        BeforeEach {
            Mock -CommandName Get-AdoEnvironment -MockWith {
                [PSCustomObject]@{
                    id          = 456
                    name        = 'env-existing'
                    description = 'Old description'
                }
            }
            Mock -CommandName Set-AdoEnvironment -MockWith {
                [PSCustomObject]@{
                    id             = 456
                    name           = 'env-existing'
                    description    = 'New description'
                    lastModifiedBy = 'test@example.com'
                    lastModifiedOn = '2026-01-11T11:00:00Z'
                }
            }
        }

        It 'Should update environment when description changes' {
            # Arrange
            $params = @{
                CollectionUri = 'https://dev.azure.com/test-org'
                ProjectName   = 'test-project'
                Name          = 'env-existing'
                Description   = 'New description'
                Confirm       = $false
            }

            # Act
            $result = & $script:scriptPath @params

            # Assert
            $result.status | Should -Be 'Updated'
            Should -Invoke -CommandName Set-AdoEnvironment -Times 1
        }

        It 'Should not update when no changes detected' {
            # Arrange
            $params = @{
                CollectionUri = 'https://dev.azure.com/test-org'
                ProjectName   = 'test-project'
                Name          = 'env-existing'
                Confirm       = $false
            }

            # Act
            $result = & $script:scriptPath @params

            # Assert
            $result.status | Should -Be 'NoChange'
            Should -Invoke -CommandName Set-AdoEnvironment -Times 0
        }
    }

    Context 'DSC Scenario: Rollback - Remove Environment' {
        BeforeEach {
            Mock -CommandName Get-AdoEnvironment -MockWith {
                [PSCustomObject]@{
                    id   = 789
                    name = 'env-to-remove'
                }
            }
            Mock -CommandName Remove-AdoEnvironment
        }

        It 'Should remove existing environment' {
            # Arrange
            $params = @{
                CollectionUri = 'https://dev.azure.com/test-org'
                ProjectName   = 'test-project'
                Name          = 'env-to-remove'
                Rollback      = $true
                Confirm       = $false
            }

            # Act
            $result = & $script:scriptPath @params

            # Assert
            $result.status | Should -Be 'Removed'
            $result.action | Should -Be 'Rollback'
            Should -Invoke -CommandName Remove-AdoEnvironment -Times 1
        }

        It 'Should handle rollback when environment does not exist' {
            # Arrange
            Mock -CommandName Get-AdoEnvironment -MockWith { $null }
            $params = @{
                CollectionUri = 'https://dev.azure.com/test-org'
                ProjectName   = 'test-project'
                Name          = 'env-nonexistent'
                Rollback      = $true
                Confirm       = $false
            }

            # Act
            $result = & $script:scriptPath @params

            # Assert
            $result.status | Should -Be 'NotFound'
            Should -Invoke -CommandName Remove-AdoEnvironment -Times 0
        }
    }
}

Describe 'Environment DSC Script - Parameter Validation' {

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
                Name        = 'env-test'
                Confirm     = $false
            }

            # Act & Assert
            { & $script:scriptPath @params } | Should -Throw -ExpectedMessage '*CollectionUri is required*'
        }

        It 'Should throw when ProjectName is not provided' {
            # Arrange
            $params = @{
                CollectionUri = 'https://dev.azure.com/test-org'
                Name          = 'env-test'
                Confirm       = $false
            }

            # Act & Assert
            { & $script:scriptPath @params } | Should -Throw -ExpectedMessage '*ProjectName is required*'
        }

        It 'Should validate Name parameter is mandatory via metadata' {
            # Arrange
            $metadata = (Get-Command $script:scriptPath).Parameters['Name']

            # Assert
            $metadata.Attributes.Mandatory | Should -Contain $true
        }
    }
}

Describe 'Environment DSC Script - Azure Context Validation' {

    Context 'When Azure context is invalid' {
        It 'Should throw when no Azure context exists' {
            # Arrange
            Mock -CommandName Get-AzContext -MockWith { $null }
            $params = @{
                CollectionUri = 'https://dev.azure.com/test-org'
                ProjectName   = 'test-project'
                Name          = 'env-test'
                Confirm       = $false
            }

            # Act & Assert
            { & $script:scriptPath @params } | Should -Throw -ExpectedMessage '*No Azure context found*'
        }

        It 'Should throw when no active subscription exists' {
            # Arrange
            Mock -CommandName Get-AzContext -MockWith {
                [PSCustomObject]@{
                    Tenant       = @{ Id = '11111111-1111-1111-1111-111111111111' }
                    Subscription = $null
                }
            }
            $params = @{
                CollectionUri = 'https://dev.azure.com/test-org'
                ProjectName   = 'test-project'
                Name          = 'env-test'
                Confirm       = $false
            }

            # Act & Assert
            { & $script:scriptPath @params } | Should -Throw -ExpectedMessage '*No active Azure subscription*'
        }
    }
}

Describe 'Environment DSC Script - ResourceGroup Integration' {

    Context 'When ResourceGroup parameter is provided' {
        BeforeEach {
            Mock -CommandName Get-AdoEnvironment -MockWith { $null }
            Mock -CommandName New-AdoEnvironment -MockWith {
                [PSCustomObject]@{
                    id   = 999
                    name = 'env-with-rg'
                }
            }
        }

        It 'Should throw when ResourceGroup is missing required properties' {
            # Arrange
            $params = @{
                CollectionUri = 'https://dev.azure.com/test-org'
                ProjectName   = 'test-project'
                Name          = 'env-test'
                ResourceGroup = @{
                    name = 'rg-test'
                }
                Confirm       = $false
            }

            # Act & Assert
            { & $script:scriptPath @params } | Should -Throw -ExpectedMessage '*missing required property*'
        }

        It 'Should throw when subscription ID format is invalid' {
            # Arrange
            $params = @{
                CollectionUri = 'https://dev.azure.com/test-org'
                ProjectName   = 'test-project'
                Name          = 'env-test'
                ResourceGroup = @{
                    name           = 'rg-test'
                    location       = 'westeurope'
                    subscriptionId = 'invalid-guid'
                }
                Confirm       = $false
            }

            # Act & Assert
            { & $script:scriptPath @params } | Should -Throw -ExpectedMessage '*Invalid subscription ID format*'
        }

        It 'Should create environment with resource group when subscriptions match' {
            # Arrange
            $params = @{
                CollectionUri = 'https://dev.azure.com/test-org'
                ProjectName   = 'test-project'
                Name          = 'env-with-rg'
                ResourceGroup = @{
                    name           = 'rg-test'
                    location       = 'westeurope'
                    subscriptionId = '22222222-2222-2222-2222-222222222222' # Same as current context
                }
                Confirm       = $false
            }

            # Act
            $result = & $script:scriptPath @params

            # Assert
            $result.resourceGroup.name | Should -Be 'rg-test'
            $result.resourceGroup.location | Should -Be 'westeurope'
            Should -Invoke -CommandName Set-AzContext -Times 0 # No switch needed when subscriptions match
        }
    }
}
