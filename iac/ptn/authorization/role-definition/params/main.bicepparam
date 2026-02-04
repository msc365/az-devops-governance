using '../main.bicep'

param assignableScopes = [
  '/providers/Microsoft.Management/managementGroups/<your-management-group>'
  '/subscriptions/<your-subscription-id-dev>'
  '/subscriptions/<your-subscription-id-prd>'
]
