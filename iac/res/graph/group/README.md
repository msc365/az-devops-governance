<!-- markdownlint-disable -->
<!-- omit from toc -->
# Entra ID security groups `[Graph/group]`

This module deploys Entra groups used for end-to-end governance.

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
| [`groups`](#parameter-groups) | array | The list of Entra security groups to create. |

**Optional parameters**

| Parameter | Type | Description |
| :-- | :-- | :-- |
| [`customRoleDefinitionId`](#parameter-customroledefinitionid) | string | The ID of the custom `Headless Owner (DevOps CI/CD)` role definition to assign. |

### Parameter: `groups`

The list of Entra security groups to create.

- Required: Yes
- Type: array

### Parameter: `customRoleDefinitionId`

The ID of the custom `Headless Owner (DevOps CI/CD)` role definition to assign.

- Required: No
- Type: string
- Default: `''`

## Outputs

| Output | Type | Description |
| :-- | :-- | :-- |
| `groups` | array | The list of created Entra group IDs. |
