using '../main.bicep'

import {
  getLocationCode
} from '../../../../utl/custom-functions/main.bicep'

var config = loadJsonContent('../../../../../src/cfg/main.config.json')

var resourceName = '${config.prefix}-prj${config.uniqueId}'

param serviceShort = 'prj${config.uniqueId}'

// Managed identity names
param developmentResourceGroupName = 'rg-${resourceName}-dev-${getLocationCode(config.location)}'
param productionResourceGroupName = 'rg-${resourceName}-prd-${getLocationCode(config.location)}'
