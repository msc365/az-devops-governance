metadata name = 'Resource group'
metadata description = 'This module deploys a resource group used for end-to-end governance.'
metadata owner = 'project-administrators'

targetScope = 'subscription'

// ---------- //
// PARAMETERS //
// ---------- //

@description('Required. The name of the development resource group.')
param developmentResourceGroupName string

@description('Required. The name of the production resource group.')
param productionResourceGroupName string

@description('Optional. The Azure location to deploy the resource groups to.')
param location string = deployment().location

@description('Optional. Tags to apply to the managed identity.')
param serviceShort string = 'e2egov'

// --------- //
// RESOURCES //
// --------- //

module resourceGroup_Development 'br/public:avm/res/resources/resource-group:0.4.1' = {
  params: {
    name: developmentResourceGroupName
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

module resourceGroup_Production 'br/public:avm/res/resources/resource-group:0.4.1' = {
  params: {
    name: productionResourceGroupName
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

@description('The development resource group.')
output resourceGroupDevelopment object = {
  name: resourceGroup_Development.outputs.name
  location: resourceGroup_Development.outputs.location
  resourceId: resourceGroup_Development.outputs.resourceId
}

@description('The production resource group.')
output resourceGroupProduction object = {
  name: resourceGroup_Production.outputs.name
  location: resourceGroup_Production.outputs.location
  resourceId: resourceGroup_Production.outputs.resourceId
}
