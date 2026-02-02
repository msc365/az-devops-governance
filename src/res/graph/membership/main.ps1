#Requires -Version 7.0
<#PSScriptInfo
    .VERSION 0.1.0

    .GUID 3083d7f7-a885-460d-966f-8f0ff06dec6b

    .AUTHOR Martin Swinkels

    .COMPANYNAME MSc365.eu

    .COPYRIGHT 2025 (c) MSc365.eu, Martin Swinkels

    .TAGS 'Azure', 'Security', 'Governance', 'DevOps', 'Platform', 'RBAC'

    .LICENSEURI https://github.com/msc365/az-devops-governance/blob/main/LICENSE

    .PROJECTURI https://github.com/msc365/az-devops-governance

    .ICONURI https://raw.githubusercontent.com/msc365/az-devops-governance/main/.assets/icon.png

    .EXTERNALMODULEDEPENDENCIES Az.Accounts, Azure.DevOps.PSModule, Microsoft.Graph.Groups
#>
<#
.SYNOPSIS
    Manage Azure DevOps group memberships based on Entra ID security groups.

.DESCRIPTION
    This script manages Azure DevOps group memberships by adding specified Entra ID security groups to built-in Azure DevOps groups within a given project.

.PARAMETER CollectionUri
    Optional. The collection URI of the Azure DevOps collection/organization, e.g., `https://dev.azure.com/my-org`.

.PARAMETER ProjectName
    Optional. The Azure DevOps project ID or Name where the environment will be created.

.PARAMETER UniqueName
    Mandatory. The UniqueName (MailNickname) of the Entra ID security group to be added to Azure DevOps groups.

.PARAMETER GroupMembership
    Mandatory. The name of the Azure DevOps built-in group to which the Entra ID security group will be added, e.g., `Readers`, `Contributors`, `Project Administrators`.

.PARAMETER Rollback
    Optional. Switch to indicate if the operation should be rolled back (i.e., remove the specified group memberships).
    ⚠️ Note: Rollback functionality is not yet implemented.

.OUTPUTS
    [PSCustomObject]@{
        memberDescriptor    = The descriptor of the member (Entra ID security group)
        containerDescriptor = The descriptor of the container (Azure DevOps built-in group)
        uniqueName          = Entra ID Group UniqueName (MailNickname)
        originId            = Entra ID Group Object ID
        groupMembership     = Azure DevOps Built-in Group Name
        projectName         = Azure DevOps Project Name
        collectionUri       = Azure DevOps Collection URI
        status              = Operation Status (Created, Updated, NoChange, Removed, NotFound)
    }

.EXAMPLE
    $deploySplat = @{
        TemplateFile          = 'main.ps1'
        TemplateParameterFile = 'params/main.parameters.json'
    }

    .\deploy.ps1 @deploySplat -Verbose

    Deploys the group membership using the specified template and parameters.

.EXAMPLE
    $customSplat = @{
        TemplateFile          = 'main.ps1'
        TemplateParameterFile = 'params\custom.parameters.json'
    }

    .\deploy.ps1 @customSplat -Verbose

    Deploys the group membership using the specified template and custom parameters.

.EXAMPLE
    $rollbackSplat = @{
        TemplateFile          = 'main.ps1'
        TemplateParameterFile = 'params/main.parameters.json'
    }

    .\deploy.ps1 @rollbackSplat -Rollback -Confirm:$false -Verbose

    Rolls back (removes) the group membership and related resources without confirmation.

.EXAMPLE
    $params = @{
        CollectionUri   = 'https://dev.azure.com/e2egov-org'
        ProjectName     = 'e2egov-prjHb72x9'
        UniqueName      = 'e2egov-prjHb72x9-devs'
        GroupMembership = 'Contributors'
    }
    .\main.ps1 @params -Verbose

    Deploys a new group membership with the specified parameters.
#>
[CmdletBinding(SupportsShouldProcess)]
[OutputType([PSCustomObject])]
param (
    [Parameter()]
    [string]$CollectionUri = $env:DefaultAdoCollectionUri,

    [Parameter()]
    [string]$ProjectName = $env:DefaultAdoProjectName,

    [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
    [string]$UniqueName,

    [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
    [string]$GroupMembership,

    [Parameter()]
    [switch]$Rollback
)

begin {
    Write-Verbose "[Enter]: ./src/res/membership/$($MyInvocation.MyCommand.Name)"

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

    # Validate Microsoft Graph context
    if ($null -eq (Get-MgContext)) {
        throw 'No Microsoft Graph context found. Please login using Connect-MgGraph'
    }

    # Import required module if not already loaded
    $requiredModules = @('Azure.DevOps.PSModule', 'Microsoft.Graph.Groups')

    foreach ($requiredModule in $requiredModules) {
        if (-not (Get-Module -Name $requiredModule)) {
            Import-Module $requiredModule -Force -Verbose:$false -ErrorAction Stop
            Write-Verbose "Module '$requiredModule' imported successfully."
        }
    }

    # Project
    $prjSplat = @{
        CollectionUri = $CollectionUri
        Project       = $ProjectName
    }
    $prj = Get-AdoProject @prjSplat -Verbose:$false -ErrorAction SilentlyContinue

    if ($null -eq $prj) {
        throw "Project with ID $ProjectName does not exist, cannot proceed."
    }

    # Project scope descriptor
    $prjScopeDescSplat = @{
        CollectionUri = $CollectionUri
        StorageKey    = $prj.id
    }
    $projectScopeDescriptor = (Get-AdoDescriptor @prjScopeDescSplat -Verbose:$false).value

    # Get built-in group
    $buildInGroupsSplat = @{
        CollectionUri   = $CollectionUri
        ScopeDescriptor = $projectScopeDescriptor
        SubjectTypes    = 'vssgp'
    }
    $buildInGroups = (Get-AdoGroup @buildInGroupsSplat -Verbose:$false)

    # Get Entra ID group
    $entraGroupsSplat = @{
        CollectionUri = $CollectionUri
        SubjectTypes  = 'aadgp'
    }
    $entraGroups = Get-AdoGroup @entraGroupsSplat -Verbose:$false
}

process {
    try {
        $ErrorActionPreference = 'Stop'

        #region INITIALIZE

        # Status
        $status = 'Unknown'

        # Variables
        $mgGrp, $grpMshp = $null

        # Graph group lookup
        $mgGrpSplat = @{
            Filter   = "mailNickname eq '$($UniqueName)'"
            Property = 'Id, MailNickname, DisplayName'
        }
        $mgGrp = Get-MgGroup @mgGrpSplat

        if ($null -eq $mgGrp) {
            throw "Security group with UniqueName '$($UniqueName)' does not exist, cannot proceed."
        }

        # Build-in group lookup
        $buildInGroup = $buildInGroups | Where-Object { $_.displayName -eq $GroupMembership }

        # Entra group lookup
        $entraGroup = $entraGroups | Where-Object { $_.originId -eq $mgGrp.id }

        if ($null -eq $entraGroup) {
            # Entra ID group not found in Azure DevOps, so membership cannot exist
            $grpMshp = $null
        } else {
            # Check if membership already exists
            $groupMembershipSplat = @{
                CollectionUri       = $CollectionUri
                subjectDescriptor   = $entraGroup.descriptor
                containerDescriptor = $buildInGroup.descriptor
            }

            $grpMshp = Get-AdoMembership @groupMembershipSplat -Verbose:$false -ErrorAction SilentlyContinue
        }

        #endregion

        #region DEPLOYMENTS

        if (-not $Rollback.IsPresent) {
            if ($null -eq $grpMshp) {
                $addMembershipSplat = @{
                    CollectionUri   = $CollectionUri
                    GroupDescriptor = $buildInGroup.descriptor
                    GroupId         = $mgGrp.Id
                }

                if ($PSCmdlet.ShouldProcess($mgGrp.mailNickname, "Add group membership: $GroupMembership")) {

                    $addGrpMshp = Add-AdoGroupMember @addMembershipSplat -Confirm:$false -Verbose:$false

                    $grpMshp = [PSCustomObject]@{
                        memberDescriptor    = $addGrpMshp.descriptor
                        containerDescriptor = $buildInGroup.descriptor
                    }

                    $status = 'Added'
                    Write-Verbose "[ADDED]: Group membership '$GroupMembership' (GroupId: $($mgGrp.Id))"
                } else {
                    $status = 'WouldCreate'
                    Write-Verbose "[WHATIF]: Call Add-AdoGroupMember with parameters: $($addMembershipSplat | ConvertTo-Json -Depth 5)"
                }
            } else {
                $status = 'NoChange'
                Write-Verbose "[NOCHANGE]: Group membership '$GroupMembership' (GroupId: $($mgGrp.Id))"
            }
        }

        #endregion

        #region ROLLBACK

        if ($Rollback.IsPresent) {
            if ($null -ne $grpMshp) {

                $status = 'NotImplemented'
                $grpMshp = [PSCustomObject]@{
                    memberDescriptor    = $grpMshp.memberDescriptor
                    containerDescriptor = $buildInGroup.descriptor
                }
                # TODO: Implement removal of membership when available
                # Waiting for Azure.DevOps.PSModule to implement Remove-AdoMembership
                Write-Warning "[NOTIMPLEMENTED]: Group membership '$GroupMembership' (GroupId: $($mgGrp.Id))"

            } else {
                $status = 'NotFound'
                $grpMshp = [PSCustomObject]@{
                    memberDescriptor    = '<unknown>'
                    containerDescriptor = $buildInGroup.descriptor
                }
                Write-Verbose "[NOTFOUND]: Group membership '$GroupMembership' (GroupId: $($mgGrp.Id))"
            }
        }

        #endregion

        #region OUTPUTS

        # Return deployment result; rebuild object
        $grpMshp | Select-Object -ExcludeProperty collectionUri -Property *,
        @{ Name = 'uniqueName'; Expression = { $mgGrp.mailNickname } },
        @{ Name = 'originId'; Expression = { $mgGrp.id } },
        @{ Name = 'groupMembership'; Expression = { $GroupMembership } },
        @{ Name = 'projectName'; Expression = { $ProjectName } },
        @{ Name = 'collectionUri'; Expression = { $CollectionUri } },
        @{ Name = 'status'; Expression = { $status } }

        #endregion

    } catch {
        throw $_
    }
}

end {
    Write-Verbose ("[Exit]: ./src/res/membership/$($MyInvocation.MyCommand.Name)")
}
