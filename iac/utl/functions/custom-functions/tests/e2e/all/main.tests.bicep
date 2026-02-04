metadata name = 'Import all user-defined functions'
metadata description = '''
This example imports all available user-defined functions of the given module.

Note: In your module you would import only the functions you need.
'''
metadata owner = 'platform-engineers'

// -------------- //
// TEST EXECUTION //
// -------------- //

import {
  getLocationCode
} from '../../../main.bicep'

param ResourceName string = 'rg-example-dev-${LocationCode}'

output ResourceNameOutput string = ResourceName

// ------------------ //
// Location Functions //
// ------------------ //

param LocationCode string = getLocationCode('westeurope')

output LocationCodeOutput string = LocationCode

// Dynamic Location Code

param DynamicLocationCode string = getLocationCode(resourceGroup().location)

output DynamicLocationCodeOutput string = DynamicLocationCode
