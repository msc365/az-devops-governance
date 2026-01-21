<!-- omit from toc -->
# Understanding this Demo

## Azure DevOps Projects

The project demo structure illustrates different governance models and their trade-offs.
<!-- 
![e2egov-projects](.assets/e2egov-projects.png)  
<sub>Image: Azure DevOps organization created with scripts form this repo</sub>

- The isolated model with the `avengers` and `guardians` projects means less governance management - at the cost of less collaboration.
- The `fantastic-four` project prioritizes collaboration via multiple shared Azure Boards - but requires more governance management, especially for repositories and pipelines.

| Project | Boards | Repos | Pipelines | Description |
| :-- | :-- | :-- | :-- | :-- |
| `avengers` |  Yes | Yes | Yes | Isolated by project scope |
| `guardians` | Yes | Yes | Yes | Isolated by project scope |
| `galaxy` | No | Yes | Yes | Shared resources |
| `fantastic-four` | Yes | Yes | Yes | One project multiple teams, prioritizes collaboration |

## Entra ID Groups

The key to en-to-end governance is to have multiple role assignments (with different role definitions and different resource scopes to the same Entra ID Groups).

![e2egov-rbac](./.assets/e2egov-rbac.png)  
<sub>Image: Role Assignment diagram</sub> -->
