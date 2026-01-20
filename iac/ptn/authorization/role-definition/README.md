<!-- markdownlint-disable -->
<!-- omit from toc -->
# Role Definition Headless Owner (DevOps CI/CD) `[Authorization/roleDefinition]`

This module deploys a Role definition at a Management group scope.

## Navigation

<!-- no toc -->
- [Resource Types](#resource-types)
- [Parameters](#parameters)
- [Outputs](#outputs)
- [Cross-referenced modules](#cross-referenced-modules)

## Resource Types

| Resource Type | API Version |
| :-- | :-- |
| `Microsoft.Authorization/roleDefinitions` | [2022-05-01-preview](https://learn.microsoft.com/en-us/azure/templates/Microsoft.Authorization/2022-05-01-preview/roleDefinitions) |

## Parameters

**Required parameters**

| Parameter | Type | Description |
| :-- | :-- | :-- |
| [`assignableScopes`](#parameter-assignablescopes) | array | The assignable scopes of the custom role definition. If not specified, the management group being targeted in the parameter managementGroupName will be used. |

### Parameter: `assignableScopes`

The assignable scopes of the custom role definition. If not specified, the management group being targeted in the parameter managementGroupName will be used.

- Required: Yes
- Type: array

## Outputs

| Output | Type | Description |
| :-- | :-- | :-- |
| `resourceId` | string | The resource ID of the role definition. |

## Cross-referenced modules

This section gives you an overview of all local-referenced module files (i.e., other modules that are referenced in this module) and all remote-referenced files (i.e., Bicep modules that are referenced from a Bicep Registry or Template Specs).

| Reference | Type |
| :-- | :-- |
| `br/public:avm/ptn/authorization/role-definition:0.1.1` | Remote reference |
