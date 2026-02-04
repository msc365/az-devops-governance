<!-- markdownlint-disable -->
<!-- omit from toc -->
# Managed identity `[ManagedIdentity/userAssignedIdentity]`

This module deploys user-assigned managed identities used for end-to-end governance.

## Navigation

<!-- no toc -->
- [Resource Types](#resource-types)
- [Usage examples](#usage-examples)
- [Parameters](#parameters)
- [Outputs](#outputs)

## Resource Types

| Resource Type | API Version |
| :-- | :-- |
| `Microsoft.ManagedIdentity/userAssignedIdentities` | [2025-01-31-preview](https://learn.microsoft.com/en-us/azure/templates/Microsoft.ManagedIdentity/2025-01-31-preview/userAssignedIdentities) |

## Usage examples

The following section provides usage examples for the module, which were used to validate and deploy the module successfully. For a full reference, please review the module's test folder in its repository.

> **Note** <br>
> Each example lists all the required parameters first, followed by the rest - each in alphabetical order.

> **Note** <br>
> To reference the module, please use the following syntax `iac/ptn/managed-identity/user-assigned-identity/main.bicep`.

- [Using all](#example-1-using-all)
- [Default only](#example-2-default-only)

### Example 1: _Using all_

This instance deploys the module with all parameters.


<details>

<summary>via Bicep module</summary>

```bicep
module userAssignedIdentity 'iac/ptn/managed-identity/user-assigned-identity/main.bicep' = {
  name: 'userAssignedIdentityDeployment'
  params: {
    managedIdentities: [
      {
        location: '<location>'
        name: 'id-prjE2eT3st-dev'
        resourceGroup: 'rg-prjE2eT3st-dev-weu'
        tags: {
          public: 'false'
          reason: 'e2e-tests'
          service: '<service>'
        }
      }
      {
        location: '<location>'
        name: 'id-prjE2eT3st-prd'
        resourceGroup: 'rg-prjE2eT3st-prd-weu'
        tags: {
          public: 'false'
          reason: 'e2e-tests'
          service: '<service>'
        }
      }
    ]
  }
}
```

</details>
<p>

<details>

<summary>via JSON parameters file</summary>

```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "managedIdentities": {
      "value": [
        {
          "location": "<location>",
          "name": "id-prjE2eT3st-dev",
          "resourceGroup": "rg-prjE2eT3st-dev-weu",
          "tags": {
            "public": "false",
            "reason": "e2e-tests",
            "service": "<service>"
          }
        },
        {
          "location": "<location>",
          "name": "id-prjE2eT3st-prd",
          "resourceGroup": "rg-prjE2eT3st-prd-weu",
          "tags": {
            "public": "false",
            "reason": "e2e-tests",
            "service": "<service>"
          }
        }
      ]
    }
  }
}
```

</details>
<p>

<details>

<summary>via Bicep parameters file</summary>

```bicep-params
using 'iac/ptn/managed-identity/user-assigned-identity/main.bicep'

param managedIdentities = [
  {
    location: '<location>'
    name: 'id-prjE2eT3st-dev'
    resourceGroup: 'rg-prjE2eT3st-dev-weu'
    tags: {
      public: 'false'
      reason: 'e2e-tests'
      service: '<service>'
    }
  }
  {
    location: '<location>'
    name: 'id-prjE2eT3st-prd'
    resourceGroup: 'rg-prjE2eT3st-prd-weu'
    tags: {
      public: 'false'
      reason: 'e2e-tests'
      service: '<service>'
    }
  }
]
```

</details>
<p>

### Example 2: _Default only_

This instance deploys the module with default parameters.


<details>

<summary>via Bicep module</summary>

```bicep
module userAssignedIdentity 'iac/ptn/managed-identity/user-assigned-identity/main.bicep' = {
  name: 'userAssignedIdentityDeployment'
  params: {
    managedIdentities: [
      {
        name: 'id-prjE2eT3st-dev'
        resourceGroup: 'rg-prjE2eT3st-dev-weu'
      }
      {
        name: 'id-prjE2eT3st-prd'
        resourceGroup: 'rg-prjE2eT3st-prd-weu'
      }
    ]
  }
}
```

</details>
<p>

<details>

<summary>via JSON parameters file</summary>

```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "managedIdentities": {
      "value": [
        {
          "name": "id-prjE2eT3st-dev",
          "resourceGroup": "rg-prjE2eT3st-dev-weu"
        },
        {
          "name": "id-prjE2eT3st-prd",
          "resourceGroup": "rg-prjE2eT3st-prd-weu"
        }
      ]
    }
  }
}
```

</details>
<p>

<details>

<summary>via Bicep parameters file</summary>

```bicep-params
using 'iac/ptn/managed-identity/user-assigned-identity/main.bicep'

param managedIdentities = [
  {
    name: 'id-prjE2eT3st-dev'
    resourceGroup: 'rg-prjE2eT3st-dev-weu'
  }
  {
    name: 'id-prjE2eT3st-prd'
    resourceGroup: 'rg-prjE2eT3st-prd-weu'
  }
]
```

</details>
<p>

## Parameters

**Required parameters**

| Parameter | Type | Description |
| :-- | :-- | :-- |
| [`managedIdentities`](#parameter-managedidentities) | array | The list of governance identities to create managed identities for. |

### Parameter: `managedIdentities`

The list of governance identities to create managed identities for.

- Required: Yes
- Type: array

**Required parameters**

| Parameter | Type | Description |
| :-- | :-- | :-- |
| [`name`](#parameter-managedidentitiesname) | string | The name of the managed identity. |
| [`resourceGroup`](#parameter-managedidentitiesresourcegroup) | string | The resource group name of the managed identity. |

**Optional parameters**

| Parameter | Type | Description |
| :-- | :-- | :-- |
| [`environmentType`](#parameter-managedidentitiesenvironmenttype) | string | The environment type of the managed identity. |
| [`location`](#parameter-managedidentitieslocation) | string | The location of the managed identity. |
| [`tags`](#parameter-managedidentitiestags) | object | The tags of the managed identity used as metadata. |

### Parameter: `managedIdentities.name`

The name of the managed identity.

- Required: Yes
- Type: string

### Parameter: `managedIdentities.resourceGroup`

The resource group name of the managed identity.

- Required: Yes
- Type: string

### Parameter: `managedIdentities.environmentType`

The environment type of the managed identity.

- Required: No
- Type: string
- Allowed:
  ```Bicep
  [
    'dev'
    'prd'
    'sbx'
    'stg'
    'tst'
  ]
  ```

### Parameter: `managedIdentities.location`

The location of the managed identity.

- Required: No
- Type: string

### Parameter: `managedIdentities.tags`

The tags of the managed identity used as metadata.

- Required: No
- Type: object

## Outputs

| Output | Type | Description |
| :-- | :-- | :-- |
| `managedIdentities` | array | The list of managed identities created. |
