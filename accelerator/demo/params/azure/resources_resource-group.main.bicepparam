using '../../../../iac/ptn/resources/resource-group/main.bicep'

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

param resourceGroups = [
  // CCoE Resource Groups
  {
    name: 'rg-${serviceShortCCoE}-dev-${geoCode}'
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
    name: 'rg-${serviceShortCCoE}-prd-${geoCode}'
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
  // Portugal Resource Groups
  {
    name: 'rg-${serviceShortPortugal}-dev-${geoCode}'
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
    name: 'rg-${serviceShortPortugal}-prd-${geoCode}'
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
