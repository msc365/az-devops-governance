<!-- markdownlint-disable -->
<!-- omit from toc -->
# Resource group `[Resources/resourceGroup]`

This module deploys a resource group used for end-to-end governance.

## Navigation

<!-- no toc -->
- [Resource Types](#resource-types)
- [Parameters](#parameters)
- [Outputs](#outputs)
- [Cross-referenced modules](#cross-referenced-modules)

## Resource Types

| Resource Type | API Version |
| :-- | :-- |
| `Microsoft.Authorization/locks` | [2020-05-01](https://learn.microsoft.com/en-us/azure/templates/Microsoft.Authorization/2020-05-01/locks) |
| `Microsoft.Authorization/roleAssignments` | [2022-04-01](https://learn.microsoft.com/en-us/azure/templates/Microsoft.Authorization/2022-04-01/roleAssignments) |
| `Microsoft.Resources/resourceGroups` | [2021-04-01](https://learn.microsoft.com/en-us/azure/templates/Microsoft.Resources/2021-04-01/resourceGroups) |

## Parameters

**Required parameters**

| Parameter | Type | Description |
| :-- | :-- | :-- |
| [`developmentResourceGroupName`](#parameter-developmentresourcegroupname) | string | The name of the development resource group. |
| [`productionResourceGroupName`](#parameter-productionresourcegroupname) | string | The name of the production resource group. |

**Optional parameters**

| Parameter | Type | Description |
| :-- | :-- | :-- |
| [`location`](#parameter-location) | string | The Azure location to deploy the resource groups to. |
| [`serviceShort`](#parameter-serviceshort) | string | Tags to apply to the managed identity. |

### Parameter: `developmentResourceGroupName`

The name of the development resource group.

- Required: Yes
- Type: string

### Parameter: `productionResourceGroupName`

The name of the production resource group.

- Required: Yes
- Type: string

### Parameter: `location`

The Azure location to deploy the resource groups to.

- Required: No
- Type: string
- Default: `[deployment().location]`

### Parameter: `serviceShort`

Tags to apply to the managed identity.

- Required: No
- Type: string
- Default: `'e2egov'`

## Outputs

| Output | Type | Description |
| :-- | :-- | :-- |
| `resourceGroupDevelopment` | object | The development resource group. |
| `resourceGroupProduction` | object | The production resource group. |

## Cross-referenced modules

This section gives you an overview of all local-referenced module files (i.e., other modules that are referenced in this module) and all remote-referenced files (i.e., Bicep modules that are referenced from a Bicep Registry or Template Specs).

| Reference | Type |
| :-- | :-- |
| `br/public:avm/res/resources/resource-group:0.4.1` | Remote reference |
