# ========== #
# Parameters #
# ========== #

$params = @{
    Organization      = 'my-org'
    Project           = 'my-project'
    MailNickname      = 'sg-my-project-admins-tst'
    DisplayName       = 'SG My Project Admins TST'
    Description       = 'End-to-end administrators test security group sample.'
    ManagedIdentity   = @{
        Name              = 'id-my-project-tst-weu'
        SubscriptionId    = '00000000-0000-0000-0000-000000000000'
        ResourceGroupName = 'rg-my-project-tst-weu'
        Location          = 'westeurope'
        Tags              = @{
            public      = 'false'
            service     = 'my-project'
            environment = 'tst'
            security    = 'rbac'
            iac         = 'bicep'
            ci          = 'azure-pipelines'
        }
    }
    ServiceConnection = @{
        Name  = 'sub-my-project-tst-weu'
        Scope = '/subscriptions/00000000-0000-0000-0000-000000000000'
    }
    GroupMembership   = @(
        'Project Administrators'
    )
    RoleAssignments   = @(
        @{
            ObjectType         = 'ServicePrincipal'
            RoleDefinitionName = 'Headless Owner (DevOps CI/CD)'
            Scope              = '/subscriptions/00000000-0000-0000-0000-000000000000'
        },
        @{
            ObjectType         = 'Group'
            RoleDefinitionName = 'Owner'
            Scope              = '/subscriptions/00000000-0000-0000-0000-000000000000'
        }
    )
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
