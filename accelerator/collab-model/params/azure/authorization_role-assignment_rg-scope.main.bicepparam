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
var serviceShort = '${config.prefix}-${toLower(config.service)}-${config.uniqueId}'

// ---------- //
// PARAMETERS //
// ---------- //

// Custom role definition ID for Headless Owner (DevOps CI/CD)
param customRoleDefinitionId = 'd71dc0cc-cb2e-52dd-b167-928dbda9d909'

// Security groups object-based pattern
param securityGroups = {
  administrators: { name: '${serviceShort}-admins' }
  developers: { name: '${serviceShort}-devs' }
  stakeholders: { name: '${serviceShort}-stakes' }
}

// Managed identities object-based pattern
param managedIdentities = {
  development: { name: 'id-${serviceShort}-dev' }
  production: { name: 'id-${serviceShort}-prd' }
}

// Resource groups object-based pattern
param resourceGroups = {
  development: { name: 'rg-${serviceShort}-dev-${geoCode}' }
  production: { name: 'rg-${serviceShort}-prd-${geoCode}' }
}
