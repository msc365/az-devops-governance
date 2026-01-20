metadata name = 'Resource groups'
metadata description = 'This module deploys resource groups used for end-to-end governance.'
metadata owner = 'project-administrators'

targetScope = 'subscription'

// ---------- //
// PARAMETERS //
// ---------- //

import { governanceResourceGroupType } from '../../../utl/custom-types/main.bicep'
@description('Required. The list of governance resource groups to create resource groups for.')
param resourceGroups governanceResourceGroupType[]

// --------- //
// RESOURCES //
// --------- //

module resourceGroup 'br/public:avm/res/resources/resource-group:0.4.1' = [
  for (rg, index) in resourceGroups: {
    params: {
      name: rg.name
      location: rg.?location
      tags: rg.?tags
    }
  }
]

// ------- //
// OUTPUTS //
// ------- //

@description('The list of resource groups created.')
output resourceGroups array = [
  for (rg, index) in resourceGroups: {
    name: resourceGroup[index].outputs.name
    location: resourceGroup[index].outputs.location
    resourceId: resourceGroup[index].outputs.resourceId
  }
]
