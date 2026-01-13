<!-- markdownlint-disable no-duplicate-heading -->
<!-- omit from toc -->
# Resource Group `[res\shared\resource-group\main.ps1]`

![Version](https://img.shields.io/badge/script%20version-0.1.0-blue) [![License](https://img.shields.io/badge/license-MIT-purple)](https://github.com/msc365/az-devops-governance/blob/main/LICENSE)

Create or update an Azure Resource Group.

<!-- omit from toc -->
## NAVIGATION

- [DESCRIPTION](#description)
- [PARAMETERS](#parameters)
- [EXAMPLES](#examples)
- [OUTPUTS](#outputs)
- [SUPPORT](#support)
- [DEPENDENCIES](#dependencies)
- [RESOURCES](#resources)
- [NOTES](#notes)

## DESCRIPTION

This script creates a new Azure Resource Group or updates an existing one with specified tags.

## PARAMETERS

| Parameter | Type | Required | Default | Description |
| :-- | :-- | :-- | :-- | :-- |
| `Location` | `String` | Yes | - | Required. The Azure region where the Resource Group will be created e.g.: 'westeurope', 'northeurope'. |
| `Name` | `String` | Yes | - | Required. The name of the Resource Group. |
| `Rollback` | `Switch` | No | - | Not implemented by design. See [Notes](#notes) for detailed information. |
| `SubscriptionId` | `String` | No | - | Optional. The Azure subscription ID where the resource group will be created. If not provided, the current context subscription will be used. |
| `Tags` | `Object` | No | - | Optional. A hashtable of tags to assign to the Resource Group. |

## EXAMPLES

### Example 1

#### PowerShell

```powershell
$rgParams = @{
    Name           = 'rg-e2egov-prjHb72x9-tst-weu'
    Location       = 'westeurope'
    SubscriptionId = '00000000-0000-0000-0000-000000000000'
    Tags           = @{
        'environment' = 'tst'
        'owner'       = 'e2egov'
    }
}
.\main.ps1 @rgParams
```

Creates or updates the resource group 'rg-e2egov-prjHb72x9-tst-weu' in the 'westeurope' region with the specified tags.
The resource group will be deployed in  current Azure subscription context.

## OUTPUTS

### `PSCustomObject`

## SUPPORT

### CommonParameters

This cmdlet supports the common parameters: `-Debug`, `-ErrorAction`, `-ErrorVariable`,  
`-InformationAction`, `-InformationVariable`, `-OutBuffer`, `-OutVariable`, `-PipelineVariable`,  
`-ProgressAction`, `-Verbose`, `-WarningAction`, and `-WarningVariable`.  
For more information, see [about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

### SupportsShouldProcess

This script supports the `-WhatIf` and `-Confirm` parameters for safe execution:

- **`-WhatIf`**: Shows what would happen if the script runs without actually making any changes.
- **`-Confirm`**: Prompts for confirmation before performing each action.

## DEPENDENCIES

This script requires the following PowerShell modules:

- `Az.Accounts`
- `Az.Resources`

## RESOURCES

- [deploy](deploy.ps1)

### Tests

- [all](tests/e2e/all)
- [default](tests/e2e/default)
- [rollback](tests/e2e/rollback)
- [update](tests/e2e/update)
- [unit](tests/unit)


## NOTES

- Operations are idempotent (safe to run multiple times).

> [!IMPORTANT]
> Rollback does not perform actual Resource group deletion. Resource groups may contain shared resources that are not part of this implementation but could be deployed by other systems or requirements over time. Deleting the Resource group could impact other services and operations relying on those resources.
