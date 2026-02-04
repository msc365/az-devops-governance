<!-- markdownlint-disable -->
<!-- omit from toc -->
# Resource groups `[Resources/resourceGroup]`

This module deploys resource groups used for end-to-end governance.

## Navigation

<!-- no toc -->
- [Resource Types](#resource-types)
- [Usage examples](#usage-examples)
- [Parameters](#parameters)
- [Outputs](#outputs)
- [Cross-referenced modules](#cross-referenced-modules)

## Resource Types

| Resource Type | API Version |
| :-- | :-- |
| `Microsoft.Authorization/locks` | [2020-05-01](https://learn.microsoft.com/en-us/azure/templates/Microsoft.Authorization/2020-05-01/locks) |
| `Microsoft.Authorization/roleAssignments` | [2022-04-01](https://learn.microsoft.com/en-us/azure/templates/Microsoft.Authorization/2022-04-01/roleAssignments) |
| `Microsoft.Resources/resourceGroups` | [2021-04-01](https://learn.microsoft.com/en-us/azure/templates/Microsoft.Resources/2021-04-01/resourceGroups) |

## Usage examples

The following section provides usage examples for the module, which were used to validate and deploy the module successfully. For a full reference, please review the module's test folder in its repository.

> **Note** <br>
> Each example lists all the required parameters first, followed by the rest - each in alphabetical order.

> **Note** <br>
> To reference the module, please use the following syntax `iac/ptn/resources/resource-group/main.bicep`.

- [Using all](#example-1-using-all)
- [Defaults only](#example-2-defaults-only)

### Example 1: _Using all_

This instance deploys the module with all parameters.


<details>

<summary>via Bicep module</summary>

```bicep
module resourceGroup 'iac/ptn/resources/resource-group/main.bicep' = {
  name: 'resourceGroupDeployment'
  params: {
    resourceGroups: [
      {
        location: '<location>'
        name: 'rg-prjE2eT3st-dev-weu'
        tags: {
          public: 'false'
          reason: 'e2e-tests'
          service: '<service>'
        }
      }
      {
        location: '<location>'
        name: 'rg-prjE2eT3st-prd-weu'
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
    "resourceGroups": {
      "value": [
        {
          "location": "<location>",
          "name": "rg-prjE2eT3st-dev-weu",
          "tags": {
            "public": "false",
            "reason": "e2e-tests",
            "service": "<service>"
          }
        },
        {
          "location": "<location>",
          "name": "rg-prjE2eT3st-prd-weu",
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
using 'iac/ptn/resources/resource-group/main.bicep'

param resourceGroups = [
  {
    location: '<location>'
    name: 'rg-prjE2eT3st-dev-weu'
    tags: {
      public: 'false'
      reason: 'e2e-tests'
      service: '<service>'
    }
  }
  {
    location: '<location>'
    name: 'rg-prjE2eT3st-prd-weu'
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

### Example 2: _Defaults only_

This instance deploys the module with the minimum set of required parameters.


<details>

<summary>via Bicep module</summary>

```bicep
module resourceGroup 'iac/ptn/resources/resource-group/main.bicep' = {
  name: 'resourceGroupDeployment'
  params: {
    resourceGroups: [
      {
        location: '<location>'
        name: 'rg-prjE2eT3st-dev-weu'
      }
      {
        location: '<location>'
        name: 'rg-prjE2eT3st-prd-weu'
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
    "resourceGroups": {
      "value": [
        {
          "location": "<location>",
          "name": "rg-prjE2eT3st-dev-weu"
        },
        {
          "location": "<location>",
          "name": "rg-prjE2eT3st-prd-weu"
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
using 'iac/ptn/resources/resource-group/main.bicep'

param resourceGroups = [
  {
    location: '<location>'
    name: 'rg-prjE2eT3st-dev-weu'
  }
  {
    location: '<location>'
    name: 'rg-prjE2eT3st-prd-weu'
  }
]
```

</details>
<p>

## Parameters

**Required parameters**

| Parameter | Type | Description |
| :-- | :-- | :-- |
| [`resourceGroups`](#parameter-resourcegroups) | array | The list of governance resource groups to create resource groups for. |

### Parameter: `resourceGroups`

The list of governance resource groups to create resource groups for.

- Required: Yes
- Type: array

**Required parameters**

| Parameter | Type | Description |
| :-- | :-- | :-- |
| [`name`](#parameter-resourcegroupsname) | string | The unique name of the resource group. |

**Optional parameters**

| Parameter | Type | Description |
| :-- | :-- | :-- |
| [`environmentType`](#parameter-resourcegroupsenvironmenttype) | string | The environment type of the resource group. |
| [`location`](#parameter-resourcegroupslocation) | string | The location of the resource group. |
| [`tags`](#parameter-resourcegroupstags) | object | The tags of the resource group used as metadata. |

### Parameter: `resourceGroups.name`

The unique name of the resource group.

- Required: Yes
- Type: string

### Parameter: `resourceGroups.environmentType`

The environment type of the resource group.

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

### Parameter: `resourceGroups.location`

The location of the resource group.

- Required: No
- Type: string

### Parameter: `resourceGroups.tags`

The tags of the resource group used as metadata.

- Required: No
- Type: object

## Outputs

| Output | Type | Description |
| :-- | :-- | :-- |
| `resourceGroups` | array | The list of resource groups created. |

## Cross-referenced modules

This section gives you an overview of all local-referenced module files (i.e., other modules that are referenced in this module) and all remote-referenced files (i.e., Bicep modules that are referenced from a Bicep Registry or Template Specs).

| Reference | Type |
| :-- | :-- |
| `br/public:avm/res/resources/resource-group:0.4.1` | Remote reference |
