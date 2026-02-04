metadata name = 'Using all'
metadata description = 'This instance deploys the module with all parameters.'

targetScope = 'subscription'

// ========== //
// PARAMETERS //
// ========== //

@description('Optional. A short identifier for the kind of deployment. Should be kept short to not run into resource-name length-constraints.')
param serviceShort string = 'E2eT3st'

@description('Optional. A token to inject into the name of each resource. This value can be automatically injected by the CI.')
param namePrefix string = 'e2egov-'

@description('Optional. The location to deploy resources to.')
param resourceLocation string = deployment().location

// ============== //
// TEST EXECUTION //
// ============== //

@batchSize(1)
module testDeployment '../../../main.bicep' = [
  for iteration in ['init', 'idem']: {
    name: '${uniqueString(deployment().name, resourceLocation)}-tests-${serviceShort}-${iteration}'
    params: {
      securityGroups: [
        {
          displayName: 'SG ${namePrefix}prj${serviceShort} Administrators'
          uniqueName: '${namePrefix}prj${serviceShort}-admins'
          mailNickname: '${namePrefix}prj${serviceShort}-admins'
          description: 'Administrators group for ${serviceShort} project.'
        }
        {
          displayName: 'SG ${namePrefix}prj${serviceShort} Developers'
          uniqueName: '${namePrefix}prj${serviceShort}-devs'
          mailNickname: '${namePrefix}prj${serviceShort}-devs'
          description: 'Developers group for ${serviceShort} project.'
        }
        {
          displayName: 'SG ${namePrefix}prj${serviceShort} Stakeholders'
          uniqueName: '${namePrefix}prj${serviceShort}-stakes'
          mailNickname: '${namePrefix}prj${serviceShort}-stakes'
          description: 'Stakeholders group for ${serviceShort} project.'
        }
      ]
    }
  }
]
