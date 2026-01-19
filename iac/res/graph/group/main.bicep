metadata name = 'Entra ID security groups'
metadata description = 'This module deploys Entra groups used for end-to-end governance.'
metadata owner = 'project-administrators'

extension microsoftGraphV1

targetScope = 'subscription'

// ---------- //
// PARAMETERS //
// ---------- //

@description('Optional. The ID of the custom `Headless Owner (DevOps CI/CD)` role definition to assign.')
param customRoleDefinitionId string = ''

@description('Required. The list of Entra security groups to create.')
param groups array

// --------- //
// RESOURCES //
// --------- //

resource graphGroups 'Microsoft.Graph/groups@v1.0' = [
  for (group, index) in groups: {
    displayName: group.displayName
    uniqueName: group.uniqueName
    mailNickname: group.mailNickname
    mailEnabled: false
    securityEnabled: true
    owners: !empty(customRoleDefinitionId)
      ? {
          relationships: [customRoleDefinitionId]
        }
      : null
  }
]

// ------- //
// OUTPUTS //
// ------- //

@description('The list of created Entra group IDs.')
output groups array = [
  for (group, index) in groups: {
    id: graphGroups[index].id
    displayName: graphGroups[index].displayName
    uniqueName: graphGroups[index].uniqueName
    mailNickname: graphGroups[index].mailNickname
  }
]
