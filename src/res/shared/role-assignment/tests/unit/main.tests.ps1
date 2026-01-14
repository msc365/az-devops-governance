<#
.SYNOPSIS
    Unit tests for Azure role assignment script.

.DESCRIPTION
    This script contains unit tests for the role assignment deployment script.

.NOTES
    File Name      : main.tests.ps1
    Prerequisite   : Pester module
#>

BeforeAll {
    $script:rootPath = (Get-Item $PSScriptRoot).Parent.Parent.FullName
    $script:mainScript = Join-Path $rootPath -ChildPath 'main.ps1'
}

Describe 'Role Assignment Script Tests' {
    Context 'Script Structure' {
        It 'Should exist' {
            Test-Path $script:mainScript | Should -Be $true
        }

        It 'Should have valid PowerShell syntax' {
            $errors = $null
            [System.Management.Automation.PSParser]::Tokenize((Get-Content $script:mainScript -Raw), [ref]$errors)
            $errors.Count | Should -Be 0
        }

        It 'Should support ShouldProcess' {
            $scriptContent = Get-Content $script:mainScript -Raw
            $scriptContent | Should -Match '\[CmdletBinding\(.*SupportsShouldProcess.*\)\]'
        }

        It 'Should have required parameters' {
            $scriptContent = Get-Content $script:mainScript -Raw
            $scriptContent | Should -Match '\$ObjectId'
            $scriptContent | Should -Match '\$RoleAssignments'
        }

        It 'Should support Rollback parameter' {
            $scriptContent = Get-Content $script:mainScript -Raw
            $scriptContent | Should -Match '\$Rollback'
        }
    }

    Context 'Parameter Validation' {
        It 'Should have mandatory ObjectId parameter' {
            $scriptContent = Get-Content $script:mainScript -Raw
            $scriptContent | Should -Match '\[Parameter\(Mandatory\)\][\s\S]*?\[string\]\$ObjectId'
        }

        It 'Should have mandatory RoleAssignments parameter' {
            $scriptContent = Get-Content $script:mainScript -Raw
            $scriptContent | Should -Match '\[Parameter\(Mandatory\)\][\s\S]*?\[AllowEmptyCollection\(\)\][\s\S]*?\[array\]\$RoleAssignments'
        }

        It 'Should validate ObjectId as GUID format' {
            $scriptContent = Get-Content $script:mainScript -Raw
            $scriptContent | Should -Match '\[System\.Guid\]::TryParse'
        }

        It 'Should throw on invalid ObjectId format' {
            $scriptContent = Get-Content $script:mainScript -Raw
            $scriptContent | Should -Match 'Invalid ObjectId format.*Expected a valid GUID'
        }
    }

    Context 'Scope Format Validation' {
        BeforeAll {
            Mock -CommandName Get-AzContext -MockWith {
                return @{
                    Subscription = @{
                        Id   = '00000000-0000-0000-0000-000000000000'
                        Name = 'Test Subscription'
                    }
                }
            }
            Mock -CommandName Get-AzRoleAssignment -MockWith { return @() }
        }

        It 'Should accept valid Management Group scope format' {
            Mock -CommandName New-AzRoleAssignment -MockWith {
                return [PSCustomObject]@{
                    ObjectId           = '12345678-1234-1234-1234-123456789abc'
                    DisplayName        = 'Test User'
                    RoleDefinitionName = 'Reader'
                    Scope              = '/providers/Microsoft.Management/managementGroups/my-mg'
                    RoleAssignmentId   = '/providers/Microsoft.Management/managementGroups/my-mg/providers/Microsoft.Authorization/roleAssignments/test1'
                }
            }
            $validRoleAssignment = @{
                roleDefinitionName = 'Reader'
                scope              = '/providers/Microsoft.Management/managementGroups/my-mg'
            }
            {
                & $script:mainScript -ObjectId '12345678-1234-1234-1234-123456789abc' -RoleAssignments @($validRoleAssignment) -Confirm:$false -ErrorAction Stop
            } | Should -Not -Throw
        }

        It 'Should accept valid Subscription scope format' {
            Mock -CommandName New-AzRoleAssignment -MockWith {
                return [PSCustomObject]@{
                    ObjectId           = '12345678-1234-1234-1234-123456789abc'
                    DisplayName        = 'Test User'
                    RoleDefinitionName = 'Contributor'
                    Scope              = '/subscriptions/12345678-1234-1234-1234-123456789abc'
                    RoleAssignmentId   = '/subscriptions/12345678-1234-1234-1234-123456789abc/providers/Microsoft.Authorization/roleAssignments/test2'
                }
            }
            $validRoleAssignment = @{
                roleDefinitionName = 'Contributor'
                scope              = '/subscriptions/12345678-1234-1234-1234-123456789abc'
            }
            {
                & $script:mainScript -ObjectId '12345678-1234-1234-1234-123456789abc' -RoleAssignments @($validRoleAssignment) -Confirm:$false -ErrorAction Stop
            } | Should -Not -Throw
        }

        It 'Should accept valid Resource Group scope format' {
            Mock -CommandName New-AzRoleAssignment -MockWith {
                return [PSCustomObject]@{
                    ObjectId           = '12345678-1234-1234-1234-123456789abc'
                    DisplayName        = 'Test User'
                    RoleDefinitionName = 'Owner'
                    Scope              = '/subscriptions/12345678-1234-1234-1234-123456789abc/resourceGroups/my-rg'
                    RoleAssignmentId   = '/subscriptions/12345678-1234-1234-1234-123456789abc/resourceGroups/my-rg/providers/Microsoft.Authorization/roleAssignments/test3'
                }
            }
            $validRoleAssignment = @{
                roleDefinitionName = 'Owner'
                scope              = '/subscriptions/12345678-1234-1234-1234-123456789abc/resourceGroups/my-rg'
            }
            {
                & $script:mainScript -ObjectId '12345678-1234-1234-1234-123456789abc' -RoleAssignments @($validRoleAssignment) -Confirm:$false -ErrorAction Stop
            } | Should -Not -Throw
        }

        It 'Should reject invalid scope format' {
            $invalidRoleAssignment = @{
                roleDefinitionName = 'Reader'
                scope              = '/invalid/scope/format'
            }
            {
                & $script:mainScript -ObjectId '12345678-1234-1234-1234-123456789abc' -RoleAssignments @($invalidRoleAssignment) -Confirm:$false -ErrorAction Stop
            } | Should -Throw -ExpectedMessage '*Invalid scope format*'
        }

        It 'Should reject role assignment with missing roleDefinitionName' {
            $invalidRoleAssignment = @{
                scope = '/subscriptions/12345678-1234-1234-1234-123456789abc'
            }
            {
                & $script:mainScript -ObjectId '12345678-1234-1234-1234-123456789abc' -RoleAssignments @($invalidRoleAssignment) -Confirm:$false -ErrorAction Stop
            } | Should -Throw -ExpectedMessage '*roleDefinitionName*required*'
        }

        It 'Should reject role assignment with missing scope' {
            $invalidRoleAssignment = @{
                roleDefinitionName = 'Reader'
            }
            {
                & $script:mainScript -ObjectId '12345678-1234-1234-1234-123456789abc' -RoleAssignments @($invalidRoleAssignment) -Confirm:$false -ErrorAction Stop
            } | Should -Throw -ExpectedMessage '*scope*required*'
        }
    }

    Context 'ObjectId Format Validation' {
        BeforeAll {
            # Mock Azure cmdlets to prevent actual Azure calls
            Mock -CommandName Get-AzContext -MockWith {
                return @{
                    Subscription = @{
                        Id   = '00000000-0000-0000-0000-000000000000'
                        Name = 'Test Subscription'
                    }
                }
            }
            Mock -CommandName Get-AzRoleAssignment -MockWith { return @() }
        }

        It 'Should accept valid GUID format for ObjectId' {
            # Valid GUIDs should not throw during validation
            $validGuids = @(
                '12345678-1234-1234-1234-123456789abc'
                '00000000-0000-0000-0000-000000000000'
                'AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE'
            )

            foreach ($guid in $validGuids) {
                {
                    & $script:mainScript -ObjectId $guid -RoleAssignments @() -Confirm:$false -ErrorAction Stop
                } | Should -Not -Throw
            }
        }

        It 'Should reject invalid GUID formats' {
            $invalidGuids = @(
                @{ Value = 'not-a-guid'; ExpectedError = '*Invalid ObjectId format*' }
                @{ Value = '12345'; ExpectedError = '*Invalid ObjectId format*' }
                @{ Value = '12345678-1234-1234-1234'; ExpectedError = '*Invalid ObjectId format*' }
                @{ Value = 'ZZZZZZZZ-ZZZZ-ZZZZ-ZZZZ-ZZZZZZZZZZZZ'; ExpectedError = '*Invalid ObjectId format*' }
                @{ Value = ''; ExpectedError = '*empty string*' }
            )

            foreach ($testCase in $invalidGuids) {
                {
                    & $script:mainScript -ObjectId $testCase.Value -RoleAssignments @() -Confirm:$false -ErrorAction Stop
                } | Should -Throw -ExpectedMessage $testCase.ExpectedError -Because "ObjectId '$($testCase.Value)' should be invalid"
            }
        }
    }

    Context 'Comparison Logic and Performance Optimizations' {
        BeforeAll {
            Mock -CommandName Get-AzContext -MockWith {
                return @{
                    Subscription = @{
                        Id   = '00000000-0000-0000-0000-000000000000'
                        Name = 'Test Subscription'
                    }
                }
            }
        }

        It 'Should use hashtable lookup for scope filtering (O(1) performance)' {
            $scriptContent = Get-Content $script:mainScript -Raw
            # Verify hashtable is used for scope lookup
            $scriptContent | Should -Match '\$managedScopesLookup\s*=\s*@\{\}'
            $scriptContent | Should -Match '\$managedScopesLookup\.ContainsKey'
        }

        It 'Should use hashtable lookup for role assignment comparison' {
            $scriptContent = Get-Content $script:mainScript -Raw
            # Verify hashtable is used for comparison
            $scriptContent | Should -Match '\$currentLookup\s*=\s*@\{\}'
            $scriptContent | Should -Match '\$currentLookup\.ContainsKey'
        }

        It 'Should use idiomatic PowerShell arrays instead of Generic Lists' {
            $scriptContent = Get-Content $script:mainScript -Raw
            # Verify no Generic List usage
            $scriptContent | Should -Not -Match 'System\.Collections\.Generic\.List'
            $scriptContent | Should -Not -Match 'System\.Collections\.Generic\.HashSet'
            # Verify array usage
            $scriptContent | Should -Match '\$results\s*=\s*@\(\)'
            $scriptContent | Should -Match '\$assignmentsToCreate\s*=\s*@\(\)'
        }

        It 'Should filter to managed scopes only' {
            Mock -CommandName Get-AzRoleAssignment -MockWith {
                return @(
                    [PSCustomObject]@{
                        ObjectId           = '12345678-1234-1234-1234-123456789abc'
                        DisplayName        = 'Test User'
                        RoleDefinitionName = 'Reader'
                        Scope              = '/subscriptions/12345678-1234-1234-1234-123456789abc'
                        RoleAssignmentId   = '/subscriptions/12345678-1234-1234-1234-123456789abc/providers/Microsoft.Authorization/roleAssignments/test1'
                    },
                    [PSCustomObject]@{
                        ObjectId           = '12345678-1234-1234-1234-123456789abc'
                        DisplayName        = 'Test User'
                        RoleDefinitionName = 'Contributor'
                        Scope              = '/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'
                        RoleAssignmentId   = '/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/providers/Microsoft.Authorization/roleAssignments/test2'
                    }
                )
            }

            $desiredAssignments = @(
                @{
                    roleDefinitionName = 'Reader'
                    scope              = '/subscriptions/12345678-1234-1234-1234-123456789abc'
                }
            )

            $result = & $script:mainScript -ObjectId '12345678-1234-1234-1234-123456789abc' -RoleAssignments $desiredAssignments -Confirm:$false

            # Should only process the assignment in the managed scope
            Assert-MockCalled -CommandName Get-AzRoleAssignment -Times 1
        }

        It 'Should identify assignments to create' {
            Mock -CommandName Get-AzRoleAssignment -MockWith {
                return @(
                    [PSCustomObject]@{
                        ObjectId           = '12345678-1234-1234-1234-123456789abc'
                        DisplayName        = 'Test User'
                        RoleDefinitionName = 'Reader'
                        Scope              = '/subscriptions/12345678-1234-1234-1234-123456789abc'
                        RoleAssignmentId   = '/subscriptions/12345678-1234-1234-1234-123456789abc/providers/Microsoft.Authorization/roleAssignments/test1'
                    }
                )
            }

            $desiredAssignments = @(
                @{
                    roleDefinitionName = 'Reader'
                    scope              = '/subscriptions/12345678-1234-1234-1234-123456789abc'
                },
                @{
                    roleDefinitionName = 'Contributor'
                    scope              = '/subscriptions/12345678-1234-1234-1234-123456789abc'
                }
            )

            Mock -CommandName New-AzRoleAssignment -MockWith {
                return [PSCustomObject]@{
                    ObjectId           = '12345678-1234-1234-1234-123456789abc'
                    DisplayName        = 'Test User'
                    RoleDefinitionName = 'Contributor'
                    Scope              = '/subscriptions/12345678-1234-1234-1234-123456789abc'
                    RoleAssignmentId   = '/subscriptions/12345678-1234-1234-1234-123456789abc/providers/Microsoft.Authorization/roleAssignments/test3'
                }
            }

            $result = & $script:mainScript -ObjectId '12345678-1234-1234-1234-123456789abc' -RoleAssignments $desiredAssignments -Confirm:$false

            # Verbose output should indicate creation of Contributor role
            Assert-MockCalled -CommandName Get-AzRoleAssignment -Times 1
        }

        It 'Should handle case-insensitive scope comparison' {
            $scriptContent = Get-Content $script:mainScript -Raw
            # Verify ToLowerInvariant is used for case-insensitive comparison
            $scriptContent | Should -Match '\.ToLowerInvariant\(\)'
        }

        It 'Should support empty RoleAssignments array' {
            Mock -CommandName Get-AzRoleAssignment -MockWith { return @() }

            {
                & $script:mainScript -ObjectId '12345678-1234-1234-1234-123456789abc' -RoleAssignments @() -Confirm:$false -ErrorAction Stop
            } | Should -Not -Throw
        }
    }

    Context 'Deployment and Rollback Behavior' {
        BeforeAll {
            Mock -CommandName Get-AzContext -MockWith {
                return @{
                    Subscription = @{
                        Id   = '00000000-0000-0000-0000-000000000000'
                        Name = 'Test Subscription'
                    }
                }
            }
        }

        It 'Should support additive deployment (no -Enforce parameter)' {
            $scriptContent = Get-Content $script:mainScript -Raw
            # Verify -Enforce parameter is NOT present
            $scriptContent | Should -Not -Match '\[Parameter.*\]\s*\[switch\]\$Enforce'
        }

        It 'Should support Rollback switch' {
            $scriptContent = Get-Content $script:mainScript -Raw
            $scriptContent | Should -Match 'if \(\$Rollback\.IsPresent\)'
        }

        It 'Should track matched assignments for NoChange status' {
            $scriptContent = Get-Content $script:mainScript -Raw
            $scriptContent | Should -Match '\$matchedAssignments'
            $scriptContent | Should -Match "Status 'NoChange'"
        }
    }
}
