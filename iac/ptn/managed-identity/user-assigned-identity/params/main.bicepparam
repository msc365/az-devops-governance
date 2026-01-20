using '../main.bicep'

import {
  getLocationCode
} from '../../../../utl/functions/custom-functions/main.bicep'

// --------- //
// VARIABLES //
// --------- //

var config = loadJsonContent('../../../../../src/cfg/main.config.json')

var location = config.location
var geoCode = getLocationCode(location)
var serviceShort = '${config.prefix}-prj${config.uniqueId}'

// ---------- //
// PARAMETERS //
// ---------- //

param managedIdentities = [
  {
    name: 'id-${serviceShort}-dev'
    resourceGroup: 'rg-${serviceShort}-dev-${geoCode}'
    location: location
    tags: {
      public: 'false'
      service: serviceShort
      environment: 'dev'
      security: 'rbac'
      iac: 'bicep'
      ci: 'azure-pipelines'
    }
  }
  {
    name: 'id-${serviceShort}-prd'
    resourceGroup: 'rg-${serviceShort}-prd-${geoCode}'
    location: location
    tags: {
      public: 'false'
      service: serviceShort
      environment: 'prd'
      security: 'rbac'
      iac: 'bicep'
      ci: 'azure-pipelines'
    }
  }
]
