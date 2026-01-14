#Requires -Version 7.0

BeforeAll {
    # Import the script under test
    $script:scriptPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\main.ps1'

    # Create mock functions for context utilities
    function Set-AzContextInfo { }
    function Restore-AzContextInfo { }

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

    Mock -CommandName Start-Sleep
    Mock -CommandName Get-AzResourceGroup
    Mock -CommandName New-AzResourceGroup
    Mock -CommandName Set-AzResourceGroup
    Mock -CommandName Set-AzContextInfo -MockWith {
        [PSCustomObject]@{
            originalContext = $null
            targetContext   = $null
            switched        = $true
        }
    }
    Mock -CommandName Restore-AzContextInfo

    # Mock the Set-AzContextInfo helper script
    $mockHelperScriptPath = Join-Path -Path $TestDrive -ChildPath 'Set-AzContextInfo.ps1'
    @'
function Set-AzContextInfo {
    param($SubscriptionId, $Verbose)
    [PSCustomObject]@{
        originalContext = $null
        targetContext   = $null
        switched        = $true
    }
}
function Restore-AzContextInfo {
    param($ContextInfo)
}
'@ | Out-File -FilePath $mockHelperScriptPath -Force

    # Mock Join-Path to return our mock script
    Mock -CommandName Join-Path -ParameterFilter {
        $ChildPath -like '*Set-AzContextInfo.ps1*'
    } -MockWith {
        $mockHelperScriptPath
    }
}

Describe 'Resource Group DSC Script - Core Functionality' {

    Context 'DSC Scenario: Create - Resource Group Does Not Exist' {
        BeforeEach {
            Mock -CommandName Get-AzResourceGroup -MockWith { $null }
            Mock -CommandName New-AzResourceGroup -MockWith {
                [PSCustomObject]@{
                    ResourceGroupName = 'rg-test-weu'
                    Location          = 'westeurope'
                    ResourceId        = '/subscriptions/22222222-2222-2222-2222-222222222222/resourceGroups/rg-test-weu'
                    Tags              = @{
                        environment = 'test'
                        owner       = 'devops'
                    }
                }
            }
        }

        It 'Should create resource group with required parameters only' {
            # Arrange
            $params = @{
                Name     = 'rg-test-weu'
                Location = 'westeurope'
                Confirm  = $false
            }

            # Act
            $result = & $script:scriptPath @params

            # Assert
            $result.name | Should -Be 'rg-test-weu'
            $result.location | Should -Be 'westeurope'
            $result.status | Should -Be 'Created'
            $result.resourceType | Should -Be 'ResourceGroup'
            Should -Invoke -CommandName New-AzResourceGroup -Times 1
        }

        It 'Should create resource group with tags' {
            # Arrange
            $tags = @{
                environment = 'test'
                owner       = 'devops'
            }
            $params = @{
                Name     = 'rg-test-weu'
                Location = 'westeurope'
                Tags     = $tags
                Confirm  = $false
            }

            # Act
            $result = & $script:scriptPath @params

            # Assert
            $result.tags.environment | Should -Be 'test'
            $result.tags.owner | Should -Be 'devops'
            $result.status | Should -Be 'Created'
            Should -Invoke -CommandName New-AzResourceGroup -Times 1
        }

        It 'Should create resource group with subscription context switch' {
            # Arrange
            $params = @{
                Name           = 'rg-test-weu'
                Location       = 'westeurope'
                SubscriptionId = '33333333-3333-3333-3333-333333333333'
                Confirm        = $false
            }

            # Act
            $result = & $script:scriptPath @params

            # Assert
            $result.status | Should -Be 'Created'
            Should -Invoke -CommandName Set-AzContextInfo -Times 1
            Should -Invoke -CommandName Restore-AzContextInfo -Times 1
        }
    }

    Context 'DSC Scenario: Update - Resource Group Exists with Different Tags' {
        BeforeEach {
            Mock -CommandName Get-AzResourceGroup -MockWith {
                [PSCustomObject]@{
                    ResourceGroupName = 'rg-existing-weu'
                    Location          = 'westeurope'
                    ResourceId        = '/subscriptions/22222222-2222-2222-2222-222222222222/resourceGroups/rg-existing-weu'
                    Tags              = @{
                        environment = 'old'
                    }
                }
            }
            Mock -CommandName Set-AzResourceGroup -MockWith {
                [PSCustomObject]@{
                    ResourceGroupName = 'rg-existing-weu'
                    Location          = 'westeurope'
                    ResourceId        = '/subscriptions/22222222-2222-2222-2222-222222222222/resourceGroups/rg-existing-weu'
                    Tags              = @{
                        environment = 'new'
                        owner       = 'platform'
                    }
                }
            }
        }

        It 'Should update resource group when tags differ' {
            # Arrange
            $newTags = @{
                environment = 'new'
                owner       = 'platform'
            }
            $params = @{
                Name     = 'rg-existing-weu'
                Location = 'westeurope'
                Tags     = $newTags
                Confirm  = $false
            }

            # Act
            $result = & $script:scriptPath @params

            # Assert
            $result.status | Should -Be 'Updated'
            Should -Invoke -CommandName Set-AzResourceGroup -Times 1
            Should -Invoke -CommandName New-AzResourceGroup -Times 0
        }

        It 'Should update when tag count differs' {
            # Arrange
            $newTags = @{
                environment = 'old'
                owner       = 'platform'
                project     = 'test'
            }
            $params = @{
                Name     = 'rg-existing-weu'
                Location = 'westeurope'
                Tags     = $newTags
                Confirm  = $false
            }

            # Act
            $result = & $script:scriptPath @params

            # Assert
            $result.status | Should -Be 'Updated'
            Should -Invoke -CommandName Set-AzResourceGroup -Times 1
        }
    }

    Context 'DSC Scenario: NoChange - Resource Group Exists with Same Tags' {
        BeforeEach {
            Mock -CommandName Get-AzResourceGroup -MockWith {
                [PSCustomObject]@{
                    ResourceGroupName = 'rg-unchanged-weu'
                    Location          = 'westeurope'
                    ResourceId        = '/subscriptions/22222222-2222-2222-2222-222222222222/resourceGroups/rg-unchanged-weu'
                    Tags              = @{
                        environment = 'test'
                        owner       = 'devops'
                    }
                }
            }
        }

        It 'Should not update when tags are identical' {
            # Arrange
            $sameTags = @{
                environment = 'test'
                owner       = 'devops'
            }
            $params = @{
                Name     = 'rg-unchanged-weu'
                Location = 'westeurope'
                Tags     = $sameTags
                Confirm  = $false
            }

            # Act
            $result = & $script:scriptPath @params

            # Assert
            $result.status | Should -Be 'NoChange'
            Should -Invoke -CommandName Set-AzResourceGroup -Times 0
            Should -Invoke -CommandName New-AzResourceGroup -Times 0
        }
    }

    Context 'DSC Scenario: Rollback - Resource Group Exists' {
        BeforeEach {
            Mock -CommandName Get-AzResourceGroup -MockWith {
                [PSCustomObject]@{
                    ResourceGroupName = 'rg-rollback-weu'
                    Location          = 'westeurope'
                    ResourceId        = '/subscriptions/22222222-2222-2222-2222-222222222222/resourceGroups/rg-rollback-weu'
                    Tags              = @{}
                }
            }
        }

        It 'Should skip deletion when rollback is requested (by design)' {
            # Arrange
            $params = @{
                Name     = 'rg-rollback-weu'
                Location = 'westeurope'
                Rollback = $true
                Confirm  = $false
            }

            # Act
            $result = & $script:scriptPath @params

            # Assert
            $result.status | Should -Be 'Skipped'
            $result.action | Should -Be 'Rollback'
            Should -Invoke -CommandName New-AzResourceGroup -Times 0
            Should -Invoke -CommandName Set-AzResourceGroup -Times 0
        }

        It 'Should return rollback result with correct structure' {
            # Arrange
            $params = @{
                Name     = 'rg-rollback-weu'
                Location = 'westeurope'
                Rollback = $true
                Confirm  = $false
            }

            # Act
            $result = & $script:scriptPath @params

            # Assert
            $result.name | Should -Be 'rg-rollback-weu'
            $result.action | Should -Be 'Rollback'
            $result.resourceType | Should -Be 'ResourceGroup'
        }
    }

    Context 'DSC Scenario: Rollback - Resource Group Does Not Exist' {
        BeforeEach {
            Mock -CommandName Get-AzResourceGroup -MockWith { $null }
        }

        It 'Should return NotFound status when resource group does not exist' {
            # Arrange
            $params = @{
                Name     = 'rg-notfound-weu'
                Location = 'westeurope'
                Rollback = $true
                Confirm  = $false
            }

            # Act
            $result = & $script:scriptPath @params

            # Assert
            $result.status | Should -Be 'NotFound'
            $result.action | Should -Be 'Rollback'
        }
    }

    Context 'Error Handling' {
        BeforeEach {
            Mock -CommandName Get-AzContext -MockWith { $null }
        }

        It 'Should throw error when no Azure context is found' {
            # Arrange
            $params = @{
                Name     = 'rg-test-weu'
                Location = 'westeurope'
                Confirm  = $false
            }

            # Act & Assert
            { & $script:scriptPath @params } | Should -Throw '*No Azure subscription context found*'
        }
    }
}

Describe 'Resource Group DSC Script - Output Validation' {

    Context 'Output Structure' {
        BeforeEach {
            Mock -CommandName Get-AzResourceGroup -MockWith { $null }
            Mock -CommandName New-AzResourceGroup -MockWith {
                [PSCustomObject]@{
                    ResourceGroupName = 'rg-output-test'
                    Location          = 'westeurope'
                    ResourceId        = '/subscriptions/22222222-2222-2222-2222-222222222222/resourceGroups/rg-output-test'
                    Tags              = @{ test = 'value' }
                }
            }
        }

        It 'Should return correctly structured output object' {
            # Arrange
            $params = @{
                Name     = 'rg-output-test'
                Location = 'westeurope'
                Tags     = @{ test = 'value' }
                Confirm  = $false
            }

            # Act
            $result = & $script:scriptPath @params

            # Assert
            $result.PSObject.Properties.Name | Should -Contain 'name'
            $result.PSObject.Properties.Name | Should -Contain 'location'
            $result.PSObject.Properties.Name | Should -Contain 'resourceId'
            $result.PSObject.Properties.Name | Should -Contain 'subscription'
            $result.PSObject.Properties.Name | Should -Contain 'tags'
            $result.PSObject.Properties.Name | Should -Contain 'resourceType'
            $result.PSObject.Properties.Name | Should -Contain 'status'
        }

        It 'Should include subscription information in output' {
            # Arrange
            $params = @{
                Name     = 'rg-output-test'
                Location = 'westeurope'
                Confirm  = $false
            }

            # Act
            $result = & $script:scriptPath @params

            # Assert
            $result.subscription.Id | Should -Be '22222222-2222-2222-2222-222222222222'
            $result.subscription.Name | Should -Be 'Test Subscription'
        }
    }
}
