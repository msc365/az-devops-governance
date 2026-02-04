metadata name = 'Defaults only'
metadata description = 'This instance deploys the module with default parameters.'

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
      customRoleDefinitionId: '8e3af657-a8ff-443c-a75c-2fe8c4bcb635' // Owner role for test only
      // Security groups object-based pattern
      securityGroups: {
        administrators: { name: '${namePrefix}prj${serviceShort}-admins' }
        developers: { name: '${namePrefix}prj${serviceShort}-devs' }
        stakeholders: { name: '${namePrefix}prj${serviceShort}-stakes' }
      }

      // Managed identities object-based pattern
      managedIdentities: {
        development: { name: 'id-${namePrefix}prj${serviceShort}-dev' }
        production: { name: 'id-${namePrefix}prj${serviceShort}-prd' }
      }

      // Resource groups object-based pattern
      resourceGroups: {
        development: { name: 'rg-${namePrefix}prj${serviceShort}-dev-weu' }
        production: { name: 'rg-${namePrefix}prj${serviceShort}-prd-weu' }
      }

      subscriptions: {
        development: { id: subscription().subscriptionId }
        production: { id: subscription().subscriptionId }
      }
    }
  }
]
