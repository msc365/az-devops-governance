metadata name = 'Role Definition Headless Owner (DevOps CI/CD)'
metadata description = 'This module deploys a Role definition at a Management group scope.'
metadata owner = 'platform-engineers'

targetScope = 'managementGroup'

// ---------- //
// PARAMETERS //
// ---------- //

@description('Required. The assignable scopes of the custom role definition. If not specified, the management group being targeted in the parameter managementGroupName will be used.')
param assignableScopes array

// --------- //
// RESOURCES //
// --------- //

module roleDefinition 'br/public:avm/ptn/authorization/role-definition:0.1.1' = {
  params: {
    name: 'headless-owner-devops-ci-cd)'
    roleName: 'Headless Owner (DevOps CI/CD)'
    description: 'Grants access to manage all resources, including the ability to assign roles in Azure RBAC, excluding irreversible destructive changes.'
    actions: [
      '*'
    ]
    notActions: [
      'Microsoft.Authorization/*/Delete'
    ]
    assignableScopes: assignableScopes
  }
}

// ------- //
// OUTPUTS //
// ------- //

@description('The resource ID of the role definition.')
output resourceId string = roleDefinition.outputs.roleDefinitionIdName
