metadata name = 'Entra ID security groups'
metadata description = 'This module deploys Entra security groups used for end-to-end governance.'
metadata owner = 'project-administrators'

extension microsoftGraphV1

targetScope = 'subscription'

// ---------- //
// PARAMETERS //
// ---------- //

import { governanceSecurityGroupType } from '../../../utl/custom-types/main.bicep'
@description('Required. The list of Entra security groups to create.')
param securityGroups governanceSecurityGroupType[]

// --------- //
// RESOURCES //
// --------- //

resource securityGroup 'Microsoft.Graph/groups@v1.0' = [
  for (sg, index) in securityGroups: {
    displayName: sg.displayName
    uniqueName: sg.uniqueName
    mailNickname: sg.mailNickname
    mailEnabled: false
    securityEnabled: true
    description: sg.?description
  }
]

// ------- //
// OUTPUTS //
// ------- //

@description('The list of created Entra security groups.')
output securityGroups array = [
  for (sg, index) in securityGroups: {
    id: securityGroup[index].id
    displayName: securityGroup[index].displayName
    uniqueName: securityGroup[index].uniqueName
    mailNickname: securityGroup[index].mailNickname
  }
]
