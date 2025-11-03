using '../main.bicep'

param managementGroupName = 'mg-alz-intermediate-prd'
param assignableScopes = [
  '/subscriptions/fb806ddb-a9c8-4c23-ade6-4d35ba393dd7' // avengers
  '/subscriptions/fc3df67d-efb5-4a2e-87ec-fa4dce269e1c' // guardians
  '/subscriptions/02f3a45f-f2a6-4598-b9a3-0e5b8e8a056d' // galaxy (shared)
  '/providers/Microsoft.Management/managementGroups/${managementGroupName}'
]
