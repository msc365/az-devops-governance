metadata name = 'Managed identity'
metadata description = 'This nested module deploys a user-assigned managed identity.'
metadata owner = 'project-administrators'

targetScope = 'resourceGroup'

// ---------- //
// PARAMETERS //
// ---------- //

@description('Required. The name of the managed identity to create.')
param managedIdentityName string

@description('Optional. The Azure location to deploy the managed identity to.')
param location string = resourceGroup().location

@description('Optional. Tags to apply to the managed identity.')
param tags object = {}

// --------- //
// RESOURCES //
// --------- //

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2025-01-31-preview' = {
  name: managedIdentityName
  location: location
  tags: tags
}

// ------- //
// OUTPUTS //
// ------- //

@description('The name of the managed identity.')
output name string = managedIdentity.name

@description('The client ID of the managed identity.')
output clientId string = managedIdentity.properties.clientId

@description('The principal ID of the managed identity.')
output principalId string = managedIdentity.properties.principalId

@description('The resource ID of the managed identity.')
output resourceId string = managedIdentity.id
