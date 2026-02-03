using '../../../../iac/ptn/managed-identity/user-assigned-identity/main.bicep'

import {
  getLocationCode
} from '../../../../iac/utl/functions/custom-functions/main.bicep'

// --------- //
// VARIABLES //
// --------- //

var config = loadJsonContent('../../config/main.config.json')

var location = config.location
var geoCode = getLocationCode(location)

var serviceShortCCoE = '${config.prefix}-ccoe-${config.uniqueId}'
var serviceShortPortugal = '${config.prefix}-portugal-${config.uniqueId}'

// ---------- //
// PARAMETERS //
// ---------- //

param managedIdentities = [
  // CCoE Managed Identities
  {
    name: 'id-${serviceShortCCoE}-dev'
    resourceGroup: 'rg-${serviceShortCCoE}-dev-${geoCode}'
    location: location
    tags: {
      public: 'false'
      service: serviceShortCCoE
      environment: 'dev'
      security: 'rbac'
      iac: 'bicep'
      ci: 'azure-pipelines'
    }
  }
  {
    name: 'id-${serviceShortCCoE}-prd'
    resourceGroup: 'rg-${serviceShortCCoE}-prd-${geoCode}'
    location: location
    tags: {
      public: 'false'
      service: serviceShortCCoE
      environment: 'prd'
      security: 'rbac'
      iac: 'bicep'
      ci: 'azure-pipelines'
    }
  }
  // Portugal Managed Identities
  {
    name: 'id-${serviceShortPortugal}-dev'
    resourceGroup: 'rg-${serviceShortPortugal}-dev-${geoCode}'
    location: location
    tags: {
      public: 'false'
      service: serviceShortPortugal
      environment: 'dev'
      security: 'rbac'
      iac: 'bicep'
      ci: 'azure-pipelines'
    }
  }
  {
    name: 'id-${serviceShortPortugal}-prd'
    resourceGroup: 'rg-${serviceShortPortugal}-prd-${geoCode}'
    location: location
    tags: {
      public: 'false'
      service: serviceShortPortugal
      environment: 'prd'
      security: 'rbac'
      iac: 'bicep'
      ci: 'azure-pipelines'
    }
  }
]
