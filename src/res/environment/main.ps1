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
    Create, update or rollback an Azure DevOps Environment.

.DESCRIPTION
    This PowerShell script creates, updates or rolls back an Azure DevOps Environment.

    It provides comprehensive environment management capabilities including configuration of an optional resource group
    and its properties as a scoped environment.

.PARAMETER CollectionUri
    Optional. The collection URI of the Azure DevOps collection/organization, e.g., `https://dev.azure.com/my-org`.

.PARAMETER ProjectName
    Optional. The Azure DevOps project ID or Name where the environment will be created.

.PARAMETER Name
    Required. The name of the environment to create, update, or remove.

.PARAMETER Description
    Optional. A description for the environment.

.PARAMETER Rollback
    Optional. Switch to indicate if the operation should rollback (remove) the environment and related resources.
    ⚠️ WARNING: Use with caution! Removing an environment is irreversible and may affect teams relying on it.

.OUTPUTS
    [PSCustomObject]@{
        id             = Environment ID
        name           = Environment Name
        description    = Environment Description
        createdBy      = User who created the environment
        createdOn      = Timestamp of environment creation
        lastModifiedBy = User who last modified the environment
        lastModifiedOn = Timestamp of last modification
        projectName    = Azure DevOps Project Name
        collectionUri  = Azure DevOps Collection URI
        status         = Operation Status (Created, Updated, NoChange, Removed, NotFound, Skipped)
    }

.EXAMPLE
    $deploySplat = @{
        TemplateFile          = 'main.ps1'
        TemplateParameterFile = 'params/main.parameters.json'
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
        TemplateParameterFile = 'params/main.parameters.json'
    }

    .\deploy.ps1 @rollbackSplat -Rollback -Confirm:$false -Verbose

    Rolls back (removes) the environment and related resources without confirmation.

.EXAMPLE
    $paramSplat = @{
        CollectionUri  = 'https://dev.azure.com/e2egov-org'
        ProjectName    = 'e2egov-prjHb72x9'
        Name           = 'env-e2egov-prjHb72x9-tst'
        Description    = 'Default environment description'
    }
    .\main.ps1 @paramSplat -Verbose

    Deploys a new environment with the specified parameters.

.NOTES
    ## Declarative (DSC-like) Design

    This script follows a declarative, idempotent design pattern similar to Desired State Configuration (DSC).
    Resources are identified by their **Name** (logical identifier), not by system-generated IDs.

    The script automatically determines the required operation based on current state:
    - **Create**: If environment with the specified name doesn't exist
    - **Update**: If environment exists and properties differ from desired state
    - **No Change**: If environment exists and matches desired state
    - **Remove**: If -Rollback switch is specified

    This approach enables true infrastructure-as-code where configuration files define the desired state,
    and the script converges the actual state to match it.
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
[OutputType([PSCustomObject])]
param (
    [Parameter()]
    [string]$CollectionUri = $env:DefaultAdoCollectionUri,

    [Parameter()]
    [string]$ProjectName = $env:DefaultAdoProjectName,

    [Parameter(Mandatory)]
    [string]$Name,

    [Parameter()]
    [string]$Description,

    [Parameter()]
    [switch]$Rollback
)

begin {
    Write-Verbose "[Enter]: ./src/res/environment/$($MyInvocation.MyCommand.Name)"

    # Validate required parameters
    if ([string]::IsNullOrWhiteSpace($CollectionUri)) {
        throw "CollectionUri is required. Provide via parameter or use Set-AdoDefault to set '`$env:DefaultAdoCollectionUri'."
    }
    if ([string]::IsNullOrWhiteSpace($ProjectName)) {
        throw "ProjectName is required. Provide via parameter or use Set-AdoDefault to set '`$env:DefaultAdoProjectName'."
    }

    # Validate Azure context
    $currentContext = Get-AzContext
    if ($null -eq $currentContext) {
        throw 'No Azure context found. Please login using Connect-AzAccount.'
    }

    # Import required module if not already loaded
    $requiredModule = 'Azure.DevOps.PSModule'

    if (-not (Get-Module -Name $requiredModule)) {
        Import-Module $requiredModule -Force -Verbose:$false -ErrorAction Stop
        Write-Verbose "Module '$requiredModule' imported successfully."
    }
}

process {
    try {
        $ErrorActionPreference = 'Stop'

        #region INITIALIZE

        # Status
        $status = 'Unknown'

        # Variables
        $env = $null

        # Environment - Lookup by Name (DSC-like declarative approach)

        $envSplat = @{
            CollectionUri = $CollectionUri
            ProjectName   = $ProjectName
            Name          = $Name
        }

        $env = Get-AdoEnvironment @envSplat -ErrorAction SilentlyContinue

        #endregion

        #region DEPLOYMENTS

        if (-not $Rollback.IsPresent) {
            # Environment
            if ($null -eq $env) {
                if ($PSCmdlet.ShouldProcess($ProjectName, "Create environment: $($Name)")) {
                    $envSplat = @{
                        CollectionUri = $CollectionUri
                        ProjectName   = $ProjectName
                        Name          = $Name
                        Description   = $Description
                    }

                    $env = New-AdoEnvironment @envSplat -Confirm:$false -ErrorAction Stop

                    $status = 'Created'
                    Write-Verbose "[CREATED] Environment: '$Name' (ID: $($env.Id))"
                } else {
                    $env = [PSCustomObject]@{
                        id          = '<generated>'
                        name        = $Name
                        description = $Description
                    }
                    $status = 'WouldCreate'
                    Write-Verbose "[WHATIF] Call New-AdoEnvironment with parameters: $($envSplat | ConvertTo-Json -Depth 5)"
                }

            } else {
                # Environment already exists -> check for changes
                $hasChanges = $false

                $envSplat = @{
                    CollectionUri = $CollectionUri
                    ProjectName   = $ProjectName
                    Id            = $env.Id
                }

                # Only check description if it was explicitly provided
                if ($PSBoundParameters.ContainsKey('Description')) {

                    # Normalize to empty string for comparison
                    $currentDesc = $env.Description ?? ''
                    $newDesc = $Description ?? ''

                    if ($newDesc -ne $currentDesc) {
                        $envSplat['Description'] = $Description
                        $hasChanges = $true
                    }
                }

                if ($hasChanges) {
                    if ($PSCmdlet.ShouldProcess($ProjectName, "Update environment: $($Name)")) {

                        $env = Set-AdoEnvironment @envSplat -Confirm:$false -ErrorAction Stop

                        $status = 'Updated'
                        Write-Verbose "[UPDATED] Environment: '$Name' (ID: $($env.Id))"
                    } else {
                        $status = 'WouldUpdate'
                        Write-Verbose "[WHATIF] Call Set-AdoEnvironment with parameters: $($envSplat | ConvertTo-Json -Depth 5)"
                    }
                } else {
                    $status = 'NoChange'
                    Write-Verbose "[NOCHANGE] Environment: '$Name' (ID: $($env.Id))"
                }
            }
        }

        #endregion

        #region ROLLBACK

        if ($Rollback.IsPresent) {
            if ($null -ne $env) {
                if ($PSCmdlet.ShouldProcess($ProjectName, "Remove environment: $($Name)")) {
                    $envSplat = @{
                        CollectionUri = $CollectionUri
                        ProjectName   = $ProjectName
                        Id            = $env.Id
                    }

                    Remove-AdoEnvironment @envSplat -Confirm:$false -ErrorAction Stop

                    $status = 'Removed'
                    Write-Verbose "[REMOVED] Environment: '$Name' (ID: $($env.Id))"
                } else {
                    $status = 'WouldRemove'
                    Write-Verbose "[WHATIF] Call Remove-AdoEnvironment with parameters: $($envSplat | ConvertTo-Json -Depth 5)"
                }
            } else {
                $status = 'NotFound'
                $env = [PSCustomObject]@{
                    id   = $null
                    name = $Name
                }
                Write-Verbose "[NOTFOUND] Environment: '$Name' (ID: `$null)"
            }

            # Return rollback result; rebuild object for consistency when not found
            return $env | Select-Object -ExcludeProperty collectionUri, projectName -Property *,
            @{ Name = 'projectName'; Expression = { $ProjectName } },
            @{ Name = 'collectionUri'; Expression = { $CollectionUri } },
            @{ Name = 'status'; Expression = { $status } }
        }

        #endregion

        #region OUTPUTS

        # Return deployment result; rebuild object for consistency when created
        $env | Select-Object -ExcludeProperty collectionUri, projectName -Property *,
        @{Name = 'projectName'; Expression = { $ProjectName } },
        @{Name = 'collectionUri'; Expression = { $CollectionUri } },
        @{Name = 'status'; Expression = { $status } }

        #endregion

    } catch {
        throw $_
    }
}

end {
    Write-Verbose "[Exit]: ./src/res/environment/$($MyInvocation.MyCommand.Name)"
}
