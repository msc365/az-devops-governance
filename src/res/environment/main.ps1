#Requires -Version 7.0
<#PSScriptInfo
    .VERSION 0.1.0

    .GUID 4adf0e7d-d5cc-4f5a-a1fb-0945e475571a

    .AUTHOR Martin Swinkels

    .COMPANYNAME MSc365.eu

    .COPYRIGHT 2025 (c) MSc365.eu, Martin Swinkels

    .TAGS 'Azure', 'Security', 'Governance', 'DevOps', 'Platform', 'RBAC'

    .LICENSEURI https://github.com/msc365/az-devops-governance/blob/main/LICENSE

    .PROJECTURI https://github.com/msc365/az-devops-governance

    .ICONURI https://raw.githubusercontent.com/msc365/az-devops-governance/main/.assets/icon.png

    .EXTERNALMODULEDEPENDENCIES Az.Accounts, Az.Resources, Azure.DevOps.PSModule
#>
<#
.SYNOPSIS
    Creates or updates an Azure DevOps Environment.

.DESCRIPTION
    This PowerShell script creates or updates an Azure DevOps Environment.

    It provides comprehensive environment management capabilities including configuration of an optional resource group
    and its properties as a scoped environment.

.PARAMETER Organization
    Required. The Azure DevOps organization name.

.PARAMETER ProjectId
    Required. The Azure DevOps project ID or Name where the environment will be created.

.PARAMETER Name
    Required. The name of the environment to create or update.

.PARAMETER Description
    Optional. A description for the environment.

.PARAMETER ResourceGroup
    Optional. An optional object defining the resource group properties: `Name`, `Location`, `SubscriptionId`, `Tags`. See [Notes](#notes) for more information.

.PARAMETER Rollback
    Optional. Switch to indicate if the operation should rollback (delete) the environment and related resources. <br /> <b> WARNING! </b> <br /> Use with caution! Removing an environment is irreversible and may affect teams relying on it. See [Notes](#notes) for more information.

.PARAMETER Force
    Optional. Switch to force deletion without confirmation during rollback.

.EXAMPLE
    $deploySplat = @{
        TemplateFile          = 'main.ps1'
        TemplateParameterFile = 'params\main.parameters.json'
    }

    .\deploy.ps1 @deploySplat -Verbose

    Deploys the environment using the specified template and parameters.

.EXAMPLE
    $customSplat = @{
        TemplateFile          = 'main.ps1'
        TemplateParameterFile = 'params\custom.parameters.json'
    }

    .\deploy.ps1 @customSplat -Verbose

    Deploys the environment using the specified template and custom parameters.

.EXAMPLE
    $rollbackSplat = @{
        TemplateFile          = 'main.ps1'
        TemplateParameterFile = 'params\main.parameters.json'
    }

    .\deploy.ps1 @rollbackSplat -Rollback -Force -Verbose

    Rolls back (deletes) the environment and related resources without confirmation.

.EXAMPLE
    $paramSplat = @{
        Organization   = 'e2egov-org'
        ProjectId      = 'e2egov-prjHb72x9'
        Name           = 'env-prjHb72x9-tst'
        Description    = 'Default e2e governance description'
        ResourceGroup  = @{
            Name           = 'rg-e2egov-prjHb72x9-tst-neu'
            Location       = 'northeurope'
            SubscriptionId = '00000000-0000-0000-0000-000000000000'
            Tags           = @{ environment = 'tst'; service = 'e2egov' }
        }
    }
    .\main.ps1 @paramSplat -Verbose

    Deploys a new environment including the configuration of an optional resource group
    and its properties as a (least privileged) scoped environment using the specified parameters in code.
    See [Service Connection](../service-connection) deployment for creating a service connection with least privileged access to the resource group.
#>
[CmdletBinding(SupportsShouldProcess)]
[OutputType([pscustomobject])]
param (
    [Parameter(Mandatory)]
    [string]$Organization,

    [Parameter(Mandatory)]
    [string]$ProjectId,

    [Parameter(Mandatory)]
    [string]$Name,

    [Parameter(Mandatory = $false)]
    [string]$Description,

    [Parameter(Mandatory = $false)]
    [object]$ResourceGroup,

    [Parameter()]
    [switch]$Rollback,

    [Parameter()]
    [switch]$Force
)

begin {
    Write-Verbose ('[Enter]: .\src\res\environment\{0}' -f $MyInvocation.MyCommand.Name)

    if ($null -eq (Get-AzContext)) {
        throw 'No Azure context found. Please login using Connect-AzAccount.'
    }

    # Define required modules
    $modules = @(
        'Azure.DevOps.PSModule'
    )

    # Import required modules
    $modules | ForEach-Object {
        if (-not (Get-Module -Name $_)) {
            Import-Module $_ -Force -Verbose:$false -ErrorAction Stop
        }
    }

    # Connect to Azure DevOps Organization
    Connect-AdoOrganization -Organization $Organization
}

process {
    try {
        $ErrorActionPreference = 'Stop'
        $Error.Clear()

        #region INITIALIZE

        # Variables
        $prj, $env, $ctx, $sub, $rg = $null

        # Project
        $prj = Get-AdoProject -ProjectId $ProjectId -ErrorAction SilentlyContinue

        if ($null -eq $prj) {
            throw ("Doesn't exists. '/projects/{0}' ." -f $ProjectId)
        }

        # Environment
        $envSplat = @{
            ProjectId = $prj.Id
            Name      = $Name
            Verbose   = $VerbosePreference
        }

        $env = Get-AdoEnvironmentList @envSplat -ErrorAction SilentlyContinue

        if ($null -ne $ResourceGroup) {
            # Subscription Context
            $ctx = Get-AzContext -ErrorAction Stop

            if ($ctx.Subscription.Id -ne $ResourceGroup.subscriptionId) {
                $subSplat = @{
                    TenantId       = $ctx.Tenant.Id
                    SubscriptionId = $ResourceGroup.subscriptionId
                    WhatIf         = $false
                }

                $sub = Set-AzContext @subSplat -ErrorAction Stop
            }

            # Resource Group
            $rgSplat = @{
                Name     = $ResourceGroup.name
                Location = $ResourceGroup.location
                Tags     = $ResourceGroup.tags
                Rollback = $Rollback.IsPresent
                WhatIf   = $WhatIfPreference
                Verbose  = $VerbosePreference
            }

            $rg = & (Join-Path -Path $PSScriptRoot -ChildPath '..\shared\resource-group\main.ps1') @rgSplat
        }

        #endregion

        #region DEPLOYMENTS

        if (-not $Rollback.IsPresent) {
            # Environment
            if ($null -eq $env) {
                if ($PSCmdlet.ShouldProcess(('{0}' -f $Name), 'Create')) {

                    $envSplat = @{
                        ProjectId   = $prj.Id
                        Name        = $Name
                        Description = $Description
                        Verbose     = $VerbosePreference
                    }

                    $env = New-AdoEnvironment @envSplat
                }
            } else {
                if ($Description -ne $env.description) {

                    if ($PSCmdlet.ShouldProcess(('{0}' -f $Name), 'Update')) {
                        $envSplat = @{
                            ProjectId     = $prj.Id
                            EnvironmentId = $env.Id
                            Name          = $Name
                            Description   = $Description
                            Verbose       = $VerbosePreference
                        }

                        $env = Set-AdoEnvironment @envSplat
                    }
                } else {
                    Write-Verbose ("Exists. '/environment/{0}'" -f $Name)
                }
            }
        }

        #endregion

        #region ROLLBACK

        if ($Rollback.IsPresent) {
            if ($null -ne $env) {
                if ($PSCmdlet.ShouldProcess(('{0}' -f $Name), 'Delete')) {
                    if (-not $Force.IsPresent) {
                        $prompt = @(
                            "This script will delete environment '$($Name)'."
                            'All related resources like approvals and checks will be lost.'
                            "Do you want to continue? 'Yes [Y]' 'No [N]'"
                        ) -join "`n"

                        $result = Read-Host -Prompt $prompt
                        $result = $result.ToLower()

                        if ($result -ne 'y' -and $result -ne 'yes') {
                            Write-Warning 'Operation cancelled by user'
                            return
                        }
                    }

                    # Environment
                    $envSplat = @{
                        ProjectId     = $prj.Id
                        EnvironmentId = $env.Id
                        Verbose       = $VerbosePreference
                    }

                    Remove-AdoEnvironment @envSplat | Out-Null
                    Write-Verbose ("Deleted. '/environment/{0}'" -f $Name)
                }
            } else {
                Write-Warning ("Doesn't Exist. '/environment/{0}'" -f $Name)
            }

            return
        }

        #endregion

        #region OUTPUTS

        if (-not $WhatIfPreference) {

            $output = [pscustomobject]@{
                Environment = ($env | Select-Object *) ?? $null
            }

            if ($null -ne $rg) {
                $addMemberSplat = @{
                    MemberType = 'NoteProperty'
                    Name       = 'ResourceGroup'
                    Value      = ($rg | Select-Object ResourceGroupName, Location, ProvisioningState, Tags, ResourceId, ManagedBy )
                    Force      = $true
                }
                $output | Add-Member @addMemberSplat
            }

            return $output | Format-List *
        }

        return $null

        #endregion

    } catch {
        throw $_
    }

    finally {
        if ($null -ne $ctx -and $null -ne $sub) {
            $ctxSplat = @{
                TenantId       = $ctx.Tenant.Id
                SubscriptionId = $ctx.Subscription.Id
                WhatIf         = $false
            }
            Set-AzContext @ctxSplat | Out-Null
        }
    }
}

end {
    Write-Verbose ('[Exit]: .\src\res\environment\{0}' -f $MyInvocation.MyCommand.Name)
}
