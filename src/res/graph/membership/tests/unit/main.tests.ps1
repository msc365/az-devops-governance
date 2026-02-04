#Requires -Version 7.0

BeforeAll {
    # Import the script under test
    $script:scriptPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\main.ps1'

    # Create mock functions for Azure DevOps cmdlets before importing the script
    function Get-AdoProject { }
    function Get-AdoDescriptor { }
    function Get-AdoGroup { }
    function Get-AdoMembership { }
    function Add-AdoGroupMember { }

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

    Mock -CommandName Get-MgContext -MockWith {
        [PSCustomObject]@{
            TenantId = '11111111-1111-1111-1111-111111111111'
        }
    }

    Mock -CommandName Get-MgGroup -MockWith {
        [PSCustomObject]@{
            Id           = '33333333-3333-3333-3333-333333333333'
            MailNickname = 'test-group'
            DisplayName  = 'Test Group'
        }
    }

    Mock -CommandName Import-Module
    Mock -CommandName Get-Module -MockWith { $true }
    Mock -CommandName Start-Sleep

    Mock -CommandName Get-AdoProject -MockWith {
        [PSCustomObject]@{
            id   = 'proj-123'
            name = 'test-project'
        }
    }

    Mock -CommandName Get-AdoDescriptor -MockWith {
        [PSCustomObject]@{
            value = 'descriptor-proj-123'
        }
    }

    Mock -CommandName Get-AdoGroup -MockWith {
        param($ScopeDescriptor, $SubjectTypes)
        if ($SubjectTypes -eq 'vssgp') {
            # Built-in groups
            @(
                [PSCustomObject]@{
                    displayName = 'Contributors'
                    descriptor  = 'descriptor-contributors'
                }
                [PSCustomObject]@{
                    displayName = 'Readers'
                    descriptor  = 'descriptor-readers'
                }
            )
        } elseif ($SubjectTypes -eq 'aadgp') {
            # Entra ID groups
            @(
                [PSCustomObject]@{
                    originId   = '33333333-3333-3333-3333-333333333333'
                    descriptor = 'descriptor-entra-group'
                }
            )
        }
    }

    Mock -CommandName Get-AdoMembership
    Mock -CommandName Add-AdoGroupMember
    Mock -CommandName Write-Warning
}

Describe 'Group Membership Script - Core Functionality' {

    Context 'DSC Scenario: Create - Membership Does Not Exist' {
        BeforeEach {
            Mock -CommandName Get-AdoMembership -MockWith { $null }
            Mock -CommandName Add-AdoGroupMember -MockWith {
                [PSCustomObject]@{
                    descriptor = 'descriptor-new-member'
                }
            }
        }

        It 'Should add group membership when it does not exist' {
            # Arrange
            $params = @{
                CollectionUri   = 'https://dev.azure.com/test-org'
                ProjectName     = 'test-project'
                UniqueName      = 'test-group'
                GroupMembership = 'Contributors'
                Confirm         = $false
            }

            # Act
            $result = & $script:scriptPath @params

            # Assert
            $result.status | Should -Be 'Created'
            $result.memberDescriptor | Should -Be 'descriptor-new-member'
            $result.containerDescriptor | Should -Be 'descriptor-contributors'
            $result.uniqueName | Should -Be 'test-group'
            $result.groupMembership | Should -Be 'Contributors'
            $result.projectName | Should -Be 'test-project'
            $result.collectionUri | Should -Be 'https://dev.azure.com/test-org'
            Should -Invoke -CommandName Add-AdoGroupMember -Times 1
        }

        It 'Should add membership to Readers group' {
            # Arrange
            $params = @{
                CollectionUri   = 'https://dev.azure.com/test-org'
                ProjectName     = 'test-project'
                UniqueName      = 'test-group'
                GroupMembership = 'Readers'
                Confirm         = $false
            }

            # Act
            $result = & $script:scriptPath @params

            # Assert
            $result.status | Should -Be 'Created'
            $result.containerDescriptor | Should -Be 'descriptor-readers'
            Should -Invoke -CommandName Add-AdoGroupMember -Times 1
        }
    }

    Context 'DSC Scenario: NoChange - Membership Already Exists' {
        BeforeEach {
            Mock -CommandName Get-AdoMembership -MockWith {
                [PSCustomObject]@{
                    memberDescriptor    = 'descriptor-existing-member'
                    containerDescriptor = 'descriptor-contributors'
                }
            }
        }

        It 'Should not add membership when it already exists' {
            # Arrange
            $params = @{
                CollectionUri   = 'https://dev.azure.com/test-org'
                ProjectName     = 'test-project'
                UniqueName      = 'test-group'
                GroupMembership = 'Contributors'
                Confirm         = $false
            }

            # Act
            $result = & $script:scriptPath @params

            # Assert
            $result.status | Should -Be 'NoChange'
            $result.memberDescriptor | Should -Be 'descriptor-existing-member'
            Should -Invoke -CommandName Add-AdoGroupMember -Times 0
        }
    }

    Context 'DSC Scenario: Rollback - Remove Membership' {
        BeforeEach {
            Mock -CommandName Get-AdoMembership -MockWith {
                [PSCustomObject]@{
                    memberDescriptor    = 'descriptor-member-to-remove'
                    containerDescriptor = 'descriptor-contributors'
                }
            }
        }

        It 'Should indicate not implemented for rollback when membership exists' {
            # Arrange
            $params = @{
                CollectionUri   = 'https://dev.azure.com/test-org'
                ProjectName     = 'test-project'
                UniqueName      = 'test-group'
                GroupMembership = 'Contributors'
                Rollback        = $true
                Confirm         = $false
            }

            # Act
            $result = & $script:scriptPath @params

            # Assert
            $result.status | Should -Be 'NotImplemented'
            $result.memberDescriptor | Should -Be 'descriptor-member-to-remove'
            Should -Invoke -CommandName Add-AdoGroupMember -Times 0
        }

        It 'Should indicate not found when membership does not exist during rollback' {
            # Arrange
            Mock -CommandName Get-AdoMembership -MockWith { $null }
            $params = @{
                CollectionUri   = 'https://dev.azure.com/test-org'
                ProjectName     = 'test-project'
                UniqueName      = 'test-group'
                GroupMembership = 'Contributors'
                Rollback        = $true
                Confirm         = $false
            }

            # Act
            $result = & $script:scriptPath @params

            # Assert
            $result.status | Should -Be 'NotFound'
            $result.memberDescriptor | Should -Be '<unknown>'
        }
    }
}

Describe 'Group Membership Script - Parameter Validation' {

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
                ProjectName     = 'test-project'
                UniqueName      = 'test-group'
                GroupMembership = 'Contributors'
                Confirm         = $false
            }

            # Act & Assert
            { & $script:scriptPath @params } | Should -Throw -ExpectedMessage '*CollectionUri is required*'
        }

        It 'Should throw when ProjectName is not provided' {
            # Arrange
            $params = @{
                CollectionUri   = 'https://dev.azure.com/test-org'
                UniqueName      = 'test-group'
                GroupMembership = 'Contributors'
                Confirm         = $false
            }

            # Act & Assert
            { & $script:scriptPath @params } | Should -Throw -ExpectedMessage '*ProjectName is required*'
        }

        It 'Should validate UniqueName parameter is mandatory via metadata' {
            # Arrange
            $metadata = (Get-Command $script:scriptPath).Parameters['UniqueName']

            # Assert
            $metadata.Attributes.Mandatory | Should -Contain $true
        }

        It 'Should validate GroupMembership parameter is mandatory via metadata' {
            # Arrange
            $metadata = (Get-Command $script:scriptPath).Parameters['GroupMembership']

            # Assert
            $metadata.Attributes.Mandatory | Should -Contain $true
        }
    }
}

Describe 'Group Membership Script - Context Validation' {

    Context 'When Azure context is invalid' {
        It 'Should throw when no Azure context exists' {
            # Arrange
            Mock -CommandName Get-AzContext -MockWith { $null }
            $params = @{
                CollectionUri   = 'https://dev.azure.com/test-org'
                ProjectName     = 'test-project'
                UniqueName      = 'test-group'
                GroupMembership = 'Contributors'
                Confirm         = $false
            }

            # Act & Assert
            { & $script:scriptPath @params } | Should -Throw -ExpectedMessage '*No Azure context found*'
        }
    }

    Context 'When Microsoft Graph context is invalid' {
        It 'Should throw when no Microsoft Graph context exists' {
            # Arrange
            Mock -CommandName Get-MgContext -MockWith { $null }
            $params = @{
                CollectionUri   = 'https://dev.azure.com/test-org'
                ProjectName     = 'test-project'
                UniqueName      = 'test-group'
                GroupMembership = 'Contributors'
                Confirm         = $false
            }

            # Act & Assert
            { & $script:scriptPath @params } | Should -Throw -ExpectedMessage '*No Microsoft Graph context found*'
        }
    }
}

Describe 'Group Membership Script - Error Handling' {

    Context 'When Entra ID group does not exist' {
        It 'Should throw when UniqueName does not match any group' {
            # Arrange
            Mock -CommandName Get-MgGroup -MockWith { $null }
            $params = @{
                CollectionUri   = 'https://dev.azure.com/test-org'
                ProjectName     = 'test-project'
                UniqueName      = 'nonexistent-group'
                GroupMembership = 'Contributors'
                Confirm         = $false
            }

            # Act & Assert
            { & $script:scriptPath @params } | Should -Throw -ExpectedMessage "*Security group with UniqueName 'nonexistent-group' does not exist*"
        }
    }

    Context 'When Azure DevOps project does not exist' {
        It 'Should throw when project is not found' {
            # Arrange
            Mock -CommandName Get-AdoProject -MockWith { $null }
            $params = @{
                CollectionUri   = 'https://dev.azure.com/test-org'
                ProjectName     = 'nonexistent-project'
                UniqueName      = 'test-group'
                GroupMembership = 'Contributors'
                Confirm         = $false
            }

            # Act & Assert
            { & $script:scriptPath @params } | Should -Throw -ExpectedMessage '*Project with ID nonexistent-project does not exist*'
        }
    }
}
