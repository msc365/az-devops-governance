metadata name = 'Managed identity'
metadata description = 'This module deploys user-assigned managed identities used for end-to-end governance.'
metadata owner = 'project-administrators'

targetScope = 'subscription'

// ---------- //
// PARAMETERS //
// ---------- //

import { governanceIdentityType } from '../../../utl/custom-types/main.bicep'
@description('Required. The list of governance identities to create managed identities for.')
param managedIdentities governanceIdentityType[]

// --------- //
// RESOURCES //
// --------- //

// Existing resource groups
resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' existing = [
  for (rg, index) in managedIdentities: {
    name: rg.resourceGroup
  }
]

// Nested managed identity modules
module managedIdentity 'modules/nested_managedIdentity.bicep' = [
  for (identity, index) in managedIdentities: {
    scope: resourceGroup[index]
    name: '${uniqueString(deployment().name, identity.name)}-managedIdentity-${index}'
    params: {
      managedIdentityName: identity.name
      location: identity.?location
      tags: identity.?tags
    }
  }
]

// // ------- //
// // OUTPUTS //
// // ------- //

@description('The list of managed identities created.')
output managedIdentities array = [
  for (identity, index) in managedIdentities: {
    name: managedIdentity[index].outputs.name
    clientId: managedIdentity[index].outputs.clientId
    principalId: managedIdentity[index].outputs.principalId
    resourceId: managedIdentity[index].outputs.resourceId
  }
]
