metadata name = 'Role Definition - Headless Owner'
metadata description = 'This module deploys a Role Definition at a Management Group scope accordance to ALZs and Microsoft CAF.'
metadata owner = 'platform-engineers'

targetScope = 'managementGroup'

// PARAMETERS

@description('Required. The management group scope to which the role can be assigned. This management group ID will be used for the assignableScopes property in the role definition.')
param managementGroupName string

@description('Optional. The assignable scopes of the custom role definition. If not specified, the management group being targeted in the parameter managementGroupName will be used.')
param assignableScopes array = [
  '/providers/Microsoft.Management/managementGroups/${managementGroupName}'
]

// VARIABLES

var roleConfig = {
  name: 'Headless Owner (DevOps CI/CD)'
  description: 'Grants access to manage all resources, including the ability to assign roles in Azure RBAC, excluding irreversible destructive changes.'
}

// RESOURCES

module roleDefinition 'br/public:avm/ptn/authorization/role-definition:0.1.1' = {
  name: '${uniqueString(deployment().name)}-headless-owner-role'
  params: {
    name: roleConfig.name
    roleName: roleConfig.name
    description: roleConfig.description
    actions: [
      '*'
    ]
    notActions: [
      'Microsoft.Authorization/*/Delete'
    ]
    assignableScopes: assignableScopes
  }
}

// OUTPUTS

output roleDefinitionIdName string = roleDefinition.outputs.roleDefinitionIdName
