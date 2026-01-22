<!-- markdownlint-disable no-duplicate-heading -->
<!-- omit from toc -->
# Service Connection `[res\service-connection\main.ps1]`

![Version](https://img.shields.io/badge/script%20version-0.1.0-blue) [![License](https://img.shields.io/badge/license-MIT-purple)](https://github.com/msc365/az-devops-governance/blob/main/LICENSE)

Deploys an Azure DevOps service connection.

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

This script deploys an Azure DevOps service connection for a managed identity, including the creation of a federated identity credential.

## PARAMETERS

| Parameter | Type | Required | Default | Description |
| :-- | :-- | :-- | :-- | :-- |
| `ManagedIdentity` | `Object` | Yes | - | Required. An object containing details of the Managed Identity to be used. The object should contain: `name`, `resourceGroupName`, `subscriptionId`, and `federatedIdentityCredential` (an object with the `name` property). See [Example 4](#example-4) for more information. |
| `Name` | `String` | Yes | - | Required. The name of the service connection to be created. |
| `CollectionUri` | `String` | No | `$env:DefaultAdoCollectionUri` | Optional. The collection URI of the Azure DevOps collection/organization, e.g.: `https://dev.azure.com/my-org`, `https://vssps.dev.azure.com/my-org`. |
| `Description` | `String` | No | - | Optional. A description for the service connection. |
| `ProjectName` | `String` | No | `$env:DefaultAdoProjectName` | Optional. The Azure DevOps project ID or Name where the service connection will be created. |
| `Rollback` | `Switch` | No | - | Optional. Switch to indicate if the operation should rollback (remove) the service connection and related resources. <br> ⚠️ WARNING: Use with caution! Removing a service connection is irreversible and may affect teams relying on it. |

## EXAMPLES

### Example 1

#### PowerShell

```powershell
$deploySplat = @{
    TemplateFile          = 'main.ps1'
    TemplateParameterFile = 'params/main.parameters.json'
}

.\deploy.ps1 @deploySplat -Verbose
```

Deploys the service connection using the specified template and parameters.

### Example 2

#### PowerShell

```powershell
$customSplat = @{
    TemplateFile          = 'main.ps1'
    TemplateParameterFile = 'params\custom.parameters.json'
}

.\deploy.ps1 @customSplat -Verbose
```

Deploys the service connection using the specified template and custom parameters.

### Example 3

#### PowerShell

```powershell
$rollbackSplat = @{
    TemplateFile          = 'main.ps1'
    TemplateParameterFile = 'params/main.parameters.json'
}

.\deploy.ps1 @rollbackSplat -Rollback -Force -Verbose
```

Rolls back (deletes) the service connection and related resources without confirmation.

### Example 4

#### PowerShell

```powershell
$paramSplat = @{
    CollectionUri          = 'https://dev.azure.com/e2egov-org'
    ProjectName            = 'e2egov-prjHb72x9'
    Name                   = 'rg-e2egov-prjHb72x9-tst-weu'
    Description            = 'Service Connection for e2egov-prjHb72x9 testing in West Europe'
    ManagedIdentity = @{
        Name                         = 'id-e2egov-prjHb72x9-tst'
        ResourceGroupName            = 'rg-e2egov-prjHb72x9-tst-weu'
        SubscriptionId               = '00000000-0000-0000-0000-000000000000'
        FederatedIdentityCredential  = @{
            Name = 'fic-e2egov-prjHb72x9-tst'
        }
    }
}

.\main.ps1 @paramSplat -Verbose
```

Deploys a service connection using the specified parameters in code.

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
- `Az.ManagedServiceIdentity`
- `Az.Resources`
- `Azure.DevOps.PSModule`

## RESOURCES

- [deploy](deploy.ps1)

### Tests

- [default](tests/e2e/default)
- [rollback](tests/e2e/rollback)


## NOTES

- Operations are idempotent (safe to run multiple times).
- Ensure you are logged in to Azure using Connect-AzAccount before running this script.
- User confirmation is required for deletion unless `-Force` is specified.
