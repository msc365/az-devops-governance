#Requires -Version 7.0

BeforeAll {
    # Define the script path
    $scriptPath = Join-Path $PSScriptRoot '../../main.ps1'

    # Create function stubs for external cmdlets to enable mocking
    function Get-AdoProject { }
    function Get-AdoRepository { }
    function New-AdoPushInitialCommit { }
    function Get-AzContext { }
    function Get-Module { }
    function Import-Module { }
}

Describe 'Initial Push Deployment Script' {

    Context 'Core Functionality - Initial Commit Creation' {

        BeforeEach {
            Mock Get-AzContext {
                [PSCustomObject]@{
                    Account      = [PSCustomObject]@{ Id = 'test@example.com' }
                    Subscription = [PSCustomObject]@{ Id = '00000000-0000-0000-0000-000000000000' }
                }
            }

            Mock Get-Module { $true }
            Mock Import-Module { }
            Mock Start-Sleep { }

            Mock Get-AdoProject {
                [PSCustomObject]@{
                    id   = '12345678-1234-1234-1234-123456789012'
                    name = 'TestProject'
                }
            }

            Mock Get-AdoRepository {
                [PSCustomObject]@{
                    id   = '87654321-4321-4321-4321-210987654321'
                    name = 'test-repo'
                }
            }

            Mock New-AdoPushInitialCommit {
                [PSCustomObject]@{
                    pushId     = 123
                    commits    = @(
                        [PSCustomObject]@{
                            commitId = 'abc123def456'
                            comment  = 'Initial commit'
                        }
                    )
                    refUpdates = @(
                        [PSCustomObject]@{
                            name        = 'refs/heads/main'
                            oldObjectId = '0000000000000000000000000000000000000000'
                            newObjectId = 'abc123def456'
                        }
                    )
                    pushedBy   = [PSCustomObject]@{
                        displayName = 'Test User'
                    }
                    date       = [DateTime]::Now
                }
            }
        }

        It 'Should create an initial commit with valid parameters' {
            # Arrange
            $params = @{
                CollectionUri  = 'https://dev.azure.com/test-org'
                ProjectName    = 'TestProject'
                RepositoryName = 'test-repo'
                BranchName     = 'main'
                Message        = 'Initial commit'
                Files          = @(
                    @{
                        path        = '/README.md'
                        content     = '# Test Repository'
                        contentType = 'rawtext'
                    }
                )
                Confirm        = $false
            }

            # Act
            $result = & $scriptPath @params

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.repositoryName | Should -Be 'test-repo'
            $result.status | Should -Be 'Pushed'
            Should -Invoke New-AdoPushInitialCommit -Times 1 -Exactly
        }

        It 'Should handle multiple files in initial commit' {
            # Arrange
            $params = @{
                CollectionUri  = 'https://dev.azure.com/test-org'
                ProjectName    = 'TestProject'
                RepositoryName = 'test-repo'
                BranchName     = 'main'
                Message        = 'Initial commit with multiple files'
                Files          = @(
                    @{
                        path        = '/README.md'
                        content     = '# Test Repository'
                        contentType = 'rawtext'
                    },
                    @{
                        path        = '/src/app.js'
                        content     = 'console.log("Hello");'
                        contentType = 'rawtext'
                    },
                    @{
                        path        = '/.gitignore'
                        content     = 'node_modules/'
                        contentType = 'rawtext'
                    }
                )
                Confirm        = $false
            }

            # Act
            $result = & $scriptPath @params

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.status | Should -Be 'Pushed'
            Should -Invoke New-AdoPushInitialCommit -Times 1 -Exactly
        }

        It 'Should use default branch name when not specified' {
            # Arrange
            $params = @{
                CollectionUri  = 'https://dev.azure.com/test-org'
                ProjectName    = 'TestProject'
                RepositoryName = 'test-repo'
                Files          = @()
                Confirm        = $false
            }

            # Act
            $result = & $scriptPath @params

            # Assert
            $result | Should -Not -BeNullOrEmpty
            Should -Invoke New-AdoPushInitialCommit -Times 1
        }

        It 'Should use default commit message when not specified' {
            # Arrange
            $params = @{
                CollectionUri  = 'https://dev.azure.com/test-org'
                ProjectName    = 'TestProject'
                RepositoryName = 'test-repo'
                Files          = @()
                Confirm        = $false
            }

            # Act
            $result = & $scriptPath @params

            # Assert
            $result | Should -Not -BeNullOrEmpty
            Should -Invoke New-AdoPushInitialCommit -Times 1
        }

        It 'Should handle empty files array' {
            # Arrange
            $params = @{
                CollectionUri  = 'https://dev.azure.com/test-org'
                ProjectName    = 'TestProject'
                RepositoryName = 'test-repo'
                Files          = @()
                Confirm        = $false
            }

            # Act
            $result = & $scriptPath @params

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.status | Should -Be 'Pushed'
            Should -Invoke New-AdoPushInitialCommit -Times 1 -Exactly
        }
    }

    Context 'Required Parameter Validation' {

        BeforeEach {
            Mock Get-AzContext {
                [PSCustomObject]@{
                    Account      = [PSCustomObject]@{ Id = 'test@example.com' }
                    Subscription = [PSCustomObject]@{ Id = '00000000-0000-0000-0000-000000000000' }
                }
            }
            Mock Get-Module { $true }
            Mock Import-Module { }
            Mock Start-Sleep { }
        }

        It 'Should throw when CollectionUri is null or empty' {
            # Arrange
            $env:DefaultAdoCollectionUri = $null
            $params = @{
                ProjectName    = 'TestProject'
                RepositoryName = 'test-repo'
                Confirm        = $false
            }

            # Act & Assert
            { & $scriptPath @params } | Should -Throw -ExpectedMessage '*CollectionUri is required*'
        }

        It 'Should throw when ProjectName is null or empty' {
            # Arrange
            $env:DefaultAdoProjectName = $null
            $params = @{
                CollectionUri  = 'https://dev.azure.com/test-org'
                RepositoryName = 'test-repo'
                Confirm        = $false
            }

            # Act & Assert
            { & $scriptPath @params } | Should -Throw -ExpectedMessage '*ProjectName is required*'
        }

        It 'Should use environment variables when parameters are not provided' {
            # Arrange
            $env:DefaultAdoCollectionUri = 'https://dev.azure.com/env-org'
            $env:DefaultAdoProjectName = 'EnvProject'

            Mock Get-AdoProject {
                [PSCustomObject]@{
                    id   = '12345678-1234-1234-1234-123456789012'
                    name = 'EnvProject'
                }
            }

            Mock Get-AdoRepository {
                [PSCustomObject]@{
                    id   = '87654321-4321-4321-4321-210987654321'
                    name = 'test-repo'
                }
            }

            Mock New-AdoPushInitialCommit {
                [PSCustomObject]@{
                    pushId = 123
                }
            }

            $params = @{
                RepositoryName = 'test-repo'
                Confirm        = $false
            }

            # Act
            $result = & $scriptPath @params

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.status | Should -Be 'Pushed'
            Should -Invoke Get-AdoProject -Times 1 -Exactly
        }
    }

    Context 'Error Handling' {

        BeforeEach {
            Mock Get-AzContext {
                [PSCustomObject]@{
                    Account      = [PSCustomObject]@{ Id = 'test@example.com' }
                    Subscription = [PSCustomObject]@{ Id = '00000000-0000-0000-0000-000000000000' }
                }
            }
            Mock Get-Module { $true }
            Mock Import-Module { }
            Mock Start-Sleep { }
        }

        It 'Should throw when Azure context is not available' {
            # Arrange
            Mock Get-AzContext { $null }

            $params = @{
                CollectionUri  = 'https://dev.azure.com/test-org'
                ProjectName    = 'TestProject'
                RepositoryName = 'test-repo'
                Confirm        = $false
            }

            # Act & Assert
            { & $scriptPath @params } | Should -Throw -ExpectedMessage '*No Azure context found*'
        }

        It 'Should throw when project does not exist' {
            # Arrange
            Mock Get-AdoProject { $null }

            $params = @{
                CollectionUri  = 'https://dev.azure.com/test-org'
                ProjectName    = 'NonExistentProject'
                RepositoryName = 'test-repo'
                Confirm        = $false
            }

            # Act & Assert
            { & $scriptPath @params } | Should -Throw -ExpectedMessage '*does not exist, cannot proceed*'
        }

        It 'Should throw when repository does not exist' {
            # Arrange
            Mock Get-AdoProject {
                [PSCustomObject]@{
                    id   = '12345678-1234-1234-1234-123456789012'
                    name = 'TestProject'
                }
            }

            Mock Get-AdoRepository { $null }

            $params = @{
                CollectionUri  = 'https://dev.azure.com/test-org'
                ProjectName    = 'TestProject'
                RepositoryName = 'non-existent-repo'
                Confirm        = $false
            }

            # Act & Assert
            { & $scriptPath @params } | Should -Throw -ExpectedMessage '*does not exist, cannot proceed*'
        }

        It 'Should handle push failure gracefully' {
            # Arrange
            Mock Get-AdoProject {
                [PSCustomObject]@{
                    id   = '12345678-1234-1234-1234-123456789012'
                    name = 'TestProject'
                }
            }

            Mock Get-AdoRepository {
                [PSCustomObject]@{
                    id   = '87654321-4321-4321-4321-210987654321'
                    name = 'test-repo'
                }
            }

            Mock New-AdoPushInitialCommit {
                [PSCustomObject]@{
                    pushId     = $null
                    commits    = @()
                    refUpdates = @()
                }
            }

            $params = @{
                CollectionUri  = 'https://dev.azure.com/test-org'
                ProjectName    = 'TestProject'
                RepositoryName = 'test-repo'
                Confirm        = $false
            }

            # Act
            $result = & $scriptPath @params

            # Assert
            $result.status | Should -Be 'Pushed'
        }
    }

    Context 'Pipeline Support' {

        BeforeEach {
            Mock Get-AzContext {
                [PSCustomObject]@{
                    Account      = [PSCustomObject]@{ Id = 'test@example.com' }
                    Subscription = [PSCustomObject]@{ Id = '00000000-0000-0000-0000-000000000000' }
                }
            }

            Mock Get-Module { $true }
            Mock Import-Module { }
            Mock Start-Sleep { }

            Mock Get-AdoProject {
                [PSCustomObject]@{
                    id   = '12345678-1234-1234-1234-123456789012'
                    name = 'TestProject'
                }
            }

            Mock Get-AdoRepository {
                [PSCustomObject]@{
                    id   = '87654321-4321-4321-4321-210987654321'
                    name = 'test-repo'
                }
            }

            Mock New-AdoPushInitialCommit {
                [PSCustomObject]@{
                    pushId = 123
                }
            }
        }

        It 'Should accept RepositoryName via pipeline' {
            # Arrange
            Mock Get-AdoRepository {
                [PSCustomObject]@{
                    id   = '87654321-4321-4321-4321-210987654321'
                    name = 'pipeline-repo'
                }
            }

            $pipelineInput = [PSCustomObject]@{
                RepositoryName = 'pipeline-repo'
                BranchName     = 'develop'
                Message        = 'Pipeline commit'
            }

            # Act
            $null = $pipelineInput | & $scriptPath -CollectionUri 'https://dev.azure.com/test-org' -ProjectName 'TestProject' -Confirm:$false

            # Assert
            Should -Invoke Get-AdoRepository -Times 1
        }
    }

    Context 'Rollback Operations' {

        BeforeEach {
            Mock Get-AzContext {
                [PSCustomObject]@{
                    Account      = [PSCustomObject]@{ Id = 'test@example.com' }
                    Subscription = [PSCustomObject]@{ Id = '00000000-0000-0000-0000-000000000000' }
                }
            }

            Mock Get-Module { $true }
            Mock Import-Module { }
            Mock Start-Sleep { }
            Mock Write-Warning { }

            Mock Get-AdoProject {
                [PSCustomObject]@{
                    id   = '12345678-1234-1234-1234-123456789012'
                    name = 'TestProject'
                }
            }

            Mock Get-AdoRepository {
                [PSCustomObject]@{
                    id   = '87654321-4321-4321-4321-210987654321'
                    name = 'test-repo'
                }
            }

            Mock New-AdoPushInitialCommit {
                [PSCustomObject]@{
                    pushId = 123
                }
            }
        }

        It 'Should return NotImplemented status when Rollback is specified' {
            # Arrange
            $params = @{
                CollectionUri  = 'https://dev.azure.com/test-org'
                ProjectName    = 'TestProject'
                RepositoryName = 'test-repo'
                Rollback       = $true
                Confirm        = $false
            }

            # Act
            $null = & $scriptPath @params 3>&1

            # Assert
            Should -Invoke New-AdoPushInitialCommit -Times 0
            Should -Invoke Write-Warning -Times 1
        }
    }

    Context 'Output Structure' {

        BeforeEach {
            Mock Get-AzContext {
                [PSCustomObject]@{
                    Account      = [PSCustomObject]@{ Id = 'test@example.com' }
                    Subscription = [PSCustomObject]@{ Id = '00000000-0000-0000-0000-000000000000' }
                }
            }

            Mock Get-Module { $true }
            Mock Import-Module { }
            Mock Start-Sleep { }

            Mock Get-AdoProject {
                [PSCustomObject]@{
                    id   = '12345678-1234-1234-1234-123456789012'
                    name = 'TestProject'
                }
            }

            Mock Get-AdoRepository {
                [PSCustomObject]@{
                    id   = '87654321-4321-4321-4321-210987654321'
                    name = 'test-repo'
                }
            }

            Mock New-AdoPushInitialCommit {
                [PSCustomObject]@{
                    pushId     = 123
                    commits    = @()
                    refUpdates = @()
                    pushedBy   = [PSCustomObject]@{ displayName = 'Test User' }
                    date       = [DateTime]::Now
                }
            }
        }

        It 'Should return object with required properties' {
            # Arrange
            $params = @{
                CollectionUri  = 'https://dev.azure.com/test-org'
                ProjectName    = 'TestProject'
                RepositoryName = 'test-repo'
                Confirm        = $false
            }

            # Act
            $result = & $scriptPath @params

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.PSObject.Properties.Name | Should -Contain 'repositoryName'
            $result.PSObject.Properties.Name | Should -Contain 'projectName'
            $result.PSObject.Properties.Name | Should -Contain 'collectionUri'
            $result.PSObject.Properties.Name | Should -Contain 'status'
        }

        It 'Should include all original push properties in output' {
            # Arrange
            $params = @{
                CollectionUri  = 'https://dev.azure.com/test-org'
                ProjectName    = 'TestProject'
                RepositoryName = 'test-repo'
                Confirm        = $false
            }

            # Act
            $result = & $scriptPath @params

            # Assert
            $result.PSObject.Properties.Name | Should -Contain 'pushId'
            $result.PSObject.Properties.Name | Should -Contain 'commits'
            $result.PSObject.Properties.Name | Should -Contain 'refUpdates'
            $result.PSObject.Properties.Name | Should -Contain 'pushedBy'
            $result.PSObject.Properties.Name | Should -Contain 'date'
        }
    }
}
