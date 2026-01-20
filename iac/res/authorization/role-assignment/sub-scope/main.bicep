metadata name = 'Role assignments at subscription scope'
metadata description = 'This module deploys role assignments at the subscription scope used for end-to-end governance.'
metadata owner = 'project-administrators'

extension microsoftGraphV1

targetScope = 'subscription'

// ---------- //
// PARAMETERS //
// ---------- //

@description('Required. The ID of the custom `Headless Owner (DevOps CI/CD)` role definition to assign.')
param customRoleDefinitionId string

@description('Required. Security groups type containing administrator, developer, and stakeholder group configurations.')
param securityGroups securityGroupsType

@description('Required. Managed identities type containing development and production managed identity configurations.')
param managedIdentities managedIdentitiesType

@description('Required. Resource groups type containing development and production resource group configurations.')
param resourceGroups resourceGroupsType

@description('Required. Subscriptions type containing development and production subscription configurations.')
param subscriptions subscriptionsType

// -------- //
// EXISTING //
// -------- //

// ---------------------- //
// Custom Role Definition //

resource customRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: customRoleDefinitionId
}

// ---------------- //
// Security  groups //

resource administratorGroup 'Microsoft.Graph/groups@v1.0' existing = {
  uniqueName: securityGroups.administrators.name
}

resource developerGroup 'Microsoft.Graph/groups@v1.0' existing = {
  uniqueName: securityGroups.developers.name
}

resource stakeholderGroup 'Microsoft.Graph/groups@v1.0' existing = {
  uniqueName: securityGroups.stakeholders.name
}

// --------------- //
// Resource Groups //

resource developmentResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  name: resourceGroups.development.name
}

resource productionResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  name: resourceGroups.production.name
}

// ------------------ //
// Managed Identities //

resource developmentMangedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2025-01-31-preview' existing = {
  scope: developmentResourceGroup
  name: managedIdentities.development.name
}

resource productionMangedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2025-01-31-preview' existing = {
  scope: productionResourceGroup
  name: managedIdentities.production.name
}

// --------- //
// RESOURCES //
// --------- //

// Managed Identities - Role Assignment
module managedIdentityRoleAssignment_development 'br/public:avm/res/authorization/role-assignment/sub-scope:0.1.1' = if (!empty(subscriptions.development.id)) {
  scope: subscription(subscriptions.development.id)
  params: {
    principalId: developmentMangedIdentity.properties.principalId
    roleDefinitionIdOrName: customRoleDefinition.id
    principalType: 'ServicePrincipal'
  }
}

module managedIdentityRoleAssignment_production 'br/public:avm/res/authorization/role-assignment/sub-scope:0.1.1' = if (!empty(subscriptions.production.id)) {
  scope: subscription(subscriptions.production.id)
  params: {
    principalId: productionMangedIdentity.properties.principalId
    roleDefinitionIdOrName: customRoleDefinition.id
    principalType: 'ServicePrincipal'
  }
}

// Administrators Group - Role Assignment
module administratorGroupRoleAssignment_development 'br/public:avm/res/authorization/role-assignment/sub-scope:0.1.1' = if (!empty(subscriptions.development.id)) {
  scope: subscription(subscriptions.development.id)
  params: {
    principalId: administratorGroup.id
    roleDefinitionIdOrName: 'Owner'
    principalType: 'Group'
  }
}

module administratorGroupRoleAssignment_production 'br/public:avm/res/authorization/role-assignment/sub-scope:0.1.1' = if (!empty(subscriptions.production.id)) {
  scope: subscription(subscriptions.production.id)
  params: {
    principalId: administratorGroup.id
    roleDefinitionIdOrName: 'Owner'
    principalType: 'Group'
  }
}

// Developers Group - Role Assignment
module developerGroupRoleAssignment_development 'br/public:avm/res/authorization/role-assignment/sub-scope:0.1.1' = if (!empty(subscriptions.development.id)) {
  scope: subscription(subscriptions.development.id)
  params: {
    principalId: developerGroup.id
    roleDefinitionIdOrName: 'Owner'
    principalType: 'Group'
  }
}

module developerGroupRoleAssignment_production 'br/public:avm/res/authorization/role-assignment/sub-scope:0.1.1' = if (!empty(subscriptions.production.id)) {
  scope: subscription(subscriptions.production.id)
  params: {
    principalId: developerGroup.id
    roleDefinitionIdOrName: 'Contributor'
    principalType: 'Group'
  }
}

// Readers Group - Role Assignment
module stakeholderGroupRoleAssignment_development 'br/public:avm/res/authorization/role-assignment/sub-scope:0.1.1' = if (!empty(subscriptions.development.id)) {
  scope: subscription(subscriptions.development.id)
  params: {
    principalId: stakeholderGroup.id
    roleDefinitionIdOrName: 'Reader'
    principalType: 'Group'
  }
}

module stakeholderGroupRoleAssignment_production 'br/public:avm/res/authorization/role-assignment/sub-scope:0.1.1' = if (!empty(subscriptions.production.id)) {
  scope: subscription(subscriptions.production.id)
  params: {
    principalId: stakeholderGroup.id
    roleDefinitionIdOrName: 'Reader'
    principalType: 'Group'
  }
}

// ----- //
// TYPES //
// ----- //

@description('Security groups type containing administrator, developer, and stakeholder group configurations.')
type securityGroupsType = {
  @description('Required. The administrators security group configuration.')
  administrators: {
    @description('Required. The unique name of the administrators security group.')
    name: string
  }
  @description('Required. The developers security group configuration.')
  developers: {
    @description('Required. The unique name of the developers security group.')
    name: string
  }
  @description('Required. The stakeholders security group configuration.')
  stakeholders: {
    @description('Required. The unique name of the stakeholders security group.')
    name: string
  }
}

@description('Managed identities type containing development and production managed identity configurations.')
type managedIdentitiesType = {
  @description('Required. The development managed identity configuration.')
  development: {
    @description('Required. The name of the development managed identity.')
    name: string
  }
  @description('Required. The production managed identity configuration.')
  production: {
    @description('Required. The name of the production managed identity.')
    name: string
  }
}

@description('Resource groups type containing development and production resource group configurations.')
type resourceGroupsType = {
  @description('Required. The development resource group configuration.')
  development: {
    @description('Required. The name of the development resource group.')
    name: string
  }
  @description('Required. The production resource group configuration.')
  production: {
    @description('Required. The name of the production resource group.')
    name: string
  }
}

@description('Subscriptions type containing development and production subscription configurations.')
type subscriptionsType = {
  @description('Required. The development subscription configuration.')
  development: {
    @description('Required. The ID of the development subscription.')
    id: string
  }
  @description('Required. The production subscription configuration.')
  production: {
    @description('Required. The ID of the production subscription.')
    id: string
  }
}

// ------- //
// OUTPUTS //
// ------- //

// Development outputs
output developmentRoleAssignmentResourceIds object = {
  managedIdentity: managedIdentityRoleAssignment_development.?outputs.resourceId
  administratorGroup: administratorGroupRoleAssignment_development.?outputs.resourceId
  developerGroup: developerGroupRoleAssignment_development.?outputs.resourceId
  stakeholderGroup: stakeholderGroupRoleAssignment_development.?outputs.resourceId
}

// Production outputs
output productionRoleAssignmentResourceIds object = {
  managedIdentity: managedIdentityRoleAssignment_production.?outputs.resourceId
  administratorGroup: administratorGroupRoleAssignment_production.?outputs.resourceId
  developerGroup: developerGroupRoleAssignment_production.?outputs.resourceId
  stakeholderGroup: stakeholderGroupRoleAssignment_production.?outputs.resourceId
}
