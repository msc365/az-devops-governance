metadata name = 'Role assignments at Resource group scope'
metadata description = 'This module deploys role assignments at the resource group scope used for end-to-end governance.'
metadata owner = 'project-administrators'

extension microsoftGraphV1

targetScope = 'subscription'

// ---------- //
// PARAMETERS //
// ---------- //

@description('Required. The ID of the custom `Headless Owner (DevOps CI/CD)` role definition to assign.')
param customRoleDefinitionId string

// Security group unique names
@description('Required. The unique name of the administrators security group.')
param administratorGroupUniqueName string

@description('Required. The unique name of the developers security group.')
param developerGroupUniqueName string

@description('Required. The unique name of the stakeholders security group.')
param stakeholderGroupUniqueName string

// Managed identity names
@description('Required. The name of the managed identity to use as the owner of the development resource groups.')
param developmentManagedIdentityName string

@description('Required. The name of the managed identity to use as the owner of the production resource groups.')
param productionManagedIdentityName string

// Resource group names
@description('Required. The name of the development resource group.')
param developmentResourceGroupName string

@description('Required. The name of the production resource group.')
param productionResourceGroupName string

// ------------------ //
// EXISTING RESOURCES //
// ------------------ //

// Custom Role Definition - Headless Owner (DevOps CI/CD)
resource customRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: customRoleDefinitionId
}

// Entra ID Security Groups - Existing
resource administratorGroup 'Microsoft.Graph/groups@v1.0' existing = {
  uniqueName: administratorGroupUniqueName
}

resource developerGroup 'Microsoft.Graph/groups@v1.0' existing = {
  uniqueName: developerGroupUniqueName
}

resource stakeholderGroup 'Microsoft.Graph/groups@v1.0' existing = {
  uniqueName: stakeholderGroupUniqueName
}

// Managed Identities - Existing
resource managedIdentity_development 'Microsoft.ManagedIdentity/userAssignedIdentities@2025-01-31-preview' existing = {
  scope: resourceGroup_development
  name: developmentManagedIdentityName
}

resource managedIdentity_production 'Microsoft.ManagedIdentity/userAssignedIdentities@2025-01-31-preview' existing = {
  scope: resourceGroup_production
  name: productionManagedIdentityName
}

// Resource Groups - Existing
resource resourceGroup_development 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  name: developmentResourceGroupName
}

resource resourceGroup_production 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  name: productionResourceGroupName
}

// --------- //
// RESOURCES //
// --------- //

// Managed Identities - Subscription - Role Assignment
module managedIdentityRoleAssignment_development 'br/public:avm/res/authorization/role-assignment/rg-scope:0.1.1' = {
  scope: resourceGroup_development
  params: {
    principalId: managedIdentity_development.properties.principalId
    roleDefinitionIdOrName: customRoleDefinition.id
    principalType: 'ServicePrincipal'
  }
}

module managedIdentityRoleAssignment_production 'br/public:avm/res/authorization/role-assignment/rg-scope:0.1.1' = {
  scope: resourceGroup_production
  params: {
    principalId: managedIdentity_production.properties.principalId
    roleDefinitionIdOrName: customRoleDefinition.id
    principalType: 'ServicePrincipal'
  }
}

// Administrators Group - Resource Group - Role Assignment
module administratorGroupRoleAssignment_development 'br/public:avm/res/authorization/role-assignment/rg-scope:0.1.1' = {
  scope: resourceGroup_development
  params: {
    principalId: administratorGroup.id
    roleDefinitionIdOrName: 'Owner'
    principalType: 'Group'
  }
}

module administratorGroupRoleAssignment_production 'br/public:avm/res/authorization/role-assignment/rg-scope:0.1.1' = {
  scope: resourceGroup_production
  params: {
    principalId: administratorGroup.id
    roleDefinitionIdOrName: 'Owner'
    principalType: 'Group'
  }
}

// Developers Group - Resource Group - Role Assignment
module developerGroupRoleAssignment_development 'br/public:avm/res/authorization/role-assignment/rg-scope:0.1.1' = {
  scope: resourceGroup_development
  params: {
    principalId: developerGroup.id
    roleDefinitionIdOrName: 'Owner'
    principalType: 'Group'
  }
}

module developerGroupRoleAssignment_production 'br/public:avm/res/authorization/role-assignment/rg-scope:0.1.1' = {
  scope: resourceGroup_production
  params: {
    principalId: developerGroup.id
    roleDefinitionIdOrName: 'Contributor'
    principalType: 'Group'
  }
}

// Readers Group - Resource Group - Role Assignment
module stakeholderGroupRoleAssignment_development 'br/public:avm/res/authorization/role-assignment/rg-scope:0.1.1' = {
  scope: resourceGroup_development
  params: {
    principalId: stakeholderGroup.id
    roleDefinitionIdOrName: 'Reader'
    principalType: 'Group'
  }
}

module stakeholderGroupRoleAssignment_production 'br/public:avm/res/authorization/role-assignment/rg-scope:0.1.1' = {
  scope: resourceGroup_production
  params: {
    principalId: stakeholderGroup.id
    roleDefinitionIdOrName: 'Reader'
    principalType: 'Group'
  }
}

// ------- //
// OUTPUTS //
// ------- //

// Development outputs

output developmentRoleAssignmentResourceIds object = {
  managedIdentity: managedIdentityRoleAssignment_development.outputs.resourceId
  administratorGroup: administratorGroupRoleAssignment_development.outputs.resourceId
  developerGroup: developerGroupRoleAssignment_development.outputs.resourceId
  stakeholderGroup: stakeholderGroupRoleAssignment_development.outputs.resourceId
}

// Production outputs
output productionRoleAssignmentResourceIds object = {
  managedIdentity: managedIdentityRoleAssignment_production.outputs.resourceId
  administratorGroup: administratorGroupRoleAssignment_production.outputs.resourceId
  developerGroup: developerGroupRoleAssignment_production.outputs.resourceId
  stakeholderGroup: stakeholderGroupRoleAssignment_production.outputs.resourceId
}
