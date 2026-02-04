<!-- omit from toc -->
# Automating Azure DevOps with End-to-End Governance [`Bicep/PowerShell`]

[![GitHub release (latest)](https://img.shields.io/github/v/release/msc365/az-devops-governance?include_prereleases&logo=github)](https://github.com/msc365/az-devops-governance/releases) [![License](https://img.shields.io/badge/license-MIT-purple)](https://github.com/msc365/az-devops-governance/blob/main/LICENSE)

This repository demonstrates a complete **Azure governance model** using _Bicep templates_ and _PowerShell scripts_. It shows how to implement end-to-end governance from _Azure DevOps_ and CI/CD pipelines through to _Azure_ deployments, following enterprise-grade cloud architecture best practices.

While Terraform and Bicep excel at Azure infrastructure provisioning, they, _like the Azure DevOps REST API_, lack a cohesive approach for provisioning complete Azure DevOps projects with all necessary configurations. Simple tasks like creating a team require multiple sequential API calls to configure area paths, iteration paths, and group memberships separately. This repository solves these challenges with fully functional PowerShell scripts built on the [Azure.DevOps.PSModule](https://github.com/msc365/az-devops-psmodule), providing a streamlined, declarative approach to Azure DevOps resource management.

The implementation combines **Bicep templates** for Azure infrastructure and Microsoft Entra ID group management with **PowerShell scripts** for Azure DevOps automation. It adopts modern security practices including [workload identity federation](https://devblogs.microsoft.com/devops/workload-identity-federation-for-azure-deployments-is-now-generally-available/) for Azure Pipelines, replacing traditional service principals to improve security and manageability.

<!-- omit from toc -->
## Table of Contents

- [Key Features](#key-features)
- [Reference Scenario](#reference-scenario)
- [Deploy the Demo](#deploy-the-demo)
- [Support](#support)
- [License](#license)

## Key Features

- Practical guidance for implementing end-to-end governance at scale
- Template scripts and CI/CD pipelines for resource provisioning, and policy enforcement
- Secure authentication with workload identity federation

## Reference Scenario

For a deeper walkthrough of the reference scenario covering a fictional _European Building Materials_ organization with _OpCo_ use cases, branching model, architecture diagrams, RBAC mappings, and service connection safeguards see [Reference Scenario Walkthrough](docs/end-to-end-governance.md).

## Deploy the Demo

This implementation extends beyond Azure Resource Manager. This is why we use **Bicep templates** for _Azure infrastructure provisioning_ and _Microsoft Entra ID group management_, and use **PowerShell scripts** for _Azure DevOps resource provisioning_. This combination provides declarative infrastructure-as-code for Azure resources and identity while leveraging PowerShell's flexibility for DevOps operations in a declarative DSC like approach.

### Quick Start

Once you've completed the prerequisites and configuration, deploying is straightforward. See [Deploy this Demo](accelerator/demo/README.md) for detailed information about prerequisites, configuration and deploying the demo.

Here's a quick reference:

**PowerShell:**
```powershell
# Install required modules (one-time setup)
Install-Module -Name Az.Accounts -Scope CurrentUser
Install-Module -Name Az.Resources -Scope CurrentUser
Install-Module -Name Microsoft.Graph.Authentication -Scope CurrentUser
Install-Module -Name Azure.DevOps.PSModule -Scope CurrentUser

# Set environment variables for Bicep deployments
$env:LOCATION = 'westeurope'
$env:SUBSCRIPTION_ID = '00000000-0000-0000-0000-000000000000'
$env:CUSTOM_ROLE_DEFINITION_ID = '11111111-1111-1111-1111-111111111111'
$env:AZ_DEVOPS_GOVERNANCE_DEMO_MODE = 'true'

# Set global configuration
{
    "$schema": "../../../schemas/config.schema.json",
    "uniqueId": "2vk6",
    "prefix": "demo",
    "service": "e2egov",
    "location": "westeurope",
    "collectionUri": "https://dev.azure.com/your-org"
}

# Login to Azure (authenticates both Azure and Azure DevOps)
Connect-AzAccount
Set-AzContext -SubscriptionId $env:SUBSCRIPTION_ID

# Navigate to pipeline scripts directory
cd accelerator/demo/pipeline-scripts

# Stage 1 - Azure Infrastructure
./Deploy-ResourceGroups.ps1
./Deploy-ManagedIndentities.ps1
./Deploy-SecurityGroups.ps1
./Deploy-RoleAssignments.ps1

# Stage 2 - Azure DevOps
./Deploy-Projects.ps1
./Deploy-Teams.ps1
./Deploy-Memberships.ps1
./Deploy-Environments.ps1
./Deploy-ServiceConnections.ps1
```

## Support

This project uses GitHub Issues to track bugs and feature requests.
Please [search the existing issues](https://github.com/msc365/az-devops-governance/issues?q=is%3Aissue) before filing
new issues to avoid duplicates.

- For new issues, file your bug or feature request as a [new issue](https://github.com/msc365/az-devops-governance/issues/new/choose).
- For help and questions, please raise an issue or start a [new discussion](https://github.com/msc365/az-devops-governance/discussions).

## License

![logo small martin swinkels cloud](.assets/logo-small.png)  
Part of Martin's Cloud on GitHub

Copyright (c) 2025 MSc365.eu by Martin Swinkels

Portions of the documentation in this repository are adapted from Microsoft Corporation's
documentation and the article "End-to-end governance in Azure when using CI/CD" by Julie Ng
(Microsoft Corporation), used under the MIT License.

This project is published under the MIT license.  
See [MIT License](LICENSE) for details.

<!-- omit from toc -->
## Disclaimer

This repository is provided "**as is**" and is subject to **limited support**. While reasonable efforts
have been made to ensure its usefulness, there are **no warranties or guarantees** regarding accuracy,
reliability, security, or ongoing maintenance. By using this code, you acknowledge and agree that you
do so at your own risk. It is your responsibility to validate, test, and ensure suitability for your specific
use case, particularly in production environments. We welcome community contributions and feedback to improve
the project; however, official support will limited.

<!-- omit from toc -->
## Liability

Under no circumstances shall the authors, contributors, or affiliated organizations be held liable for
any direct, indirect, incidental, or consequential damages arising from the use of this repository, including
but not limited to loss of data, business interruption, or system failures.
Use of this code implies acceptance of these terms.

<!-- omit from toc -->
## Trademarks

This project may contain trademarks or logos for projects, products, or services. Authorized use of Microsoft
trademarks or logos is subject to and must follow
[Microsoft's Trademark & Brand Guidelines](https://www.microsoft.com/legal/intellectualproperty/trademarks/usage/general).
Use of Microsoft trademarks or logos in modified versions of this project must not cause confusion or imply Microsoft
sponsorship. Any use of third-party trademarks or logos are subject to those third-party's policies.
