<!-- markdownlint-disable -->
<!-- omit from toc -->
# Managed identity `[ManagedIdentity/userAssignedIdentity]`

This module deploys user-assigned managed identities used for end-to-end governance.

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
