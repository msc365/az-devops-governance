<!-- omit from toc -->
# Azure DevOps Accelerator [`PowerShell`]

[![GitHub release (latest)](https://img.shields.io/github/v/release/msc365/az-devops-governance?include_prereleases&logo=github)](https://github.com/msc365/az-devops-governance/releases) [![License](https://img.shields.io/badge/license-MIT-purple)](https://github.com/msc365/az-devops-governance/blob/main/LICENSE)

<!-- markdownlint-disable-next-line MD001 -->
### Azure Governance from CI/CD Pipeline to Azure Resource Manager

This repository demonstrates a complete **Azure governance model** using _Bicep templates_ and _PowerShell scripts_. It shows how to implement end-to-end governance from _Azure DevOps_ CI/CD pipelines to _Azure_ deployments, following enterprise-grade cloud architecture best practices.

While `Terraform` and `Bicep` excel at Azure infrastructure provisioning, they, _like the Azure DevOps REST API_ and _Azure CLI_, lack a cohesive approach for provisioning complete Azure DevOps projects with all necessary configurations. Simple tasks like creating a team require multiple sequential API calls to configure area paths, iteration paths, and group memberships separately. This repository solves these challenges with fully functional PowerShell scripts built on the [Azure.DevOps.PSModule](https://github.com/msc365/az-devops-psmodule), providing a streamlined, declarative approach to Azure DevOps resource management.

The full implementation combines **Bicep templates** for Azure infrastructure and Microsoft Entra ID group management with **PowerShell scripts** for Azure DevOps automation. It adopts modern security practices including [workload identity federation](https://devblogs.microsoft.com/devops/workload-identity-federation-for-azure-deployments-is-now-generally-available/) for Azure Pipelines, replacing traditional service principals to improve security and manageability.

<!-- omit from toc -->
## Table of Contents

- [Key Features](#key-features)
- [Quick Start](#quick-start)
- [Governance](#governance)
- [Support](#support)
- [License](#license)

## Key Features

- Practical guidance for implementing end-to-end governance at scale
- Template scripts and CI/CD pipelines for resource provisioning, and policy enforcement
- Secure authentication with workload identity federation

## Quick Start

Use the [Project template](src/res/core/project) to provision Azure DevOps projects.

This script creates, updates or rolls back an Azure DevOps Project within a specified organization. It provides options to configure project properties such as description, default team, process template, source control type, visibility, and feature states.

1. Install the required modules:
   - `Az.Accounts`
   - `Azure.DevOps.PSModule`

2. Authenticate with `Connect-AzAccount`.  
   The scripts will reuse your Azure context to authenticate with Azure DevOps.

3. Copy or edit the sample [config file](config/main.config.json) and set global configuration:

    ```json
    {
        "$schema": "../../../schemas/config.schema.json",
        "uniqueId": "2vk6",
        "prefix": "demo",
        "service": "e2egov",
        "location": "westeurope",
        "collectionUri": "https://dev.azure.com/<your-org>"
    }
    ```
    Parameter files  can use placeholder like `{prefix}-{service}`. These placeholders will be replaced with values set in this global config file.

4. Copy or edit the sample [parameter file](src/res/core/project/params) to match your parameters:

    ```json
    {
      "$schema": "../../../../../schemas/project.schema.json",
      "collectionUri": "{collectionUri}",
      "projects": [
          {
              "name": "{prefix}-{service}",
              "description": "Default project description",
              "defaultTeam": "Default Team",
              "sourceControl": "Git",
              "process": "Agile",
              "features": {
                  "boards": "enabled",
                  "repos": "enabled",
                  "pipelines": "enabled",
                  "artifacts": "enabled",
                  "testPlans": "disabled"
              },
              "visibility": "Private"
          }
      ]
    }
    ```

5. Execute the `deploy.ps1` script:

    ```powershell
    cd src/res/core/project

    ./deploy.ps1 -Verbose -WhatIf
    ```

For ad-hoc runs, pass parameters inline as shown in [this sample](src/res/core/project/README.md#example-4). The script is idempotent, so rerunning it updates existing projects, and `-Rollback` safely removes them when needed.

## Governance

For a deeper walkthrough based on a reference scenario covering a fictional _European Building Materials_ organization with _OpCo_ use cases see the [Azure Governance from CI/CD Pipelines to Azure Resource Manager](docs/end-to-end-governance.md) walkthrough.

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
