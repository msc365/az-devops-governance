using '../main.bicep'

import {
  getLocationCode
} from '../../../../../utl/custom-functions/main.bicep'

var config = loadJsonContent('../../../../../../src/cfg/main.config.json')

var resourceName = '${config.prefix}-prj${config.uniqueId}'

// Headless Owner (DevOps CI/CD)
param customRoleDefinitionId = '<custom-role-definition-id>'

// Security group unique names
param stakeholderGroupUniqueName = 'sg-${resourceName}-stakeholders'
param developerGroupUniqueName = 'sg-${resourceName}-developers'
param administratorGroupUniqueName = 'sg-${resourceName}-administrators'

// Managed identity names
param developmentManagedIdentityName = 'id-${resourceName}-dev'
param productionManagedIdentityName = 'id-${resourceName}-prd'

// Resource group names
param developmentResourceGroupName = 'rg-${resourceName}-dev-${getLocationCode(config.location)}'
param productionResourceGroupName = 'rg-${resourceName}-prd-${getLocationCode(config.location)}'

// Subscription IDs
param developmentSubscriptionId = ''
param productionSubscriptionId = ''
