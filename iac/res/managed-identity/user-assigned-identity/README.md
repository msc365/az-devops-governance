<!-- markdownlint-disable -->
<!-- omit from toc -->
# Managed Service Identity `[ManagedIdentity/userAssignedIdentity]`

This module deploys a managed service identity for end-to-end governance.

## Navigation

<!-- no toc -->
- [Resource Types](#resource-types)
- [Parameters](#parameters)
- [Outputs](#outputs)

## Resource Types

| Resource Type | API Version |
| :-- | :-- |
| `Microsoft.ManagedIdentity/userAssignedIdentities` | [2025-01-31-preview](https://learn.microsoft.com/en-us/azure/templates/Microsoft.ManagedIdentity/2025-01-31-preview/userAssignedIdentities) |

## Parameters

**Required parameters**

| Parameter | Type | Description |
| :-- | :-- | :-- |
| [`developmentManagedIdentityName`](#parameter-developmentmanagedidentityname) | string | The name of the managed identity to create for the development environment. |
| [`developmentResourceGroupName`](#parameter-developmentresourcegroupname) | string | The name of the development resource group. |
| [`productionManagedIdentityName`](#parameter-productionmanagedidentityname) | string | The name of the managed identity to create for the production environment. |
| [`productionResourceGroupName`](#parameter-productionresourcegroupname) | string | The name of the production resource group. |

**Optional parameters**

| Parameter | Type | Description |
| :-- | :-- | :-- |
| [`location`](#parameter-location) | string | The Azure location to deploy the managed identity to. |
| [`serviceShort`](#parameter-serviceshort) | string | Tags to apply to the managed identity. |

### Parameter: `developmentManagedIdentityName`

The name of the managed identity to create for the development environment.

- Required: Yes
- Type: string

### Parameter: `developmentResourceGroupName`

The name of the development resource group.

- Required: Yes
- Type: string

### Parameter: `productionManagedIdentityName`

The name of the managed identity to create for the production environment.

- Required: Yes
- Type: string

### Parameter: `productionResourceGroupName`

The name of the production resource group.

- Required: Yes
- Type: string

### Parameter: `location`

The Azure location to deploy the managed identity to.

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
| `managedIdentityDevelopment` | object | The managed identity created for the development environment. |
| `managedIdentityProduction` | object | The managed identity created for the production environment. |
