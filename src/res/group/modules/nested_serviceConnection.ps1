[CmdletBinding(SupportsShouldProcess)]
[OutputType([object])]
param (
    [Parameter(Mandatory)]
    [string]$EndPointName,

    [Parameter(Mandatory)]
    [object]$ProjectRef,

    [Parameter(Mandatory)]
    [object]$AuthorizationRef,

    [Parameter(Mandatory)]
    [object]$IdentityRef
)

begin {
    Write-Verbose "[Enter]: .\$($MyInvocation.MyCommand.Name)"
}

process {
    try {
        $ErrorActionPreference = 'Stop'

        $endpointSplat = @{
            Project      = $ProjectRef.Id
            EndPointName = $EndPointName
        }

        $endpoint = Get-AdoServiceEndpointByName @endpointSplat -Verbose:$VerbosePreference

        if ($null -eq $endpoint) {
            if ($PSCmdlet.ShouldProcess("Call module 'Azure.DevOps.PSModule' operation.", 'New-AdoServiceEndpoint')) {

                $subSplat = @{
                    SubscriptionId = ($AuthorizationRef.Scope -split '/')[2]
                    TenantId       = $AuthorizationRef.TenantId
                }
                $sub = Get-AzSubscription @subSplat -ErrorAction Stop

                $data = [Ordered]@{
                    creationMode     = 'Manual'
                    environment      = 'AzureCloud'
                    scopeLevel       = 'Subscription'
                    subscriptionId   = $sub.SubscriptionId
                    subscriptionName = $sub.Name
                }

                $endpointConfig = [Ordered]@{
                    data                             = $data
                    name                             = $EndPointName
                    type                             = 'AzureRM'
                    url                              = 'https://management.azure.com/'
                    authorization                    = [Ordered]@{
                        parameters = [Ordered]@{
                            serviceprincipalid = $AuthorizationRef.ServiceprincipalId
                            tenantid           = $AuthorizationRef.TenantId
                            scope              = $AuthorizationRef.Scope
                        }
                        scheme     = 'WorkloadIdentityFederation'
                    }
                    isShared                         = $false
                    isReady                          = $true
                    serviceEndpointProjectReferences = @(
                        [Ordered]@{
                            name             = $EndPointName
                            projectReference = [Ordered]@{
                                id   = $ProjectRef.Id
                                name = $ProjectRef.Name
                            }
                        }
                    )
                }

                $endpointSplat = @{
                    Configuration = ($endpointConfig | ConvertTo-Json -Depth 5)
                    Verbose       = $VerbosePreference
                }

                $endpoint = New-AdoServiceEndpoint @endpointSplat -ErrorAction Stop
            }
        } else {
            Write-Verbose "NoChange: 'RESOURCE /ServiceEndpoint/$($endpoint.name)'"
        }

        # Federated Identity Credential

        $fic = Get-AzFederatedIdentityCredential @IdentityRef -ErrorAction SilentlyContinue -Verbose:$VerbosePreference

        if ($null -eq $fic) {
            if ($PSCmdlet.ShouldProcess("Call module 'Az.ManagedServiceIdentity' operation.", 'New-AzFederatedIdentityCredential')) {

                $ficName = "cred-$($EndPointName.Substring(3))"

                $IdentityRef += @{
                    Name    = $ficName
                    Issuer  = $endpoint.authorization.parameters.workloadIdentityFederationIssuer
                    Subject = $endpoint.authorization.parameters.workloadIdentityFederationSubject
                }

                New-AzFederatedIdentityCredential @IdentityRef -Verbose:$VerbosePreference | Out-Null
            }
        } else {
            Write-Verbose "NoChange: 'RESOURCE /FederatedIdentityCredential/$($fic.Name)'"
        }

        return $endpoint

    } catch {
        throw $_
    }
}

end {
    Write-Verbose "[Exit]: .\$($MyInvocation.MyCommand.Name)"
}
