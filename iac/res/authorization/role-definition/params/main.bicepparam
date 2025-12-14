using '../main.bicep'

param managementGroupName = 'mg-alz-intermediate-stg'
param assignableScopes = [
  '/subscriptions/00000000-0000-0000-0000-000000000000'
  '/subscriptions/00000000-0000-0000-0000-000000000000'
  '/subscriptions/00000000-0000-0000-0000-000000000000'
  '/providers/Microsoft.Management/managementGroups/${managementGroupName}'
]
