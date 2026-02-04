#Requires -Version 7.0
<#
.SYNOPSIS
    Azure subscription context management utilities.

.DESCRIPTION
    This module provides reusable functions for validating and switching Azure subscription contexts,
    along with restoration capabilities to ensure proper context cleanup after operations.

.NOTES
    These functions are designed to be dot-sourced into scripts that need to manage Azure subscription
    contexts, providing consistent validation, switching, and restoration logic across the codebase.
#>

<#
.SYNOPSIS
    Validates and switches Azure subscription context if needed.

.DESCRIPTION
    This utility function validates subscription ID format, switches Azure context
    to the specified subscription if different from current, and returns both
    original and new context information for cleanup/restoration.

.PARAMETER SubscriptionId
    Required. The subscription ID to switch to (if different from current).

.PARAMETER CurrentContext
    Optional. The current Azure context. If not provided, will be retrieved.

.OUTPUTS
    [PSCustomObject]@{
        originalContext = Original Az.Context
        targetContext   = New Az.Context (if switched)
        switched        = Boolean indicating if context was switched
    }

.EXAMPLE
    . .\Set-AzContextInfo.ps1
    $contextInfo = Set-AzContextInfo -SubscriptionId '00000000-0000-0000-0000-000000000000'

    # Do work in the switched context
    # ...

    # Restore original context
    Restore-AzContextInfo -ContextInfo $contextInfo

.EXAMPLE
    $contextInfo = Set-AzContextInfo -SubscriptionId $subscriptionId -Verbose
    try {
        # Perform operations in target subscription
        $rg = New-AzResourceGroup -Name $rgName -Location $location
    }
    finally {
        Restore-AzContextInfo -ContextInfo $contextInfo
    }
#>
function Set-AzContextInfo {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory)]
        [string]$SubscriptionId,

        [Parameter()]
        [object]$CurrentContext
    )

    begin {
        Write-Verbose "[Enter]: ./src/utl/$($MyInvocation.MyCommand.Name)"
    }

    process {
        # Get current context if not provided
        if ($null -eq $CurrentContext) {
            $CurrentContext = Get-AzContext -ErrorAction Stop
            if ($null -eq $CurrentContext) {
                throw 'No Azure context found. Please login using Connect-AzAccount.'
            }
        }

        # Validate subscription ID format
        if ($SubscriptionId -notmatch '^[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}$') {
            throw "Invalid SubscriptionId format: '$SubscriptionId'"
        }

        $switched = $false
        $targetContext = $null

        # Switch context if needed
        if ($CurrentContext.Subscription.Id -ne $SubscriptionId) {
            if ($PSCmdlet.ShouldProcess("Subscription: $SubscriptionId", 'Switch Azure context')) {
                $contextSplat = @{
                    TenantId       = $CurrentContext.Tenant.Id
                    SubscriptionId = $SubscriptionId
                    WhatIf         = $false
                    Verbose        = $false
                }
                $targetContext = Set-AzContext @contextSplat -ErrorAction Stop

                # Verify the context switch was successful
                $verifyContext = Get-AzContext
                if ($verifyContext.Subscription.Id -ne $SubscriptionId) {
                    throw "Failed to switch to subscription '$SubscriptionId'"
                }

                $switched = $true
                Write-Verbose "Switched to subscription: $SubscriptionId"
            }
        } else {
            Write-Verbose "Already in target subscription: $SubscriptionId"
        }

        return [PSCustomObject]@{
            originalContext = $CurrentContext
            targetContext   = if ($switched) { $targetContext } else { $CurrentContext }
            switched        = $switched
        }
    }

    end {
        Write-Verbose "[Exit]: ./src\utl\$($MyInvocation.MyCommand.Name)"
    }
}

<#
.SYNOPSIS
    Restores the original Azure subscription context.

.DESCRIPTION
    Helper function to restore the original Azure context after operations
    that may have switched subscriptions. Should be called in a finally block
    to ensure cleanup happens even if errors occur.

.PARAMETER ContextInfo
    Required. The context information object returned by Set-AzContextInfo.

.EXAMPLE
    . .\Set-AzContextInfo.ps1
    $contextInfo = Set-AzContextInfo -SubscriptionId $subscriptionId
    try {
        # Do work
    }
    finally {
        Restore-AzContextInfo -ContextInfo $contextInfo
    }

.NOTES
    This function will only attempt to restore the context if it was actually switched.
    If restoration fails, a warning is written but no exception is thrown to avoid
    masking the original error that may have triggered the finally block.
#>
function Restore-AzContextInfo {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [object]$ContextInfo
    )

    begin {
        Write-Verbose "[Enter]: ./src\utl\$($MyInvocation.MyCommand.Name)"
    }

    process {
        if ($ContextInfo.switched) {
            try {
                $restoreSplat = @{
                    TenantId       = $ContextInfo.originalContext.Tenant.Id
                    SubscriptionId = $ContextInfo.originalContext.Subscription.Id
                    WhatIf         = $false
                    Verbose        = $false
                }
                $restored = Set-AzContext @restoreSplat -ErrorAction Stop
                Write-Verbose "Restored original subscription context: $($restored.Subscription.Id)"
            } catch {
                Write-Warning "Failed to restore original Azure context: $_"
                Write-Warning "Current context may be set to subscription: $($ContextInfo.targetContext.Subscription.Id)"
            }
        }
    }

    end {
        Write-Verbose "[Exit]: ./src/utl/$($MyInvocation.MyCommand.Name)"
    }
}
