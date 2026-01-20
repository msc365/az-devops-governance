<!-- markdownlint-disable -->
<!-- omit from toc -->
# Common interface types for custom modules `[Types/customTypes]`

This module provides you with all common variants for custom interfaces to be used in modules.

## Navigation

<!-- no toc -->
- [Resource Types](#resource-types)
- [Usage examples](#usage-examples)
- [Parameters](#parameters)
- [Outputs](#outputs)

## Resource Types

_None_

## Usage examples

The following section provides usage examples for the module, which were used to validate and deploy the module successfully. For a full reference, please review the module's test folder in its repository.

> **Note** <br>
> Each example lists all the required parameters first, followed by the rest - each in alphabetical order.

> **Note** <br>
> To reference the module, please use the following syntax `iac/utl/types/custom-types/main.bicep`.

- [Import all types](#example-1-import-all-types)

### Example 1: _Import all types_

This example imports all available types of the given module.

Note: In your module you would import only the types you need.



<details>

<summary>via Bicep module</summary>

```bicep
metadata name = 'Import all types'
metadata description = '''
This example imports all available types of the given module.

Note: In your module you would import only the types you need.
'''
metadata owner = 'platform-engineers'

// -------------- //
// TEST EXECUTION //
// -------------- //

import {
  governanceIdentityType
  governanceSecurityGroupType
  governanceResourceGroupType
} from '../../../main.bicep'

param governanceIdentities governanceIdentityType[] = [
  {
    name: 'dev-identity'
    resourceGroup: 'dev-rg'
    location: 'eastus'
    tags: {
      project: 'governance'
    }
    environmentType: 'dev'
  }
  {
    name: 'prd-identity'
    resourceGroup: 'prd-rg'
    location: 'eastus2'
    tags: {
      project: 'governance'
    }
    environmentType: 'prd'
  }
]

output governanceIdentitiesOutput governanceIdentityType[] = governanceIdentities

param governanceSecurityGroups governanceSecurityGroupType[] = [
  {
    displayName: 'Dev Security Group'
    uniqueName: 'dev-sec-group'
    mailNickname: 'devsecgroup'
    description: 'Security group for development team'
    environmentType: 'dev'
  }
  {
    displayName: 'Prod Security Group'
    uniqueName: 'prd-sec-group'
    mailNickname: 'prdsecgroup'
    description: 'Security group for production team'
    environmentType: 'prd'
  }
]

output governanceSecurityGroupsOutput governanceSecurityGroupType[] = governanceSecurityGroups

param governanceResourceGroups governanceResourceGroupType[] = [
  {
    name: 'dev-rg'
    location: 'eastus'
    tags: {
      project: 'governance'
    }
    environmentType: 'dev'
  }
  {
    name: 'prd-rg'
    location: 'eastus2'
    tags: {
      project: 'governance'
    }
    environmentType: 'prd'
  }
]

output governanceResourceGroupsOutput governanceResourceGroupType[] = governanceResourceGroups
```

</details>
<p>

## Parameters

_None_

## Outputs

_None_
