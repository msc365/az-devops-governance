<!-- markdownlint-disable -->
<!-- omit from toc -->
# Entra ID security groups `[Graph/group]`

This module deploys Entra security groups used for end-to-end governance.

## Navigation

<!-- no toc -->
- [Resource Types](#resource-types)
- [Usage examples](#usage-examples)
- [Parameters](#parameters)
- [Outputs](#outputs)

## Resource Types

| Resource Type | API Version |
| :-- | :-- |
| `Microsoft.Graph/groups@v1.0` | [](https://learn.microsoft.com/en-us/azure/templates) |

## Usage examples

The following section provides usage examples for the module, which were used to validate and deploy the module successfully. For a full reference, please review the module's test folder in its repository.

> **Note** <br>
> Each example lists all the required parameters first, followed by the rest - each in alphabetical order.

> **Note** <br>
> To reference the module, please use the following syntax `iac/ptn/graph/group/main.bicep`.

- [Using all](#example-1-using-all)
- [Default only](#example-2-default-only)

### Example 1: _Using all_

This instance deploys the module with all parameters.


<details>

<summary>via Bicep module</summary>

```bicep
module group 'iac/ptn/graph/group/main.bicep' = {
  name: 'groupDeployment'
  params: {
    securityGroups: [
      {
        description: 'Administrators group for E2eT3st project.'
        displayName: 'SG prjE2eT3st Administrators'
        mailNickname: 'prjE2eT3st-admins'
        uniqueName: 'prjE2eT3st-admins'
      }
      {
        description: 'Developers group for E2eT3st project.'
        displayName: 'SG prjE2eT3st Developers'
        mailNickname: 'prjE2eT3st-devs'
        uniqueName: 'prjE2eT3st-devs'
      }
      {
        description: 'Stakeholders group for E2eT3st project.'
        displayName: 'SG prjE2eT3st Stakeholders'
        mailNickname: 'prjE2eT3st-stakes'
        uniqueName: 'prjE2eT3st-stakes'
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
    "securityGroups": {
      "value": [
        {
          "description": "Administrators group for E2eT3st project.",
          "displayName": "SG prjE2eT3st Administrators",
          "mailNickname": "prjE2eT3st-admins",
          "uniqueName": "prjE2eT3st-admins"
        },
        {
          "description": "Developers group for E2eT3st project.",
          "displayName": "SG prjE2eT3st Developers",
          "mailNickname": "prjE2eT3st-devs",
          "uniqueName": "prjE2eT3st-devs"
        },
        {
          "description": "Stakeholders group for E2eT3st project.",
          "displayName": "SG prjE2eT3st Stakeholders",
          "mailNickname": "prjE2eT3st-stakes",
          "uniqueName": "prjE2eT3st-stakes"
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
using 'iac/ptn/graph/group/main.bicep'

param securityGroups = [
  {
    description: 'Administrators group for E2eT3st project.'
    displayName: 'SG prjE2eT3st Administrators'
    mailNickname: 'prjE2eT3st-admins'
    uniqueName: 'prjE2eT3st-admins'
  }
  {
    description: 'Developers group for E2eT3st project.'
    displayName: 'SG prjE2eT3st Developers'
    mailNickname: 'prjE2eT3st-devs'
    uniqueName: 'prjE2eT3st-devs'
  }
  {
    description: 'Stakeholders group for E2eT3st project.'
    displayName: 'SG prjE2eT3st Stakeholders'
    mailNickname: 'prjE2eT3st-stakes'
    uniqueName: 'prjE2eT3st-stakes'
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
module group 'iac/ptn/graph/group/main.bicep' = {
  name: 'groupDeployment'
  params: {
    securityGroups: [
      {
        displayName: 'SG prjE2eT3st Administrators'
        mailNickname: 'prjE2eT3st-admins'
        uniqueName: 'prjE2eT3st-admins'
      }
      {
        displayName: 'SG prjE2eT3st Developers'
        mailNickname: 'prjE2eT3st-devs'
        uniqueName: 'prjE2eT3st-devs'
      }
      {
        displayName: 'SG prjE2eT3st Stakeholders'
        mailNickname: 'prjE2eT3st-stakes'
        uniqueName: 'prjE2eT3st-stakes'
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
    "securityGroups": {
      "value": [
        {
          "displayName": "SG prjE2eT3st Administrators",
          "mailNickname": "prjE2eT3st-admins",
          "uniqueName": "prjE2eT3st-admins"
        },
        {
          "displayName": "SG prjE2eT3st Developers",
          "mailNickname": "prjE2eT3st-devs",
          "uniqueName": "prjE2eT3st-devs"
        },
        {
          "displayName": "SG prjE2eT3st Stakeholders",
          "mailNickname": "prjE2eT3st-stakes",
          "uniqueName": "prjE2eT3st-stakes"
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
using 'iac/ptn/graph/group/main.bicep'

param securityGroups = [
  {
    displayName: 'SG prjE2eT3st Administrators'
    mailNickname: 'prjE2eT3st-admins'
    uniqueName: 'prjE2eT3st-admins'
  }
  {
    displayName: 'SG prjE2eT3st Developers'
    mailNickname: 'prjE2eT3st-devs'
    uniqueName: 'prjE2eT3st-devs'
  }
  {
    displayName: 'SG prjE2eT3st Stakeholders'
    mailNickname: 'prjE2eT3st-stakes'
    uniqueName: 'prjE2eT3st-stakes'
  }
]
```

</details>
<p>

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
