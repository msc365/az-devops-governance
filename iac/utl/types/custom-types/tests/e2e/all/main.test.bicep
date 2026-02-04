metadata name = 'Import all types'
metadata description = '''
This example imports all available types of the given module.

Note: In your module you would import only the types you need.
'''
metadata owner = 'platform-engineers'

// -------------- //
// TEST EXECUTION //
// -------------- //

import {
  governanceIdentityType
  governanceSecurityGroupType
  governanceResourceGroupType
} from '../../../main.bicep'

param governanceIdentities governanceIdentityType[] = [
  {
    name: 'dev-identity'
    resourceGroup: 'dev-rg'
    location: 'eastus'
    tags: {
      project: 'governance'
    }
    environmentType: 'dev'
  }
  {
    name: 'prd-identity'
    resourceGroup: 'prd-rg'
    location: 'eastus2'
    tags: {
      project: 'governance'
    }
    environmentType: 'prd'
  }
]

output governanceIdentitiesOutput governanceIdentityType[] = governanceIdentities

param governanceSecurityGroups governanceSecurityGroupType[] = [
  {
    displayName: 'Dev Security Group'
    uniqueName: 'dev-sec-group'
    mailNickname: 'devsecgroup'
    description: 'Security group for development team'
    environmentType: 'dev'
  }
  {
    displayName: 'Prod Security Group'
    uniqueName: 'prd-sec-group'
    mailNickname: 'prdsecgroup'
    description: 'Security group for production team'
    environmentType: 'prd'
  }
]

output governanceSecurityGroupsOutput governanceSecurityGroupType[] = governanceSecurityGroups

param governanceResourceGroups governanceResourceGroupType[] = [
  {
    name: 'dev-rg'
    location: 'eastus'
    tags: {
      project: 'governance'
    }
    environmentType: 'dev'
  }
  {
    name: 'prd-rg'
    location: 'eastus2'
    tags: {
      project: 'governance'
    }
    environmentType: 'prd'
  }
]

output governanceResourceGroupsOutput governanceResourceGroupType[] = governanceResourceGroups
