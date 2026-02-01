function ConvertTo-Hashtable {
    param(
        [object]$InputObject
    )

    switch ($InputObject) {
        { $_ -is [System.Collections.IDictionary] } { return $_ }
        { $_ -is [System.Collections.IEnumerable] -and -not ($_ -is [string]) } {
            return @(@( $_ | ForEach-Object { ConvertTo-Hashtable $_ } ))
        }
        { $_ -is [pscustomobject] } {
            $hash = [ordered]@{}
            foreach ($prop in $_.PSObject.Properties) {
                $hash[$prop.Name] = ConvertTo-Hashtable $prop.Value
            }
            return $hash
        }
        default { return $_ }
    }
}
