<!-- markdownlint-disable -->
<!-- omit from toc -->
# Role assignments at subscription scope `[Authorization/roleAssignment/subScope]`

This module deploys role assignments at the subscription scope used for end-to-end governance.

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
| `Microsoft.Authorization/roleAssignments` | [2022-04-01](https://learn.microsoft.com/en-us/azure/templates/Microsoft.Authorization/2022-04-01/roleAssignments) |

## Usage examples

The following section provides usage examples for the module, which were used to validate and deploy the module successfully. For a full reference, please review the module's test folder in its repository.

> **Note** <br>
> Each example lists all the required parameters first, followed by the rest - each in alphabetical order.

> **Note** <br>
> To reference the module, please use the following syntax `iac/ptn/authorization/role-assignment/sub-scope/main.bicep`.

- [Defaults only](#example-1-defaults-only)

### Example 1: _Defaults only_

This instance deploys the module with default parameters.


<details>

<summary>via Bicep module</summary>

```bicep
module roleAssignment 'iac/ptn/authorization/role-assignment/sub-scope/main.bicep' = {
  name: 'roleAssignmentDeployment'
  params: {
    // Required parameters
    customRoleDefinitionId: '8e3af657-a8ff-443c-a75c-2fe8c4bcb635'
    managedIdentities: {
      development: '<development>'
      production: '<production>'
    }
    resourceGroups: {
      development: '<development>'
      production: '<production>'
    }
    securityGroups: {
      administrators: '<administrators>'
      developers: '<developers>'
      stakeholders: '<stakeholders>'
    }
    subscriptions: {
      development: '<development>'
      production: '<production>'
    }
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
    // Required parameters
    "customRoleDefinitionId": {
      "value": "8e3af657-a8ff-443c-a75c-2fe8c4bcb635"
    },
    "managedIdentities": {
      "value": {
        "development": "<development>",
        "production": "<production>"
      }
    },
    "resourceGroups": {
      "value": {
        "development": "<development>",
        "production": "<production>"
      }
    },
    "securityGroups": {
      "value": {
        "administrators": "<administrators>",
        "developers": "<developers>",
        "stakeholders": "<stakeholders>"
      }
    },
    "subscriptions": {
      "value": {
        "development": "<development>",
        "production": "<production>"
      }
    }
  }
}
```

</details>
<p>

<details>

<summary>via Bicep parameters file</summary>

```bicep-params
using 'iac/ptn/authorization/role-assignment/sub-scope/main.bicep'

// Required parameters
param customRoleDefinitionId = '8e3af657-a8ff-443c-a75c-2fe8c4bcb635'
param managedIdentities = {
  development: '<development>'
  production: '<production>'
}
param resourceGroups = {
  development: '<development>'
  production: '<production>'
}
param securityGroups = {
  administrators: '<administrators>'
  developers: '<developers>'
  stakeholders: '<stakeholders>'
}
param subscriptions = {
  development: '<development>'
  production: '<production>'
}
```

</details>
<p>

## Parameters

**Required parameters**

| Parameter | Type | Description |
| :-- | :-- | :-- |
| [`customRoleDefinitionId`](#parameter-customroledefinitionid) | string | The ID of the custom `Headless Owner (DevOps CI/CD)` role definition to assign. |
| [`managedIdentities`](#parameter-managedidentities) | object | Managed identities type containing development and production managed identity configurations. |
| [`resourceGroups`](#parameter-resourcegroups) | object | Resource groups type containing development and production resource group configurations. |
| [`securityGroups`](#parameter-securitygroups) | object | Security groups type containing administrator, developer, and stakeholder group configurations. |
| [`subscriptions`](#parameter-subscriptions) | object | Subscriptions type containing development and production subscription configurations. |

### Parameter: `customRoleDefinitionId`

The ID of the custom `Headless Owner (DevOps CI/CD)` role definition to assign.

- Required: Yes
- Type: string

### Parameter: `managedIdentities`

Managed identities type containing development and production managed identity configurations.

- Required: Yes
- Type: object

**Required parameters**

| Parameter | Type | Description |
| :-- | :-- | :-- |
| [`development`](#parameter-managedidentitiesdevelopment) | object | The development managed identity configuration. |
| [`production`](#parameter-managedidentitiesproduction) | object | The production managed identity configuration. |

### Parameter: `managedIdentities.development`

The development managed identity configuration.

- Required: Yes
- Type: object

**Required parameters**

| Parameter | Type | Description |
| :-- | :-- | :-- |
| [`name`](#parameter-managedidentitiesdevelopmentname) | string | The name of the development managed identity. |

### Parameter: `managedIdentities.development.name`

The name of the development managed identity.

- Required: Yes
- Type: string

### Parameter: `managedIdentities.production`

The production managed identity configuration.

- Required: Yes
- Type: object

**Required parameters**

| Parameter | Type | Description |
| :-- | :-- | :-- |
| [`name`](#parameter-managedidentitiesproductionname) | string | The name of the production managed identity. |

### Parameter: `managedIdentities.production.name`

The name of the production managed identity.

- Required: Yes
- Type: string

### Parameter: `resourceGroups`

Resource groups type containing development and production resource group configurations.

- Required: Yes
- Type: object

**Required parameters**

| Parameter | Type | Description |
| :-- | :-- | :-- |
| [`development`](#parameter-resourcegroupsdevelopment) | object | The development resource group configuration. |
| [`production`](#parameter-resourcegroupsproduction) | object | The production resource group configuration. |

### Parameter: `resourceGroups.development`

The development resource group configuration.

- Required: Yes
- Type: object

**Required parameters**

| Parameter | Type | Description |
| :-- | :-- | :-- |
| [`name`](#parameter-resourcegroupsdevelopmentname) | string | The name of the development resource group. |

### Parameter: `resourceGroups.development.name`

The name of the development resource group.

- Required: Yes
- Type: string

### Parameter: `resourceGroups.production`

The production resource group configuration.

- Required: Yes
- Type: object

**Required parameters**

| Parameter | Type | Description |
| :-- | :-- | :-- |
| [`name`](#parameter-resourcegroupsproductionname) | string | The name of the production resource group. |

### Parameter: `resourceGroups.production.name`

The name of the production resource group.

- Required: Yes
- Type: string

### Parameter: `securityGroups`

Security groups type containing administrator, developer, and stakeholder group configurations.

- Required: Yes
- Type: object

**Required parameters**

| Parameter | Type | Description |
| :-- | :-- | :-- |
| [`administrators`](#parameter-securitygroupsadministrators) | object | The administrators security group configuration. |
| [`developers`](#parameter-securitygroupsdevelopers) | object | The developers security group configuration. |
| [`stakeholders`](#parameter-securitygroupsstakeholders) | object | The stakeholders security group configuration. |

### Parameter: `securityGroups.administrators`

The administrators security group configuration.

- Required: Yes
- Type: object

**Required parameters**

| Parameter | Type | Description |
| :-- | :-- | :-- |
| [`name`](#parameter-securitygroupsadministratorsname) | string | The unique name of the administrators security group. |

### Parameter: `securityGroups.administrators.name`

The unique name of the administrators security group.

- Required: Yes
- Type: string

### Parameter: `securityGroups.developers`

The developers security group configuration.

- Required: Yes
- Type: object

**Required parameters**

| Parameter | Type | Description |
| :-- | :-- | :-- |
| [`name`](#parameter-securitygroupsdevelopersname) | string | The unique name of the developers security group. |

### Parameter: `securityGroups.developers.name`

The unique name of the developers security group.

- Required: Yes
- Type: string

### Parameter: `securityGroups.stakeholders`

The stakeholders security group configuration.

- Required: Yes
- Type: object

**Required parameters**

| Parameter | Type | Description |
| :-- | :-- | :-- |
| [`name`](#parameter-securitygroupsstakeholdersname) | string | The unique name of the stakeholders security group. |

### Parameter: `securityGroups.stakeholders.name`

The unique name of the stakeholders security group.

- Required: Yes
- Type: string

### Parameter: `subscriptions`

Subscriptions type containing development and production subscription configurations.

- Required: Yes
- Type: object

**Required parameters**

| Parameter | Type | Description |
| :-- | :-- | :-- |
| [`development`](#parameter-subscriptionsdevelopment) | object | The development subscription configuration. |
| [`production`](#parameter-subscriptionsproduction) | object | The production subscription configuration. |

### Parameter: `subscriptions.development`

The development subscription configuration.

- Required: Yes
- Type: object

**Required parameters**

| Parameter | Type | Description |
| :-- | :-- | :-- |
| [`id`](#parameter-subscriptionsdevelopmentid) | string | The ID of the development subscription. |

### Parameter: `subscriptions.development.id`

The ID of the development subscription.

- Required: Yes
- Type: string

### Parameter: `subscriptions.production`

The production subscription configuration.

- Required: Yes
- Type: object

**Required parameters**

| Parameter | Type | Description |
| :-- | :-- | :-- |
| [`id`](#parameter-subscriptionsproductionid) | string | The ID of the production subscription. |

### Parameter: `subscriptions.production.id`

The ID of the production subscription.

- Required: Yes
- Type: string

## Outputs

| Output | Type |
| :-- | :-- |
| `developmentRoleAssignmentResourceIds` | object |
| `productionRoleAssignmentResourceIds` | object |

## Cross-referenced modules

This section gives you an overview of all local-referenced module files (i.e., other modules that are referenced in this module) and all remote-referenced files (i.e., Bicep modules that are referenced from a Bicep Registry or Template Specs).

| Reference | Type |
| :-- | :-- |
| `br/public:avm/res/authorization/role-assignment/sub-scope:0.1.1` | Remote reference |
