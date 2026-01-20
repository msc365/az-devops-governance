using '../main.bicep'

import {
  getLocationCode
} from '../../../../../utl/functions/custom-functions/main.bicep'

// --------- //
// VARIABLES //
// --------- //

var config = loadJsonContent('../../../../../../src/cfg/main.config.json')

var location = config.location
var geoCode = getLocationCode(location)
var serviceShort = '${config.prefix}-prj${config.uniqueId}'

// ---------- //
// PARAMETERS //
// ---------- //

// Custom role definition ID for Headless Owner (DevOps CI/CD)
param customRoleDefinitionId = '<custom-role-definition-id>'

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

// Subscriptions object-based pattern
param subscriptions = {
  development: { id: '' }
  production: { id: '' }
}
