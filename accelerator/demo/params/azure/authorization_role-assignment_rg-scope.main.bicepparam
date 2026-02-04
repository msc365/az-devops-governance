using '../../../../iac/ptn/authorization/role-assignment/rg-scope/main.bicep'

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

// Custom role definition ID for Headless Owner (DevOps CI/CD)
param customRoleDefinitionId = 'd71dc0cc-cb2e-52dd-b167-928dbda9d909'

// Security groups object-based pattern
param securityGroups = [
  {
    administrators: { name: '${serviceShortCCoE}-admins' }
    developers: { name: '${serviceShortCCoE}-devs' }
    stakeholders: { name: '${serviceShortCCoE}-stakes' }
  }
  {
    administrators: { name: '${serviceShortPortugal}-admins' }
    developers: { name: '${serviceShortPortugal}-devs' }
    stakeholders: { name: '${serviceShortPortugal}-stakes' }
  }
]

// Managed identities object-based pattern
param managedIdentities = [
  {
    development: { name: 'id-${serviceShortCCoE}-dev' }
    production: { name: 'id-${serviceShortCCoE}-prd' }
  }
  {
    development: { name: 'id-${serviceShortPortugal}-dev' }
    production: { name: 'id-${serviceShortPortugal}-prd' }
  }
]

// Resource groups object-based pattern
param resourceGroups = [
  {
    development: { name: 'rg-${serviceShortCCoE}-dev-${geoCode}' }
    production: { name: 'rg-${serviceShortCCoE}-prd-${geoCode}' }
  }
  {
    development: { name: 'rg-${serviceShortPortugal}-dev-${geoCode}' }
    production: { name: 'rg-${serviceShortPortugal}-prd-${geoCode}' }
  }
]
