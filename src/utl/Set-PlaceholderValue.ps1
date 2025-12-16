#Requires -Version 7.0
<#
.SYNOPSIS
    Replaces placeholders in parameter JSON with values from configuration.

.DESCRIPTION
    This function takes a parameter JSON string and replaces placeholder values (e.g., {uniqueId}, {prefix}, {organization})
    with actual values from a configuration hashtable. This centralizes the parameter placeholder resolution logic
    that is commonly used across deployment scripts.

.PARAMETER ParamsJson
    The parameter JSON string containing placeholders to replace.

.PARAMETER ConfigJson
   The configuration JSON containing the configuration values to substitute for placeholders.

.EXAMPLE
    PS> $config = @{ uniqueId = "A7k9m2"; prefix = "e2egov"; organization = "msc365" }
    PS> $params = Get-Content -Path "params.json" -Raw
    PS> $resolvedParams = Set-PlaceholderValue -ParamsJson $params -ConfigJson $config

    Replaces placeholders like {uniqueId}, {prefix}, and {organization} with values from the config file.

.OUTPUTS
    System.String
    Returns the parameter JSON string with placeholders replaced by actual values.

.NOTES
    Placeholders in the JSON should be in the format {key} where key matches a property in the configuration hashtable.
    The function will replace all occurrences of each placeholder found in the configuration.
#>
function Set-PlaceholderValue {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]$ParamsJson,

        [Parameter(Mandatory)]
        [string]$ConfigJson
    )

    begin {
        Write-Verbose ('[Enter]: .\src\utl\{0}' -f $MyInvocation.MyCommand.Name)
    }

    process {
        try {
            $outputJson = $ParamsJson
            $config = $ConfigJson | ConvertFrom-Json -AsHashtable

            # Remove $schema key if it exists
            if ($config.ContainsKey('$schema')) {
                $config.Remove('$schema') | Out-Null
            }

            # Iterate through each configuration key and replace its placeholder
            foreach ($key in $config.Keys) {
                $placeholder = '{{{0}}}' -f $key
                $value = $config[$key]

                if ($null -ne $value) {
                    Write-Verbose ('Replacing placeholder {0} with value: {1}' -f $placeholder, $value)
                    $outputJson = $outputJson -replace [regex]::Escape($placeholder), $value
                }
            }

            return $outputJson

        } catch {
            Write-Error ('Failed to resolve parameter placeholders: {0}' -f $_.Exception.Message)
            throw $_
        }
    }

    end {
        Write-Verbose ('[Exit]: .\src\utl\{0}' -f $MyInvocation.MyCommand.Name)
    }
}
