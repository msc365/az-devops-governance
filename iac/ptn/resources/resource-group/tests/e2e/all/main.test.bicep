metadata name = 'Using all'
metadata description = 'This instance deploys the module with all parameters.'

targetScope = 'subscription'

// ========== //
// PARAMETERS //
// ========== //

@description('Optional. A short identifier for the kind of deployment. Should be kept short to not run into resource-name length-constraints.')
param serviceShort string = 'rrgmin'

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
    name: '${uniqueString(deployment().name, resourceLocation)}-test-${serviceShort}-${iteration}'
    params: {
      resourceGroups: [
        {
          name: 'rg-${namePrefix}${serviceShort}-test-${iteration}'
          location: resourceLocation
          tags: {
            public: 'false'
            service: serviceShort
            reason: 'e2e-test'
          }
        }
      ]
    }
  }
]
