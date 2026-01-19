using '../main.bicep'

import {
  getLocationCode
} from '../../../../utl/custom-functions/main.bicep'

var config = loadJsonContent('../../../../../src/cfg/main.config.json')

var resourceName = '${config.prefix}-prj${config.uniqueId}'

param location = 'westeurope'
param serviceShort = 'prj${config.uniqueId}'

// Managed identity names
param developmentManagedIdentityName = 'id-${resourceName}-dev'
param productionManagedIdentityName = 'id-${resourceName}-prd'

// Resource group names
param developmentResourceGroupName = 'rg-${resourceName}-dev-${getLocationCode(location)}'
param productionResourceGroupName = 'rg-${resourceName}-prd-${getLocationCode(location)}'
