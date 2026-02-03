metadata name = 'Role assignments at resource group scope'
metadata description = 'This module deploys role assignments at the resource group scope used for end-to-end governance.'
metadata owner = 'project-administrators'

extension microsoftGraphV1

targetScope = 'subscription'

// ---------- //
// PARAMETERS //
// ---------- //

@description('Required. The ID of the custom `Headless Owner (DevOps CI/CD)` role definition to assign.')
param customRoleDefinitionId string

@description('Required. Security groups type containing administrator, developer, and stakeholder group configurations.')
param securityGroups securityGroupsType[]

@description('Required. Managed identities type containing development and production managed identity configurations.')
param managedIdentities managedIdentitiesType[]

@description('Required. Resource groups type containing development and production resource group configurations.')
param resourceGroups resourceGroupsType[]

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

resource administratorGroups 'Microsoft.Graph/groups@v1.0' existing = [
  for (sg, i) in securityGroups: {
    uniqueName: sg.administrators.name
  }
]

resource developerGroups 'Microsoft.Graph/groups@v1.0' existing = [
  for (sg, i) in securityGroups: {
    uniqueName: sg.developers.name
  }
]

resource stakeholderGroups 'Microsoft.Graph/groups@v1.0' existing = [
  for (sg, i) in securityGroups: {
    uniqueName: sg.stakeholders.name
  }
]

// ------------------ //
// Managed Identities //

resource developmentManagedIdentities 'Microsoft.ManagedIdentity/userAssignedIdentities@2025-01-31-preview' existing = [
  for (mi, i) in managedIdentities: {
    scope: developmentResourceGroups[i]
    name: mi.development.name
  }
]

resource productionManagedIdentities 'Microsoft.ManagedIdentity/userAssignedIdentities@2025-01-31-preview' existing = [
  for (mi, i) in managedIdentities: {
    scope: productionResourceGroups[i]
    name: mi.production.name
  }
]

// --------------- //
// Resource Groups //

resource developmentResourceGroups 'Microsoft.Resources/resourceGroups@2021-04-01' existing = [
  for (rg, i) in resourceGroups: {
    name: rg.development.name
  }
]

resource productionResourceGroups 'Microsoft.Resources/resourceGroups@2021-04-01' existing = [
  for (rg, i) in resourceGroups: {
    name: rg.production.name
  }
]

// --------- //
// RESOURCES //
// --------- //

// Managed Identities - Role Assignment
module managedIdentityRoleAssignments_development 'br/public:avm/res/authorization/role-assignment/rg-scope:0.1.1' = [
  for (mi, i) in managedIdentities: {
    scope: developmentResourceGroups[i]
    params: {
      principalId: developmentManagedIdentities[i].properties.principalId
      roleDefinitionIdOrName: customRoleDefinition.id
      principalType: 'ServicePrincipal'
    }
  }
]

module managedIdentityRoleAssignments_production 'br/public:avm/res/authorization/role-assignment/rg-scope:0.1.1' = [
  for (mi, i) in managedIdentities: {
    scope: productionResourceGroups[i]
    params: {
      principalId: productionManagedIdentities[i].properties.principalId
      roleDefinitionIdOrName: customRoleDefinition.id
      principalType: 'ServicePrincipal'
    }
  }
]

// Administrators Group - Role Assignment
module administratorGroupRoleAssignments_development 'br/public:avm/res/authorization/role-assignment/rg-scope:0.1.1' = [
  for (sg, i) in securityGroups: {
    scope: developmentResourceGroups[i]
    params: {
      principalId: administratorGroups[i].id
      roleDefinitionIdOrName: 'Owner'
      principalType: 'Group'
    }
  }
]

module administratorGroupRoleAssignments_production 'br/public:avm/res/authorization/role-assignment/rg-scope:0.1.1' = [
  for (sg, i) in securityGroups: {
    scope: productionResourceGroups[i]
    params: {
      principalId: administratorGroups[i].id
      roleDefinitionIdOrName: 'Owner'
      principalType: 'Group'
    }
  }
]

// Developers Group - Role Assignment
module developerGroupRoleAssignments_development 'br/public:avm/res/authorization/role-assignment/rg-scope:0.1.1' = [
  for (sg, i) in securityGroups: {
    scope: developmentResourceGroups[i]
    params: {
      principalId: developerGroups[i].id
      roleDefinitionIdOrName: 'Owner'
      principalType: 'Group'
    }
  }
]

module developerGroupRoleAssignments_production 'br/public:avm/res/authorization/role-assignment/rg-scope:0.1.1' = [
  for (sg, i) in securityGroups: {
    scope: productionResourceGroups[i]
    params: {
      principalId: developerGroups[i].id
      roleDefinitionIdOrName: 'Contributor'
      principalType: 'Group'
    }
  }
]

// Readers Group - Role Assignment
module stakeholderGroupRoleAssignments_development 'br/public:avm/res/authorization/role-assignment/rg-scope:0.1.1' = [
  for (sg, i) in securityGroups: {
    scope: developmentResourceGroups[i]
    params: {
      principalId: stakeholderGroups[i].id
      roleDefinitionIdOrName: 'Reader'
      principalType: 'Group'
    }
  }
]

module stakeholderGroupRoleAssignments_production 'br/public:avm/res/authorization/role-assignment/rg-scope:0.1.1' = [
  for (sg, i) in securityGroups: {
    scope: productionResourceGroups[i]
    params: {
      principalId: stakeholderGroups[i].id
      roleDefinitionIdOrName: 'Reader'
      principalType: 'Group'
    }
  }
]

// ----- //
// TYPES //
// ----- //

@description('Type definition for security groups used in end-to-end governance.')
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

@description('Type definition for managed identities used in end-to-end governance.')
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

@description('Type definition for resource groups used in end-to-end governance.')
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

// ------- //
// OUTPUTS //
// ------- //

// Development outputs
output developmentRoleAssignmentResourceIds array = [
  for (sg, i) in securityGroups: {
    managedIdentity: managedIdentityRoleAssignments_development[i].outputs.resourceId
    administratorGroup: administratorGroupRoleAssignments_development[i].outputs.resourceId
    developerGroup: developerGroupRoleAssignments_development[i].outputs.resourceId
    stakeholderGroup: stakeholderGroupRoleAssignments_development[i].outputs.resourceId
  }
]

// Production outputs
output productionRoleAssignmentResourceIds array = [
  for (sg, i) in securityGroups: {
    managedIdentity: managedIdentityRoleAssignments_production[i].outputs.resourceId
    administratorGroup: administratorGroupRoleAssignments_production[i].outputs.resourceId
    developerGroup: developerGroupRoleAssignments_production[i].outputs.resourceId
    stakeholderGroup: stakeholderGroupRoleAssignments_production[i].outputs.resourceId
  }
]
