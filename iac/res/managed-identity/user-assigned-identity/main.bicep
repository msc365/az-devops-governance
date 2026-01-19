metadata name = 'Managed Service Identity'
metadata description = 'This module deploys a managed service identity for end-to-end governance.'
metadata owner = 'project-administrators'

extension microsoftGraphV1

targetScope = 'subscription'

// ---------- //
// PARAMETERS //
// ---------- //

// Managed identity names
@description('Required. The name of the managed identity to create for the development environment.')
param developmentManagedIdentityName string

@description('Required. The name of the managed identity to create for the production environment.')
param productionManagedIdentityName string

// Resource group names
@description('Required. The name of the development resource group.')
param developmentResourceGroupName string

@description('Required. The name of the production resource group.')
param productionResourceGroupName string

// Optional parameters
@description('Optional. The Azure location to deploy the managed identity to.')
param location string = deployment().location

@description('Optional. Tags to apply to the managed identity.')
param serviceShort string = 'e2egov'

// --------- //
// RESOURCES //
// --------- //

// Resource Groups - Existing
resource resourceGroup_development 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  name: developmentResourceGroupName
}

resource resourceGroup_production 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  name: productionResourceGroupName
}

module managedIdentity_development 'modules/nested_managedIdentity.bicep' = {
  scope: resourceGroup_development
  name: '${uniqueString(deployment().name, location)}-managedIdentity-dev'
  params: {
    managedIdentityName: developmentManagedIdentityName
    location: location
    tags: {
      public: 'false'
      service: serviceShort
      environment: 'dev'
      security: 'rbac'
      iac: 'bicep'
      ci: 'azure-pipelines'
    }
  }
}

module managedIdentity_production 'modules/nested_managedIdentity.bicep' = {
  scope: resourceGroup_production
  name: '${uniqueString(deployment().name, location)}-managedIdentity-prd'
  params: {
    managedIdentityName: productionManagedIdentityName
    location: location
    tags: {
      public: 'false'
      service: serviceShort
      environment: 'prd'
      security: 'rbac'
      iac: 'bicep'
      ci: 'azure-pipelines'
    }
  }
}

// ------- //
// OUTPUTS //
// ------- //

@description('The managed identity created for the development environment.')
output managedIdentityDevelopment object = {
  name: managedIdentity_development.outputs.name
  clientId: managedIdentity_development.outputs.clientId
  principalId: managedIdentity_development.outputs.principalId
  resourceId: managedIdentity_development.outputs.resourceId
}

@description('The managed identity created for the production environment.')
output managedIdentityProduction object = {
  name: managedIdentity_production.outputs.name
  clientId: managedIdentity_production.outputs.clientId
  principalId: managedIdentity_production.outputs.principalId
  resourceId: managedIdentity_production.outputs.resourceId
}
