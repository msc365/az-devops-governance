// using './main.tests.bicep'
using none

import {
  getLocationCode
} from '../../../main.bicep'

param resourceName = 'rg-example-dev-${locationCode}'

// ------------------ //
// Location Functions //
// ------------------ //

param locationCode = getLocationCode('westeurope')
