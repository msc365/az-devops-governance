<#
.SYNOPSIS
    Audits user access and permissions in an Azure DevOps organization, identifying potential security risks.

.DESCRIPTION
    This script retrieves all users and their group memberships in the specified Azure DevOps organization.
    It analyzes access levels, identifies inactive admin users, and flags external users with high privileges.
    The results are exported to a CSV file for further review.

.PARAMETER Organization
    Required. The name of the Azure DevOps organization to audit.

.PARAMETER Domain
    Required. The domain to consider as internal.

.PARAMETER OutputPath
    Optional. The file path to save the audit results. Default is 'C:\_tmp\UserAccessAudit.csv'.

.EXAMPLE
    $params = @{
        Organization = 'my-org'
        Domain       = 'mydomain.com'
        OutputPath   = 'C:\Audits\MyOrgUserAccessAudit.csv'
    }
    .\Invoke-UserAccessAudit.ps1 @params

    Audits the 'my-org' Azure DevOps organization, treating 'mydomain.com' as internal, and saves the results to 'C:\Audits\MyOrgUserAccessAudit.csv'.

.LINK
    https://learn.microsoft.com/en-us/azure/devops/organizations/security/security-scripts

.NOTES
    - Requires Azure.DevOps.PSModule, which can be installed via Install-Module -Name Azure.DevOps.PSModule -Scope CurrentUser
    - Ensure you have appropriate permissions to access the Azure DevOps organization and its user information.
#>
param(
    [Parameter(Mandatory)]
    [string]$Organization,

    [Parameter(Mandatory)]
    [string]$Domain,

    [Parameter()]
    [string]$OutputPath = 'C:\_tmp\UserAccessAudit.csv'
)

# Authenticate and setup
if (-not (Get-AzContext -ErrorAction SilentlyContinue)) {
    Connect-AzAccount
}

# Set Azure DevOps organization context
Set-AdoDefault -Organization $Organization | Out-Null

Write-Host "Starting user access audit for organization: $Organization" -ForegroundColor Cyan

$auditResults = @()
$riskFindings = @()

# Get all users in the organization
$users = Get-AdoUser

# Get all groups and their members
$groups = Get-AdoGroup

Write-Host "Found $($users.count) users and $($groups.count) groups" -ForegroundColor Yellow

foreach ($user in $users) {
    try {
        # Get user's group memberships
        $memberships = Get-AdoMembership -SubjectDescriptor $user.descriptor -Direction Up

        # Analyze access level and permissions
        $isAdmin = $false
        $adminGroups = @()
        $lastAccessDate = 'Unknown'

        foreach ($membership in $memberships) {
            $groupName = ($groups | Where-Object { $_.descriptor -eq $membership.containerDescriptor }).displayName

            if ($groupName -match 'Administrator|Admin|Collection|Project Collection') {
                $isAdmin = $true
                $adminGroups += $groupName
            }
        }

        # Check for inactive users with admin access
        if ($isAdmin -and $user.lastAccessedDate) {
            $lastAccess = [DateTime]$user.lastAccessedDate
            if ($lastAccess -lt (Get-Date).AddDays(-90)) {
                $riskFindings += [PSCustomObject]@{
                    Type        = 'Inactive Admin User'
                    User        = $user.displayName
                    Email       = $user.mailAddress
                    LastAccess  = $lastAccess
                    AdminGroups = ($adminGroups -join ', ')
                    Risk        = 'High'
                }
            }
        }

        # Check for external users with high privileges
        if ($user.mailAddress -notlike "*@$Domain" -and $isAdmin) {
            $riskFindings += [PSCustomObject]@{
                Type        = 'External Admin User'
                User        = $user.displayName
                Email       = $user.mailAddress
                LastAccess  = $user.lastAccessedDate
                AdminGroups = ($adminGroups -join ', ')
                Risk        = 'High'
            }
        }

        $auditResults += [PSCustomObject]@{
            DisplayName    = $user.displayName
            Email          = $user.mailAddress
            Domain         = if ($user.mailAddress) { $user.mailAddress.Split('@')[1] } else { 'Unknown' }
            IsAdmin        = $isAdmin
            AdminGroups    = ($adminGroups -join ', ')
            LastAccess     = $user.lastAccessedDate
            UserType       = if ($user.mailAddress -like "*@$Domain") { 'Internal' } else { 'External' }
            AccountEnabled = if ($user.metaType -eq 'member') { 'Active' } else { 'Inactive' }
        }

        Write-Progress -Activity 'Auditing users' -Status "Processing $($user.displayName)" -PercentComplete (($auditResults.Count / $users.count) * 100)
    } catch {
        Write-Warning "Failed to process user $($user.displayName): $($_.Exception.Message)"
    }
}

# Generate reports
Write-Host 'Generating audit reports...' -ForegroundColor Yellow

# Export full audit results
$auditResults | Export-Csv -Path $OutputPath -NoTypeInformation
Write-Host "Full audit exported to: $OutputPath" -ForegroundColor Green

# Display risk summary
if ($riskFindings.Count -gt 0) {
    Write-Host 'Security risks identified:' -ForegroundColor Red
    $riskFindings | Format-Table -AutoSize

    $riskPath = $OutputPath.Replace('.csv', '_SecurityRisks.csv')
    $riskFindings | Export-Csv -Path $riskPath -NoTypeInformation
    Write-Host "Security risks exported to: $riskPath" -ForegroundColor Yellow
} else {
    Write-Host 'No critical security risks identified' -ForegroundColor Green
}

# Display summary statistics
$stats = @{
    TotalUsers       = $auditResults.Count
    AdminUsers       = ($auditResults | Where-Object { $_.IsAdmin }).Count
    ExternalUsers    = ($auditResults | Where-Object { $_.UserType -eq 'External' }).Count
    ExternalAdmins   = ($auditResults | Where-Object { $_.UserType -eq 'External' -and $_.IsAdmin }).Count
    InactiveAccounts = ($auditResults | Where-Object { $_.AccountEnabled -eq 'Inactive' }).Count
}

Write-Host "`nAudit Summary:" -ForegroundColor Cyan
$stats.GetEnumerator() | ForEach-Object {
    Write-Host "  $($_.Key): $($_.Value)" -ForegroundColor White
}
