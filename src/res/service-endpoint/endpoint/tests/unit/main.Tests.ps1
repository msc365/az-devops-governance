#Requires -Version 7.0

BeforeAll {
    # Define the script path
    $scriptPath = Join-Path $PSScriptRoot '../../main.ps1'

    # Create function stubs for external cmdlets to enable mocking
    function Get-AdoProject { }
    function Get-AdoServiceEndpoint { }
    function New-AdoServiceEndpoint { }
    function Remove-AdoServiceEndpoint { }
    function Get-AzContext { }
    function Get-AzSubscription { }
    function Get-AzUserAssignedIdentity { }
    function Get-AzFederatedIdentityCredential { }
    function New-AzFederatedIdentityCredential { }
    function Remove-AzFederatedIdentityCredential { }
    function Get-Module { }
    function Import-Module { }
}

Describe 'Connection Deployment Script' {

    Context 'Core Functionality - Service Endpoint Creation' {

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

            Mock Get-AzUserAssignedIdentity {
                [PSCustomObject]@{
                    Name              = 'test-identity'
                    ClientId          = '11111111-1111-1111-1111-111111111111'
                    TenantId          = '22222222-2222-2222-2222-222222222222'
                    ResourceGroupName = 'test-rg'
                    Id                = '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/test-identity'
                }
            }

            Mock Get-AzSubscription {
                [PSCustomObject]@{
                    Name           = 'Test Subscription'
                    SubscriptionId = '00000000-0000-0000-0000-000000000000'
                }
            }

            Mock Get-AdoServiceEndpoint { $null }
            Mock Get-AzFederatedIdentityCredential { $null }

            Mock New-AdoServiceEndpoint {
                [PSCustomObject]@{
                    id            = '87654321-4321-4321-4321-210987654321'
                    name          = 'test-connection'
                    type          = 'AzureRM'
                    isReady       = $true
                    Authorization = [PSCustomObject]@{
                        Parameters = @{
                            WorkloadIdentityFederationIssuer  = 'https://vstoken.dev.azure.com/test-issuer'
                            WorkloadIdentityFederationSubject = 'sc://test-org/test-project/test-connection'
                        }
                    }
                }
            }

            Mock New-AzFederatedIdentityCredential {
                [PSCustomObject]@{
                    Name    = 'test-fic'
                    Id      = '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/test-identity/federatedIdentityCredentials/test-fic'
                    Issuer  = 'https://vstoken.dev.azure.com/test-issuer'
                    Subject = 'sc://test-org/test-project/test-connection'
                }
            }
        }

        It 'Should create a new service endpoint with valid parameters' {
            # Arrange
            $params = @{
                CollectionUri   = 'https://dev.azure.com/test-org'
                ProjectName     = 'TestProject'
                Name            = 'test-connection'
                Description     = 'Test connection'
                ManagedIdentity = @{
                    name                        = 'test-identity'
                    resourceGroupName           = 'test-rg'
                    subscriptionId              = '00000000-0000-0000-0000-000000000000'
                    federatedIdentityCredential = @{
                        name = 'test-fic'
                    }
                }
                Confirm         = $false
            }

            # Act
            $result = & $scriptPath @params

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.name | Should -Be 'test-connection'
            $result.status | Should -Be 'Created'
            Should -Invoke New-AdoServiceEndpoint -Times 1 -Exactly
            Should -Invoke New-AzFederatedIdentityCredential -Times 1 -Exactly
        }

        It 'Should return NoChange status when service endpoint already exists' {
            # Arrange
            Mock Get-AdoServiceEndpoint {
                [PSCustomObject]@{
                    id      = '87654321-4321-4321-4321-210987654321'
                    name    = 'test-connection'
                    type    = 'AzureRM'
                    isReady = $true
                }
            }

            Mock Get-AzFederatedIdentityCredential {
                [PSCustomObject]@{
                    Name = 'test-fic'
                    Id   = '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/test-identity/federatedIdentityCredentials/test-fic'
                }
            }

            $params = @{
                CollectionUri   = 'https://dev.azure.com/test-org'
                ProjectName     = 'TestProject'
                Name            = 'test-connection'
                ManagedIdentity = @{
                    name                        = 'test-identity'
                    resourceGroupName           = 'test-rg'
                    subscriptionId              = '00000000-0000-0000-0000-000000000000'
                    federatedIdentityCredential = @{
                        name = 'test-fic'
                    }
                }
                Confirm         = $false
            }

            # Act
            $result = & $scriptPath @params

            # Assert
            $result.status | Should -Be 'NoChange'
            Should -Invoke New-AdoServiceEndpoint -Times 0
            Should -Invoke New-AzFederatedIdentityCredential -Times 0
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
                ProjectName     = 'TestProject'
                Name            = 'test-connection'
                ManagedIdentity = @{
                    name                        = 'test-identity'
                    resourceGroupName           = 'test-rg'
                    subscriptionId              = '00000000-0000-0000-0000-000000000000'
                    federatedIdentityCredential = @{ name = 'test-fic' }
                }
                Confirm         = $false
            }

            # Act & Assert
            { & $scriptPath @params } | Should -Throw -ExpectedMessage '*CollectionUri is required*'
        }

        It 'Should throw when ProjectName is null or empty' {
            # Arrange
            $env:DefaultAdoProjectName = $null
            $params = @{
                CollectionUri   = 'https://dev.azure.com/test-org'
                Name            = 'test-connection'
                ManagedIdentity = @{
                    name                        = 'test-identity'
                    resourceGroupName           = 'test-rg'
                    subscriptionId              = '00000000-0000-0000-0000-000000000000'
                    federatedIdentityCredential = @{ name = 'test-fic' }
                }
                Confirm         = $false
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

            Mock Get-AzUserAssignedIdentity {
                [PSCustomObject]@{
                    Name              = 'test-identity'
                    ClientId          = '11111111-1111-1111-1111-111111111111'
                    TenantId          = '22222222-2222-2222-2222-222222222222'
                    ResourceGroupName = 'test-rg'
                }
            }

            Mock Get-AzSubscription {
                [PSCustomObject]@{
                    Name           = 'Test Subscription'
                    SubscriptionId = '00000000-0000-0000-0000-000000000000'
                }
            }

            Mock Get-AdoServiceEndpoint { $null }
            Mock Get-AzFederatedIdentityCredential { $null }

            Mock New-AdoServiceEndpoint {
                [PSCustomObject]@{
                    id            = '87654321-4321-4321-4321-210987654321'
                    name          = 'test-connection'
                    type          = 'AzureRM'
                    Authorization = [PSCustomObject]@{
                        Parameters = @{
                            WorkloadIdentityFederationIssuer  = 'https://vstoken.dev.azure.com/test-issuer'
                            WorkloadIdentityFederationSubject = 'sc://test-org/test-project/test-connection'
                        }
                    }
                }
            }

            Mock New-AzFederatedIdentityCredential { }

            $params = @{
                Name            = 'test-connection'
                ManagedIdentity = @{
                    name                        = 'test-identity'
                    resourceGroupName           = 'test-rg'
                    subscriptionId              = '00000000-0000-0000-0000-000000000000'
                    federatedIdentityCredential = @{ name = 'test-fic' }
                }
                Confirm         = $false
            }

            # Act
            $result = & $scriptPath @params

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.status | Should -Be 'Created'
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
                CollectionUri   = 'https://dev.azure.com/test-org'
                ProjectName     = 'TestProject'
                Name            = 'test-connection'
                ManagedIdentity = @{
                    name                        = 'test-identity'
                    resourceGroupName           = 'test-rg'
                    subscriptionId              = '00000000-0000-0000-0000-000000000000'
                    federatedIdentityCredential = @{ name = 'test-fic' }
                }
                Confirm         = $false
            }

            # Act & Assert
            { & $scriptPath @params } | Should -Throw -ExpectedMessage '*No Azure context found*'
        }

        It 'Should throw when project does not exist' {
            # Arrange
            Mock Get-AdoProject { $null }

            $params = @{
                CollectionUri   = 'https://dev.azure.com/test-org'
                ProjectName     = 'NonExistentProject'
                Name            = 'test-connection'
                ManagedIdentity = @{
                    name                        = 'test-identity'
                    resourceGroupName           = 'test-rg'
                    subscriptionId              = '00000000-0000-0000-0000-000000000000'
                    federatedIdentityCredential = @{ name = 'test-fic' }
                }
                Confirm         = $false
            }

            # Act & Assert
            { & $scriptPath @params } | Should -Throw -ExpectedMessage '*does not exist, cannot proceed*'
        }

        It 'Should throw when managed identity does not exist' {
            # Arrange
            Mock Get-AdoProject {
                [PSCustomObject]@{
                    id   = '12345678-1234-1234-1234-123456789012'
                    name = 'TestProject'
                }
            }

            Mock Get-AzUserAssignedIdentity { $null }
            Mock Get-AdoServiceEndpoint { $null }

            $params = @{
                CollectionUri   = 'https://dev.azure.com/test-org'
                ProjectName     = 'TestProject'
                Name            = 'test-connection'
                ManagedIdentity = @{
                    name                        = 'missing-identity'
                    resourceGroupName           = 'test-rg'
                    subscriptionId              = '00000000-0000-0000-0000-000000000000'
                    federatedIdentityCredential = @{ name = 'test-fic' }
                }
                Confirm         = $false
            }

            # Act & Assert
            { & $scriptPath @params } | Should -Throw -ExpectedMessage '*Managed identity*not found*'
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
            Mock Write-Information { }

            Mock Get-AdoProject {
                [PSCustomObject]@{
                    id   = '12345678-1234-1234-1234-123456789012'
                    name = 'TestProject'
                }
            }

            Mock Get-AzUserAssignedIdentity {
                [PSCustomObject]@{
                    Name              = 'test-identity'
                    ClientId          = '11111111-1111-1111-1111-111111111111'
                    TenantId          = '22222222-2222-2222-2222-222222222222'
                    ResourceGroupName = 'test-rg'
                }
            }

            Mock Get-AzFederatedIdentityCredential {
                [PSCustomObject]@{
                    Name = 'test-fic'
                    Id   = '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/test-identity/federatedIdentityCredentials/test-fic'
                }
            }

            Mock Get-AdoServiceEndpoint {
                [PSCustomObject]@{
                    id   = '87654321-4321-4321-4321-210987654321'
                    name = 'test-connection'
                    type = 'AzureRM'
                }
            }

            Mock Remove-AzFederatedIdentityCredential { }
            Mock Remove-AdoServiceEndpoint { }
        }

        It 'Should remove federated identity credential and service endpoint with Rollback switch' {
            # Arrange
            $params = @{
                CollectionUri   = 'https://dev.azure.com/test-org'
                ProjectName     = 'TestProject'
                Name            = 'test-connection'
                ManagedIdentity = @{
                    name                        = 'test-identity'
                    resourceGroupName           = 'test-rg'
                    subscriptionId              = '00000000-0000-0000-0000-000000000000'
                    federatedIdentityCredential = @{ name = 'test-fic' }
                }
                Rollback        = $true
                Confirm         = $false
            }

            # Act
            $result = & $scriptPath @params

            # Assert
            $result.status | Should -Be 'Removed'
            Should -Invoke Remove-AzFederatedIdentityCredential -Times 1 -Exactly
            Should -Invoke Remove-AdoServiceEndpoint -Times 1 -Exactly
        }

        It 'Should return NotFound status when service endpoint does not exist during rollback' {
            # Arrange
            Mock Get-AdoServiceEndpoint { $null }
            Mock Get-AzFederatedIdentityCredential { $null }

            $params = @{
                CollectionUri   = 'https://dev.azure.com/test-org'
                ProjectName     = 'TestProject'
                Name            = 'non-existent-connection'
                ManagedIdentity = @{
                    name                        = 'test-identity'
                    resourceGroupName           = 'test-rg'
                    subscriptionId              = '00000000-0000-0000-0000-000000000000'
                    federatedIdentityCredential = @{ name = 'test-fic' }
                }
                Rollback        = $true
                Confirm         = $false
            }

            # Act
            $result = & $scriptPath @params

            # Assert
            $result.status | Should -Be 'NotFound'
            $result.name | Should -Be 'non-existent-connection'
            Should -Invoke Remove-AdoServiceEndpoint -Times 0
        }

        It 'Should throw when attempting to remove service endpoint with existing federated credential' {
            # Arrange
            Mock Remove-AzFederatedIdentityCredential {
                throw 'Simulated removal failure'
            }

            $params = @{
                CollectionUri   = 'https://dev.azure.com/test-org'
                ProjectName     = 'TestProject'
                Name            = 'test-connection'
                ManagedIdentity = @{
                    name                        = 'test-identity'
                    resourceGroupName           = 'test-rg'
                    subscriptionId              = '00000000-0000-0000-0000-000000000000'
                    federatedIdentityCredential = @{ name = 'test-fic' }
                }
                Rollback        = $true
                Confirm         = $false
            }

            # Act & Assert
            { & $scriptPath @params } | Should -Throw
        }

        It 'Should retry service endpoint removal on failure' {
            # Arrange
            $script:attemptCount = 0
            Mock Remove-AdoServiceEndpoint {
                $script:attemptCount++
                if ($script:attemptCount -lt 2) {
                    throw 'Temporary failure'
                }
            }

            $params = @{
                CollectionUri   = 'https://dev.azure.com/test-org'
                ProjectName     = 'TestProject'
                Name            = 'test-connection'
                ManagedIdentity = @{
                    name                        = 'test-identity'
                    resourceGroupName           = 'test-rg'
                    subscriptionId              = '00000000-0000-0000-0000-000000000000'
                    federatedIdentityCredential = @{ name = 'test-fic' }
                }
                Rollback        = $true
                Confirm         = $false
            }

            # Act
            $result = & $scriptPath @params

            # Assert
            $result.status | Should -Be 'Removed'
            Should -Invoke Remove-AdoServiceEndpoint -Times 2 -Exactly
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

            Mock Get-AzUserAssignedIdentity {
                [PSCustomObject]@{
                    Name              = 'test-identity'
                    ClientId          = '11111111-1111-1111-1111-111111111111'
                    TenantId          = '22222222-2222-2222-2222-222222222222'
                    ResourceGroupName = 'test-rg'
                }
            }

            Mock Get-AzSubscription {
                [PSCustomObject]@{
                    Name           = 'Test Subscription'
                    SubscriptionId = '00000000-0000-0000-0000-000000000000'
                }
            }

            Mock Get-AdoServiceEndpoint { $null }
            Mock Get-AzFederatedIdentityCredential { $null }

            Mock New-AdoServiceEndpoint {
                [PSCustomObject]@{
                    id            = '87654321-4321-4321-4321-210987654321'
                    name          = $Name
                    type          = 'AzureRM'
                    Authorization = [PSCustomObject]@{
                        Parameters = @{
                            WorkloadIdentityFederationIssuer  = 'https://vstoken.dev.azure.com/test-issuer'
                            WorkloadIdentityFederationSubject = 'sc://test-org/test-project/test-connection'
                        }
                    }
                }
            }

            Mock New-AzFederatedIdentityCredential { }
        }

        It 'Should accept Name parameter from pipeline' {
            # Arrange
            $pipelineInput = [PSCustomObject]@{
                Name            = 'pipeline-connection'
                Description     = 'Connection from pipeline'
                ManagedIdentity = @{
                    name                        = 'test-identity'
                    resourceGroupName           = 'test-rg'
                    subscriptionId              = '00000000-0000-0000-0000-000000000000'
                    federatedIdentityCredential = @{ name = 'test-fic' }
                }
            }

            # Act
            $result = $pipelineInput | & $scriptPath -CollectionUri 'https://dev.azure.com/test-org' -ProjectName 'TestProject' -Confirm:$false

            # Assert
            $result.name | Should -Be 'pipeline-connection'
            $result.status | Should -Be 'Created'
            Should -Invoke New-AdoServiceEndpoint -Times 1 -Exactly
        }
    }
}
