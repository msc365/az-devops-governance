# az-devops-governance

In addition to the [Azure.DevOps.PSModule](https://github.com/msc365/az-devops-psmodule) module, this repository includes sample scripts that demonstrate a complete Azure governance model. These examples showcase how to implement end-to-end governance from CI/CD pipelines to Azure Resource Manager deployments, aligning with best practices for enterprise-grade cloud architecture.

> [!NOTE]
> This project is built upon the foundational concepts derived from [DevOps Governance](https://github.com/Azure/devops-governance) by [Julie Ng](https://github.com/julie-ng) using Terraform. I have enhanced it by incorporating the latest best practices. Specifically, I utilized **Bicep** as Infrastructure as Code (IaC) where possible and used this custom **PowerShell** module and sample scripts to bootstrap Azure DevOps projects, Azure resources and Entra identities. Additionally, I implemented [workload identity federation](https://devblogs.microsoft.com/devops/workload-identity-federation-for-azure-deployments-is-now-generally-available/) for Azure Pipelines, moving away from traditional _service principals_ to improve security and manageability.

<!-- omit from toc -->
## Features

- Secure authentication with Workload Identity Federation
- Sample scripts for CI/CD, resource provisioning, and policy enforcement
- Practical guidance for implementing Azure governance at scale

<!-- omit from toc -->
## Use Cases

- Automate DevOps workflows and resource deployments
- Enforce governance policies across environments
- Integrate Azure DevOps with PowerShell and infrastructure-as-code practices
- Accelerate onboarding and standardization for cloud teams
