<!-- markdownlint-disable -->
<!-- omit from toc -->
# Entra ID security groups `[Graph/group]`

This module deploys Entra security groups used for end-to-end governance.

## Navigation

<!-- no toc -->
- [Resource Types](#resource-types)
- [Parameters](#parameters)
- [Outputs](#outputs)

## Resource Types

| Resource Type | API Version |
| :-- | :-- |
| `Microsoft.Graph/groups@v1.0` | [](https://learn.microsoft.com/en-us/azure/templates) |

## Parameters

**Required parameters**

| Parameter | Type | Description |
| :-- | :-- | :-- |
| [`securityGroups`](#parameter-securitygroups) | array | The list of Entra security groups to create. |

### Parameter: `securityGroups`

The list of Entra security groups to create.

- Required: Yes
- Type: array

**Required parameters**

| Parameter | Type | Description |
| :-- | :-- | :-- |
| [`displayName`](#parameter-securitygroupsdisplayname) | string | The display name of the security group. |
| [`mailNickname`](#parameter-securitygroupsmailnickname) | string | The mail nickname of the security group. |
| [`uniqueName`](#parameter-securitygroupsuniquename) | string | The unique name of the security group. |

**Optional parameters**

| Parameter | Type | Description |
| :-- | :-- | :-- |
| [`description`](#parameter-securitygroupsdescription) | string | The description of the security group. |
| [`environmentType`](#parameter-securitygroupsenvironmenttype) | string | The environment type of the security group. |

### Parameter: `securityGroups.displayName`

The display name of the security group.

- Required: Yes
- Type: string

### Parameter: `securityGroups.mailNickname`

The mail nickname of the security group.

- Required: Yes
- Type: string

### Parameter: `securityGroups.uniqueName`

The unique name of the security group.

- Required: Yes
- Type: string

### Parameter: `securityGroups.description`

The description of the security group.

- Required: No
- Type: string

### Parameter: `securityGroups.environmentType`

The environment type of the security group.

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

## Outputs

| Output | Type | Description |
| :-- | :-- | :-- |
| `securityGroups` | array | The list of created Entra security groups. |
