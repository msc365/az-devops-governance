<!-- markdownlint-disable -->
<!-- omit from toc -->
# Role assignments at Subscription scope `[Authorization/roleAssignment/subScope]`

This module deploys role assignments at the subscription scope used for end-to-end governance.

## Navigation

<!-- no toc -->
- [Resource Types](#resource-types)
- [Parameters](#parameters)
- [Outputs](#outputs)
- [Cross-referenced modules](#cross-referenced-modules)

## Resource Types

| Resource Type | API Version |
| :-- | :-- |
| `Microsoft.Authorization/roleAssignments` | [2022-04-01](https://learn.microsoft.com/en-us/azure/templates/Microsoft.Authorization/2022-04-01/roleAssignments) |

## Parameters

**Required parameters**

| Parameter | Type | Description |
| :-- | :-- | :-- |
| [`administratorGroupUniqueName`](#parameter-administratorgroupuniquename) | string | The unique name of the administrators security group. |
| [`customRoleDefinitionId`](#parameter-customroledefinitionid) | string | The ID of the custom `Headless Owner (DevOps CI/CD)` role definition to assign. |
| [`developerGroupUniqueName`](#parameter-developergroupuniquename) | string | The unique name of the developers security group. |
| [`developmentManagedIdentityName`](#parameter-developmentmanagedidentityname) | string | The name of the managed identity to use as the owner of the development resource groups. |
| [`developmentResourceGroupName`](#parameter-developmentresourcegroupname) | string | The name of the development resource group. |
| [`developmentSubscriptionId`](#parameter-developmentsubscriptionid) | string | The subscription ID of the development subscription. |
| [`productionManagedIdentityName`](#parameter-productionmanagedidentityname) | string | The name of the managed identity to use as the owner of the production resource groups. |
| [`productionResourceGroupName`](#parameter-productionresourcegroupname) | string | The name of the production resource group. |
| [`productionSubscriptionId`](#parameter-productionsubscriptionid) | string | The subscription ID of the production subscription. |
| [`stakeholderGroupUniqueName`](#parameter-stakeholdergroupuniquename) | string | The unique name of the stakeholders security group. |

### Parameter: `administratorGroupUniqueName`

The unique name of the administrators security group.

- Required: Yes
- Type: string

### Parameter: `customRoleDefinitionId`

The ID of the custom `Headless Owner (DevOps CI/CD)` role definition to assign.

- Required: Yes
- Type: string

### Parameter: `developerGroupUniqueName`

The unique name of the developers security group.

- Required: Yes
- Type: string

### Parameter: `developmentManagedIdentityName`

The name of the managed identity to use as the owner of the development resource groups.

- Required: Yes
- Type: string

### Parameter: `developmentResourceGroupName`

The name of the development resource group.

- Required: Yes
- Type: string

### Parameter: `developmentSubscriptionId`

The subscription ID of the development subscription.

- Required: Yes
- Type: string

### Parameter: `productionManagedIdentityName`

The name of the managed identity to use as the owner of the production resource groups.

- Required: Yes
- Type: string

### Parameter: `productionResourceGroupName`

The name of the production resource group.

- Required: Yes
- Type: string

### Parameter: `productionSubscriptionId`

The subscription ID of the production subscription.

- Required: Yes
- Type: string

### Parameter: `stakeholderGroupUniqueName`

The unique name of the stakeholders security group.

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
