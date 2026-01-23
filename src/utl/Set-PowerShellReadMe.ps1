#Requires -Version 7.0
<#
.SYNOPSIS
    Generates or updates README.md files for PowerShell scripts based on script metadata and structure.

.DESCRIPTION
    This script analyzes PowerShell scripts and generates comprehensive README documentation
    including description, parameters, examples, outputs, and dependencies. It mirrors the
    functionality of setReadMe.ps1 but for PowerShell scripts instead of Bicep templates.
#>

#region Helper Functions

function Get-ScriptMetadata {
    <#
    .SYNOPSIS
        Extracts metadata from a PowerShell script including PSScriptInfo and comment-based help.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string] $ScriptPath
    )

    $scriptContent = Get-Content -Path $ScriptPath -Raw
    $scriptAst = [System.Management.Automation.Language.Parser]::ParseFile($ScriptPath, [ref]$null, [ref]$null)

    $metadata = @{
        Synopsis              = $null
        Description           = $null
        Parameters            = @()
        Examples              = @()
        Notes                 = $null
        PSScriptInfo          = @{}
        Outputs               = $null
        RequiredModules       = @()
        SupportsShouldProcess = $false
    }

    # Extract PSScriptInfo
    if ($scriptContent -match '<#PSScriptInfo([\s\S]*?)#>') {
        $psScriptInfoBlock = $matches[1]

        if ($psScriptInfoBlock -match '\.VERSION\s+(.+)') { $metadata.PSScriptInfo.Version = $matches[1].Trim() }
        if ($psScriptInfoBlock -match '\.AUTHOR\s+(.+)') { $metadata.PSScriptInfo.Author = $matches[1].Trim() }
        if ($psScriptInfoBlock -match '\.COMPANYNAME\s+(.+)') { $metadata.PSScriptInfo.CompanyName = $matches[1].Trim() }
        if ($psScriptInfoBlock -match '\.COPYRIGHT\s+(.+)') { $metadata.PSScriptInfo.Copyright = $matches[1].Trim() }
        if ($psScriptInfoBlock -match '\.TAGS\s+(.+)') { $metadata.PSScriptInfo.Tags = $matches[1].Trim() }
        if ($psScriptInfoBlock -match '\.LICENSE\s+(.+)') { $metadata.PSScriptInfo.License = $matches[1].Trim() }
        if ($psScriptInfoBlock -match '\.LICENSEURI\s+(.+)') { $metadata.PSScriptInfo.LicenseUri = $matches[1].Trim() }
        if ($psScriptInfoBlock -match '\.PROJECTURI\s+(.+)') { $metadata.PSScriptInfo.ProjectUri = $matches[1].Trim() }
        if ($psScriptInfoBlock -match '\.EXTERNALMODULEDEPENDENCIES\s+(.+)') {
            $metadata.PSScriptInfo.ExternalModuleDependencies = $matches[1].Trim() -split ',\s*'
        }
    }

    # Extract comment-based help
    if ($scriptContent -match '<#([\s\S]*?)\.SYNOPSIS([\s\S]*?)(?=\.(DESCRIPTION|PARAMETER|EXAMPLE|NOTES|OUTPUTS|#>))') {
        $metadata.Synopsis = $matches[2].Trim()
    }

    if ($scriptContent -match '\.DESCRIPTION([\s\S]*?)(?=\.(PARAMETER|EXAMPLE|NOTES|OUTPUTS|SYNOPSIS|#>))') {
        $metadata.Description = $matches[1].Trim()
    }

    # Extract parameters from comment-based help
    $paramMatches = [regex]::Matches($scriptContent, '\.PARAMETER\s+(\w+)([\s\S]*?)(?=\.(PARAMETER|EXAMPLE|NOTES|OUTPUTS|SYNOPSIS|#>))')
    foreach ($match in $paramMatches) {
        $paramName = $match.Groups[1].Value
        $paramDescription = $match.Groups[2].Value.Trim()

        $metadata.Parameters += @{
            Name        = $paramName
            Description = $paramDescription
            Type        = $null
            Required    = $false
            Default     = $null
        }
    }

    # Extract examples
    $exampleMatches = [regex]::Matches($scriptContent, '\.EXAMPLE([\s\S]*?)(?=\n\s*\.(PARAMETER|EXAMPLE|NOTES|OUTPUTS|SYNOPSIS|DESCRIPTION|INPUTS|LINK|COMPONENT|ROLE|FUNCTIONALITY|FORWARDHELPCATEGORY|FORWARDHELPTARGETNAME|REMOTEHELPRUNSPACE|EXTERNALHELP)|#>)')
    foreach ($match in $exampleMatches) {
        $exampleText = $match.Groups[1].Value
        # Remove leading newline/whitespace line if present
        $exampleText = $exampleText -replace '^\s*\r?\n', ''
        if (-not [string]::IsNullOrWhiteSpace($exampleText)) {
            $metadata.Examples += $exampleText
        }
    }

    # Extract outputs
    if ($scriptContent -match '\.OUTPUTS([\s\S]*?)(?=\.(PARAMETER|EXAMPLE|NOTES|SYNOPSIS|DESCRIPTION|#>))') {
        # Remove leading/trailing newlines but preserve indentation structure
        $outputText = $matches[1] -replace '^\r?\n', '' -replace '\r?\n\s*$', ''
        $metadata.Outputs = $outputText
    }

    # Extract parameter details from param block
    $paramBlock = $scriptAst.ParamBlock
    if ($paramBlock) {
        foreach ($param in $paramBlock.Parameters) {
            $paramName = $param.Name.VariablePath.UserPath

            # Find matching parameter in metadata
            $existingParam = $metadata.Parameters | Where-Object { $_.Name -eq $paramName }

            if ($existingParam) {
                # Update with AST information
                $existingParam.Type = $param.StaticType.Name
                $existingParam.Required = $param.Attributes.NamedArguments |
                    Where-Object { $_.ArgumentName -eq 'Mandatory' -and $_.Argument.Value -eq $true } |
                    Measure-Object | Select-Object -ExpandProperty Count

                if ($param.DefaultValue) {
                    $existingParam.Default = $param.DefaultValue.Extent.Text
                }
            } else {
                # Add parameter not documented in help
                $metadata.Parameters += @{
                    Name        = $paramName
                    Description = '{{ Fill in the Description }}'
                    Type        = $param.StaticType.Name
                    Required    = ($param.Attributes.NamedArguments |
                            Where-Object { $_.ArgumentName -eq 'Mandatory' -and $_.Argument.Value -eq $true } |
                            Measure-Object | Select-Object -ExpandProperty Count) -gt 0
                    Default     = if ($param.DefaultValue) { $param.DefaultValue.Extent.Text } else { $null }
                }
            }
        }
    }

    # Extract required modules from #Requires statements
    if ($scriptContent -match '#Requires\s+-Modules?\s+(.+)') {
        $metadata.RequiredModules = $matches[1] -split ',\s*' | ForEach-Object { $_.Trim() }
    }

    # Also check for modules imported in the script
    $importMatches = [regex]::Matches($scriptContent, 'Import-Module\s+[''"]?([^\s''"]+)[''"]?')
    foreach ($match in $importMatches) {
        $moduleName = $match.Groups[1].Value
        # Skip variable references
        if ($moduleName -notmatch '^\$' -and $moduleName -notin $metadata.RequiredModules) {
            $metadata.RequiredModules += $moduleName
        }
    }

    # Check if script supports ShouldProcess
    if ($scriptContent -match '\[CmdletBinding\([^\)]*SupportsShouldProcess[^\)]*\)\]') {
        $metadata.SupportsShouldProcess = $true
    }

    # Check if script has CmdletBinding attribute
    if ($scriptContent -match '\[CmdletBinding[\(\[]') {
        $metadata.HasCmdletBinding = $true
    }

    return $metadata
}

function Initialize-ReadMe {
    <#
    .SYNOPSIS
        Initializes the README content with a header and basic structure.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string] $ScriptName,

        [Parameter(Mandatory)]
        [object] $Metadata,

        [Parameter(Mandatory)]
        [string] $ScriptPath
    )

    $readMeContent = @()

    # Generate title based on parent folder name
    $parentFolder = Split-Path -Path $ScriptPath -Parent | Split-Path -Leaf

    # Format title: capitalize first letter, replace hyphens with spaces, capitalize each word
    $titleWords = $parentFolder -split '-' | ForEach-Object {
        $_.Substring(0, 1).ToUpper() + $_.Substring(1).ToLower()
    }
    $title = $titleWords -join ' '

    # Build relative path from repository root (find 'src' in the path and remove it)
    $fullPath = Resolve-Path -Path $ScriptPath
    if ($fullPath -match '\\src\\(.+)$') {
        $relativePath = $matches[1] -replace '\\', '\'
    } else {
        # Fallback: use last 3 segments of path
        $pathSegments = $fullPath -split '\\'
        $relativePath = ($pathSegments[-3..-1] -join '\')
    }

    # Title with path (add omit from toc to prevent it from being in ToC during manual edits)
    $readMeContent += '<!-- markdownlint-disable no-duplicate-heading -->'
    $readMeContent += '<!-- omit from toc -->'
    $readMeContent += "# $title ``[$relativePath]``"
    $readMeContent += ''

    # Add badges if available
    $badges = @()
    if ($Metadata.PSScriptInfo.Version) {
        $badges += "![Version](https://img.shields.io/badge/script%20version-$($Metadata.PSScriptInfo.Version)-blue)"
    }

    # License badge - use explicit LICENSE field or try to infer from repository LICENSE file
    $license = $null
    if ($Metadata.PSScriptInfo.License) {
        $license = $Metadata.PSScriptInfo.License
    } elseif ($Metadata.PSScriptInfo.LicenseUri) {
        # Try to find LICENSE file in repository root
        $repoRoot = $ScriptPath
        while ($repoRoot -and -not (Test-Path (Join-Path $repoRoot '.git'))) {
            $repoRoot = Split-Path -Path $repoRoot -Parent
        }
        if ($repoRoot) {
            $licenseFile = Join-Path $repoRoot 'LICENSE'
            if (Test-Path $licenseFile) {
                $licenseContent = Get-Content -Path $licenseFile -First 1
                if ($licenseContent -match '(MIT|Apache|GPL|BSD|ISC|MPL)') {
                    $license = $matches[1]
                }
            }
        }
    }

    if ($license) {
        $licenseBadge = "![License](https://img.shields.io/badge/license-$license-purple)"
        # Wrap badge in link if LicenseUri is available
        if ($Metadata.PSScriptInfo.LicenseUri) {
            $licenseBadge = "[$licenseBadge]($($Metadata.PSScriptInfo.LicenseUri))"
        }
        $badges += $licenseBadge
    }

    if ($badges.Count -gt 0) {
        $readMeContent += ($badges -join ' ')
    }

    # Add synopsis
    if ($Metadata.Synopsis) {
        $readMeContent += ''
        $readMeContent += $Metadata.Synopsis
    }

    $readMeContent += ''

    return $readMeContent
}

function Set-DescriptionSection {
    <#
    .SYNOPSIS
        Creates or updates the Description section.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [object[]] $ReadMeContent,

        [Parameter(Mandatory)]
        [object] $Metadata
    )

    $newContent = @()
    $newContent += '## DESCRIPTION'
    $newContent += ''

    if ($Metadata.Description) {
        # Process description lines - trim leading indentation while preserving structure
        $descLines = $Metadata.Description -split '\r?\n'

        # Find minimum indentation (excluding empty lines)
        $minIndent = 999
        foreach ($line in $descLines) {
            if ($line.Trim()) {
                if ($line -match '^(\s*)') {
                    $leadingSpaces = $matches[1].Length
                    if ($leadingSpaces -lt $minIndent) {
                        $minIndent = $leadingSpaces
                    }
                }
            }
        }
        if ($minIndent -eq 999) { $minIndent = 0 }

        # Process each line: remove common indentation, preserve empty lines and trailing spaces
        foreach ($line in $descLines) {
            if (-not $line.Trim()) {
                # Empty line - preserve it
                $newContent += ''
            } elseif ($minIndent -gt 0 -and $line.Length -ge $minIndent) {
                # Remove common leading indentation but preserve trailing spaces
                $newContent += $line.Substring($minIndent)
            } else {
                # No common indentation to remove, or line is shorter than minIndent
                $newContent += $line.TrimStart()
            }
        }
    } else {
        $newContent += '{{ Fill in the Description }}'
    }

    $newContent += ''

    return Merge-FileWithNewContent -OldContent $ReadMeContent -NewContent $newContent -SectionStartIdentifier '## DESCRIPTION' -ContentType 'nextH2'
}

function Set-ParametersSection {
    <#
    .SYNOPSIS
        Creates or updates the Parameters section.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [object[]] $ReadMeContent,

        [Parameter(Mandatory)]
        [object] $Metadata
    )

    if ($Metadata.Parameters.Count -eq 0) {
        return $ReadMeContent
    }

    $newContent = @()
    $newContent += '## PARAMETERS'
    $newContent += ''
    $newContent += '| Parameter | Type | Required | Default | Description |'
    $newContent += '| :-- | :-- | :-- | :-- | :-- |'

    # Sort parameters: required first, then alphabetically
    $sortedParams = $Metadata.Parameters | Sort-Object {
        if ($_.Required) { "0_$($_.Name)" } else { "1_$($_.Name)" }
    }

    foreach ($param in $sortedParams) {
        $required = if ($param.Required) { 'Yes' } else { 'No' }
        $type = if ($param.Type) {
            if ($param.Type -eq 'SwitchParameter') { 'Switch' } else { $param.Type }
        } else {
            'Object'
        }

        # Format default value - handle hashtable specially
        if ($param.Default) {
            if ($param.Default -match '^@\{(.+)\}$') {
                # Format hashtable with <br /> tags (with spaces for proper HTML rendering)
                $hashtableContent = $matches[1].Trim()
                # Split by semicolon, trim spaces around '=', and wrap each key-value pair in backticks
                $pairs = $hashtableContent -split '\s*;\s*' | ForEach-Object {
                    $pair = $_.Trim() -replace '\s*=\s*', '='
                    "``$pair``"
                }
                # Join with <br /> (with spaces)
                $default = "``@{`` <br /> " + ($pairs -join ' <br /> ') + " <br /> ``}``"
            } else {
                $default = "``$($param.Default)``"
            }
        } else {
            $default = '-'
        }

        # Format description - preserve line breaks and trim leading indentation
        if ($param.Description) {
            $descLines = $param.Description -split '\r?\n'
            # Find minimum indentation (excluding empty lines)
            $minIndent = 999
            foreach ($line in $descLines) {
                if ($line.Trim()) {
                    if ($line -match '^(\s*)') {
                        $leadingSpaces = $matches[1].Length
                        if ($leadingSpaces -lt $minIndent) {
                            $minIndent = $leadingSpaces
                        }
                    }
                }
            }
            if ($minIndent -eq 999) { $minIndent = 0 }

            # Process each line: remove common indentation, trim whitespace
            $processedLines = $descLines | ForEach-Object {
                if (-not $_.Trim()) {
                    # Empty line - skip it
                    $null
                } else {
                    # Remove common leading indentation and trim
                    if ($minIndent -gt 0 -and $_.Length -ge $minIndent) {
                        $_.Substring($minIndent).Trim()
                    } else {
                        $_.Trim()
                    }
                }
            } | Where-Object { $_ }  # Filter out nulls

            # Join lines with <br> tag to keep them in a single table cell
            $description = $processedLines -join ' <br> '
        } else {
            $description = ''
        }

        $newContent += "| ``$($param.Name)`` | ``$type`` | $required | $default | $description |"
    }

    $newContent += ''

    return Merge-FileWithNewContent -OldContent $ReadMeContent -NewContent $newContent -SectionStartIdentifier '## PARAMETERS' -ContentType 'nextH2'
}

function Set-ParameterSetsSection {
    <#
    .SYNOPSIS
        Creates or updates the Syntax section with parameter sets.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [object[]] $ReadMeContent,

        [Parameter(Mandatory)]
        [string] $ScriptPath,

        [Parameter(Mandatory)]
        [object] $Metadata
    )

    # Parse script to extract parameter sets
    $scriptContent = Get-Content -Path $ScriptPath -Raw
    $scriptAst = [System.Management.Automation.Language.Parser]::ParseInput($scriptContent, [ref]$null, [ref]$null)

    $paramBlock = $scriptAst.ParamBlock
    if (-not $paramBlock) {
        return $ReadMeContent
    }

    # Get script/function name
    $scriptName = Split-Path -Path $ScriptPath -LeafBase

    # Collect parameter set information with full details
    $parameterSets = @{}
    $defaultParameterSet = $null
    $parameterDetails = @{}
    $parameterOrder = @()  # Track original parameter order

    # Check CmdletBinding for DefaultParameterSetName
    if ($scriptContent -match '\[CmdletBinding\([^\)]*DefaultParameterSetName\s*=\s*[''"]([^''"]+)[''"]') {
        $defaultParameterSet = $matches[1]
    }

    # Collect full parameter details and preserve order
    foreach ($param in $paramBlock.Parameters) {
        $paramName = $param.Name.VariablePath.UserPath
        $paramType = $param.StaticType.Name

        # Track original order
        if ($paramName -notin $parameterOrder) {
            $parameterOrder += $paramName
        }

        $parameterDetails[$paramName] = @{
            Type    = $paramType
            Default = if ($param.DefaultValue) { $param.DefaultValue.Extent.Text } else { $null }
        }

        # Find ParameterSet attributes
        foreach ($attribute in $param.Attributes) {
            if ($attribute.TypeName.Name -eq 'Parameter') {
                $setName = '__AllParameterSets'  # Default set name

                foreach ($namedArg in $attribute.NamedArguments) {
                    if ($namedArg.ArgumentName -eq 'ParameterSetName') {
                        $setName = $namedArg.Argument.Value
                        break
                    }
                }

                if (-not $parameterSets.ContainsKey($setName)) {
                    $parameterSets[$setName] = @()
                }

                # Check if parameter is mandatory in this set
                $isMandatory = $false
                foreach ($namedArg in $attribute.NamedArguments) {
                    if ($namedArg.ArgumentName -eq 'Mandatory' -and $namedArg.Argument.Value -eq $true) {
                        $isMandatory = $true
                        break
                    }
                }

                # Check for ValueFromPipeline
                $valueFromPipeline = $false
                foreach ($namedArg in $attribute.NamedArguments) {
                    if ($namedArg.ArgumentName -eq 'ValueFromPipeline' -and $namedArg.Argument.Value -eq $true) {
                        $valueFromPipeline = $true
                        break
                    }
                }

                $parameterSets[$setName] += @{
                    Name              = $paramName
                    Mandatory         = $isMandatory
                    Type              = $paramType
                    ValueFromPipeline = $valueFromPipeline
                }
            }
        }
    }

    # If only __AllParameterSets exists, no need for this section
    if ($parameterSets.Count -eq 1 -and $parameterSets.ContainsKey('__AllParameterSets')) {
        return $ReadMeContent
    }

    # Store common parameters that apply to all sets
    $commonParams = @()
    if ($parameterSets.ContainsKey('__AllParameterSets')) {
        $commonParams = $parameterSets['__AllParameterSets']
    }

    # If there are multiple parameter sets, exclude __AllParameterSets from being shown as separate section
    if ($parameterSets.Count -gt 1 -and $parameterSets.ContainsKey('__AllParameterSets')) {
        $parameterSets.Remove('__AllParameterSets')
    }

    # Build the SYNTAX section
    $newContent = @()
    $newContent += '## SYNTAX'
    $newContent += ''

    # Sort parameter sets: default first, then alphabetically
    $sortedSets = $parameterSets.Keys | Sort-Object {
        if ($_ -eq $defaultParameterSet) { "0_$_" }
        else { "1_$_" }
    }

    foreach ($setName in $sortedSets) {
        $newContent += "### $setName"
        $newContent += ''
        $newContent += '```text'

        # Build syntax string
        $syntaxLine = $scriptName

        # Get parameters for this set, preserving original order
        $setParams = $parameterSets[$setName]
        $orderedParams = @()

        # Sort by original order from param block
        foreach ($paramName in $parameterOrder) {
            # Check if parameter is in this specific set
            $param = $setParams | Where-Object { $_.Name -eq $paramName }
            if ($param) {
                $orderedParams += $param
            }
            # Also check if parameter is in common parameters (available to all sets)
            else {
                $commonParam = $commonParams | Where-Object { $_.Name -eq $paramName }
                if ($commonParam) {
                    $orderedParams += $commonParam
                }
            }
        }

        foreach ($param in $orderedParams) {
            $paramName = $param.Name
            $paramType = $param.Type.ToLower()

            # Format parameter with type
            if ($paramType -eq 'switchparameter') {
                $paramSyntax = "[-$paramName]"
            } else {
                if ($param.Mandatory) {
                    $paramSyntax = "[-$paramName] <$paramType>"
                } else {
                    $paramSyntax = "[[-$paramName] <$paramType>]"
                }
            }

            $syntaxLine += " $paramSyntax"
        }

        # Add CommonParameters if script has CmdletBinding
        if ($Metadata.HasCmdletBinding) {
            $syntaxLine += ' [<CommonParameters>]'
        }

        $newContent += $syntaxLine
        $newContent += '```'
        $newContent += ''
    }

    return Merge-FileWithNewContent -OldContent $ReadMeContent -NewContent $newContent -SectionStartIdentifier '## SYNTAX' -ContentType 'nextH2'
}

function Set-ExamplesSection {
    <#
    .SYNOPSIS
        Creates or updates the Examples section.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [object[]] $ReadMeContent,

        [Parameter(Mandatory)]
        [object] $Metadata
    )

    if ($Metadata.Examples.Count -eq 0) {
        return $ReadMeContent
    }

    $newContent = @()
    $newContent += '## EXAMPLES'
    $newContent += ''

    $exampleNumber = 1
    foreach ($example in $Metadata.Examples) {
        $newContent += "### Example $exampleNumber"
        $newContent += ''
        $newContent += '#### PowerShell'
        $newContent += ''
        $newContent += '```powershell'
        # Process each line to ensure descriptive text is commented and normalize indentation
        $lines = $example -split '\r?\n'

        # Remove leading/trailing empty lines
        while ($lines.Count -gt 0 -and -not $lines[0].Trim()) {
            $lines = $lines[1..($lines.Count - 1)]
        }
        while ($lines.Count -gt 0 -and -not $lines[-1].Trim()) {
            $lines = $lines[0..($lines.Count - 2)]
        }

        # Find minimum indentation (excluding empty lines)
        $minIndent = 999
        foreach ($line in $lines) {
            if ($line.Trim()) {
                # Non-empty line
                if ($line -match '^(\s*)') {
                    $leadingSpaces = $matches[1].Length
                    if ($leadingSpaces -lt $minIndent) {
                        $minIndent = $leadingSpaces
                    }
                }
            }
        }

        if ($minIndent -eq 999) { $minIndent = 0 }

        # Separate code lines from description lines
        $codeLines = @()
        $descriptionLines = @()

        # Process lines with normalized indentation
        foreach ($line in $lines) {
            if (-not $line.Trim()) {
                # Preserve empty lines in code
                $codeLines += ''
                continue
            }

            # Remove the common leading indentation but preserve relative indentation
            $normalizedLine = if ($minIndent -gt 0 -and $line.Length -ge $minIndent) {
                $line.Substring($minIndent)
            } else {
                $line
            }

            $trimmedLine = $normalizedLine.TrimStart()
            # If line doesn't start with common PowerShell patterns and isn't empty, it's a description
            $startsWithQuote = $trimmedLine.StartsWith("'") -or $trimmedLine.StartsWith('"')
            $isDescription = $trimmedLine -and
            $trimmedLine -notmatch '^[\$#@]' -and
            $trimmedLine -notmatch '^\w+\s*=' -and
            -not $startsWithQuote -and
            $trimmedLine -notmatch '^\.|^\[|^\{|^\}|^\)|^\('

            if ($isDescription) {
                # Store as description line
                $descriptionLines += $trimmedLine
            } else {
                $codeLines += $normalizedLine
            }
        }

        # Remove trailing empty lines from code
        while ($codeLines.Count -gt 0 -and -not $codeLines[-1].Trim()) {
            $codeLines = $codeLines[0..($codeLines.Count - 2)]
        }

        # Add code lines to content
        foreach ($codeLine in $codeLines) {
            $newContent += $codeLine
        }
        $newContent += '```'
        $newContent += ''

        # Add description lines after code block
        if ($descriptionLines.Count -gt 0) {
            foreach ($descLine in $descriptionLines) {
                $newContent += $descLine
            }
            $newContent += ''
        }

        $exampleNumber++
    }

    return Merge-FileWithNewContent -OldContent $ReadMeContent -NewContent $newContent -SectionStartIdentifier '## EXAMPLES' -ContentType 'nextH2'
}

function Set-OutputsSection {
    <#
    .SYNOPSIS
        Creates or updates the Outputs section.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [object[]] $ReadMeContent,

        [Parameter(Mandatory)]
        [object] $Metadata
    )

    $newContent = @()
    $newContent += '## OUTPUTS'
    $newContent += ''

    if ($Metadata.Outputs) {
        $newContent += '```text'

        # Process output lines - trim leading indentation while preserving structure
        $outputLines = $Metadata.Outputs -split '\r?\n'

        # Find minimum indentation (excluding empty lines)
        $minIndent = 999
        foreach ($line in $outputLines) {
            if ($line.Trim()) {
                if ($line -match '^(\s*)') {
                    $leadingSpaces = $matches[1].Length
                    if ($leadingSpaces -lt $minIndent) {
                        $minIndent = $leadingSpaces
                    }
                }
            }
        }
        if ($minIndent -eq 999) { $minIndent = 0 }

        # Process each line: remove common indentation, preserve empty lines and trailing spaces
        foreach ($line in $outputLines) {
            if (-not $line.Trim()) {
                # Empty line - preserve it
                $newContent += ''
            } elseif ($minIndent -gt 0 -and $line.Length -ge $minIndent) {
                # Remove common leading indentation but preserve trailing spaces
                $newContent += $line.Substring($minIndent)
            } else {
                # No common indentation to remove, or line is shorter than minIndent
                $newContent += $line.TrimStart()
            }
        }

        $newContent += '```'
    } else {
        # Try to detect OutputType attribute
        $scriptContent = Get-Content -Path $ScriptFilePath -Raw
        if ($scriptContent -match '\[OutputType\(\[(.+?)\]\)\]') {
            $newContent += "### ``$($matches[1])``"
        } else {
            $newContent += '{{ Fill in the Outputs }}'
        }
    }

    $newContent += ''

    return Merge-FileWithNewContent -OldContent $ReadMeContent -NewContent $newContent -SectionStartIdentifier '## OUTPUTS' -ContentType 'nextH2'
}

function Set-SupportSection {
    <#
    .SYNOPSIS
        Generates or updates the Support section with SupportsShouldProcess and CommonParameters subsections.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [object[]] $ReadMeContent,

        [Parameter(Mandatory)]
        [hashtable] $Metadata
    )

    # Only create Support section if there's content to add
    if (-not $Metadata.SupportsShouldProcess -and -not $Metadata.HasCmdletBinding) {
        return $ReadMeContent
    }

    $newContent = @()
    $newContent += '## SUPPORT'
    $newContent += ''

    # Add CommonParameters subsection if script has CmdletBinding, use multi-line for better readability
    if ($Metadata.HasCmdletBinding) {
        $newContent += '### CommonParameters'
        $newContent += ''
        $newContent += 'This cmdlet supports the common parameters: `-Debug`, `-ErrorAction`, `-ErrorVariable`,  '
        $newContent += '`-InformationAction`, `-InformationVariable`, `-OutBuffer`, `-OutVariable`, `-PipelineVariable`,  '
        $newContent += '`-ProgressAction`, `-Verbose`, `-WarningAction`, and `-WarningVariable`.  '
        $newContent += 'For more information, see [about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).'
        $newContent += ''
    }

    # Add SupportsShouldProcess subsection if applicable
    if ($Metadata.SupportsShouldProcess) {
        $newContent += '### SupportsShouldProcess'
        $newContent += ''
        $newContent += 'This script supports the `-WhatIf` and `-Confirm` parameters for safe execution:'
        $newContent += ''
        $newContent += '- **`-WhatIf`**: Shows what would happen if the script runs without actually making any changes.'
        $newContent += '- **`-Confirm`**: Prompts for confirmation before performing each action.'
        $newContent += ''
    }

    return Merge-FileWithNewContent -OldContent $ReadMeContent -NewContent $newContent -SectionStartIdentifier '## SUPPORT' -ContentType 'nextH2'
}

function Set-DependenciesSection {
    <#
    .SYNOPSIS
        Creates or updates the Dependencies section.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [object[]] $ReadMeContent,

        [Parameter(Mandatory)]
        [object] $Metadata
    )

    $allModules = @()

    # Combine all module sources
    if ($Metadata.RequiredModules.Count -gt 0) {
        $allModules += $Metadata.RequiredModules
    }

    if ($Metadata.PSScriptInfo.ExternalModuleDependencies) {
        $allModules += $Metadata.PSScriptInfo.ExternalModuleDependencies
    }

    # Remove duplicates and sort
    $allModules = $allModules | Select-Object -Unique | Sort-Object

    if ($allModules.Count -eq 0) {
        return $ReadMeContent
    }

    $newContent = @()
    $newContent += '## DEPENDENCIES'
    $newContent += ''
    $newContent += 'This script requires the following PowerShell modules:'
    $newContent += ''

    foreach ($module in $allModules) {
        $newContent += "- ``$module``"
    }

    $newContent += ''

    return Merge-FileWithNewContent -OldContent $ReadMeContent -NewContent $newContent -SectionStartIdentifier '## DEPENDENCIES' -ContentType 'nextH2'
}

function Set-ResourcesSection {
    <#
    .SYNOPSIS
        Creates or updates the Resources section with subsections for Modules, Shared, and Tests.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [object[]] $ReadMeContent,

        [Parameter(Mandatory)]
        [string] $ScriptPath
    )

    $scriptDir = Split-Path -Path $ScriptPath -Parent
    $scriptName = Split-Path -Path $ScriptPath -Leaf
    $scriptContent = Get-Content -Path $ScriptPath -Raw

    # Collect all resources
    $hasDeploy = $false
    $hasModules = $false
    $hasShared = $false
    $hasTests = $false

    $deployScript = $null
    $moduleScripts = @()
    $sharedResources = @{}
    $testScripts = @()

    # Check for deploy script
    $deployScriptPath = Join-Path -Path $scriptDir -ChildPath 'deploy.ps1'
    if ((Test-Path -Path $deployScriptPath) -and ((Split-Path -Path $deployScriptPath -Leaf) -ne $scriptName)) {
        $deployScript = @{
            Name = 'deploy'
            Path = 'deploy.ps1'
        }
        $hasDeploy = $true
    }

    # Check for modules
    $modulesPath = Join-Path -Path $scriptDir -ChildPath 'modules'
    if (Test-Path -Path $modulesPath) {
        $scripts = Get-ChildItem -Path $modulesPath -Filter '*.ps1' -File -Recurse
        foreach ($script in $scripts) {
            $relativePath = $script.FullName.Replace($scriptDir, '').TrimStart('\').TrimStart('/')
            $moduleScripts += @{
                Name = $script.Name
                Path = $relativePath -replace '\\', '/'
            }
        }
    }

    $hasModules = $moduleScripts.Count -gt 0

    # Check for shared resources in main script
    $pattern = "['\`"](\.\.\\shared\\[^'\`"]+)['\`"]"
    $matchesFound = [regex]::Matches($scriptContent, $pattern)

    foreach ($match in $matchesFound) {
        $sharedPath = $match.Groups[1].Value
        $normalizedPath = $sharedPath -replace '\\', '/'

        if ($normalizedPath -match 'shared/([^/]+)/') {
            $resourceName = $Matches[1]
            $resourcePath = "../shared/$resourceName"

            if (-not $sharedResources.ContainsKey($resourceName)) {
                $sharedResources[$resourceName] = $resourcePath
            }
        }
    }

    # Also check module files for shared resource references
    if ($hasModules) {
        foreach ($moduleScript in $moduleScripts) {
            $moduleFullPath = Join-Path -Path $scriptDir -ChildPath ($moduleScript.Path -replace '/', '\')
            if (Test-Path -Path $moduleFullPath) {
                $moduleContent = Get-Content -Path $moduleFullPath -Raw
                # Pattern for deeper paths like ..\..\shared\
                $deepPattern = "['\`"](\.\.\\\.\.\\shared\\[^'\`"]+)['\`"]"
                $deepMatches = [regex]::Matches($moduleContent, $deepPattern)

                foreach ($match in $deepMatches) {
                    $sharedPath = $match.Groups[1].Value
                    $normalizedPath = $sharedPath -replace '\\', '/'

                    if ($normalizedPath -match 'shared/([^/]+)/') {
                        $resourceName = $Matches[1]
                        $resourcePath = "../shared/$resourceName"

                        if (-not $sharedResources.ContainsKey($resourceName)) {
                            $sharedResources[$resourceName] = $resourcePath
                        }
                    }
                }
            }
        }
    }

    $hasShared = $sharedResources.Count -gt 0

    # Check for tests
    $testsPath = Join-Path -Path $scriptDir -ChildPath 'tests'
    if (Test-Path -Path $testsPath) {
        $scripts = Get-ChildItem -Path $testsPath -Filter '*.ps1' -File -Recurse
        foreach ($script in $scripts) {
            $relativePath = $script.FullName.Replace($scriptDir, '').TrimStart('\').TrimStart('/')
            $testScripts += @{
                Name = $script.Name
                Path = $relativePath -replace '\\', '/'
            }
        }
    }

    $hasTests = $testScripts.Count -gt 0

    # If no resources at all, return unchanged
    if (-not $hasDeploy -and -not $hasModules -and -not $hasShared -and -not $hasTests) {
        return $ReadMeContent
    }

    # Build the Resources section with subsections
    $newContent = @()
    $newContent += '## RESOURCES'
    $newContent += ''

    # Deploy script directly under Resources (not in a subsection)
    if ($hasDeploy) {
        $newContent += "- [$($deployScript.Name)]($($deployScript.Path))"
        $newContent += ''
    }

    # Modules subsection
    if ($hasModules) {
        $newContent += '### Modules'
        $newContent += ''
        foreach ($script in ($moduleScripts | Sort-Object -Property Path)) {
            $displayName = $script.Name -replace '\.ps1$', ''
            # Link to folder if script is main.ps1, otherwise link to the file
            if ($script.Name -eq 'main.ps1') {
                $folderPath = $script.Path -replace '/[^/]+$', ''
                $newContent += "- [$displayName]($folderPath)"
            } else {
                $newContent += "- [$displayName]($($script.Path))"
            }
        }
        $newContent += ''
    }

    # Shared subsection
    if ($hasShared) {
        $newContent += '### Shared'
        $newContent += ''
        foreach ($resourceName in ($sharedResources.Keys | Sort-Object)) {
            $resourcePath = $sharedResources[$resourceName]
            $newContent += "- [$resourceName]($resourcePath)"
        }
        $newContent += ''
    }

    # Tests subsection
    if ($hasTests) {
        $newContent += '### Tests'
        $newContent += ''
        foreach ($script in ($testScripts | Sort-Object -Property Path)) {
            # Extract test case name from path (e.g.: 'tests/e2e/default' -> 'default')
            if ($script.Path -match '/([^/]+)/[^/]+\.ps1$') {
                $displayName = $Matches[1]
            } else {
                $displayName = $script.Name -replace '\.ps1$', ''
            }
            # Link to folder if script is main.tests.ps1, otherwise link to the file
            if ($script.Name -eq 'main.tests.ps1') {
                $folderPath = $script.Path -replace '/[^/]+$', ''
                $newContent += "- [$displayName]($folderPath)"
            } else {
                $newContent += "- [$displayName]($($script.Path))"
            }
        }
        $newContent += ''
    }

    return Merge-FileWithNewContent -OldContent $ReadMeContent -NewContent $newContent -SectionStartIdentifier '## RESOURCES' -ContentType 'nextH2'
}

function Set-TableOfContent {
    <#
    .SYNOPSIS
        Creates or updates the table of contents based on sections present in the README.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [object[]] $ReadMeContent
    )

    $sections = @()

    foreach ($line in $ReadMeContent) {
        if ($line -match '^## (.+)$' -and $matches[1] -ne 'NAVIGATION') {
            $sectionName = $matches[1]
            $anchor = $sectionName.ToLower() -replace '\s+', '-' -replace '[^a-z0-9-]', ''
            $sections += @{
                Name   = $sectionName
                Anchor = $anchor
            }
        }
    }

    if ($sections.Count -eq 0) {
        return $ReadMeContent
    }

    $newContent = @()
    $newContent += '<!-- omit from toc -->'
    $newContent += '## NAVIGATION'
    $newContent += ''

    foreach ($section in $sections) {
        $newContent += "- [$($section.Name)](#$($section.Anchor))"
    }

    $newContent += ''

    return Merge-FileWithNewContent -OldContent $ReadMeContent -NewContent $newContent -SectionStartIdentifier '<!-- omit from toc -->' -ContentType 'nextH2'
}

function Merge-FileWithNewContent {
    <#
    .SYNOPSIS
        Merges new content into existing README content by replacing a specific section.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [object[]] $OldContent,

        [Parameter(Mandatory)]
        [object[]] $NewContent,

        [Parameter(Mandatory)]
        [string] $SectionStartIdentifier,

        [Parameter(Mandatory = $false)]
        [ValidateSet('nextH2', 'none')]
        [string] $ContentType = 'nextH2'
    )

    $startIndex = 0
    while (-not ($OldContent[$startIndex] -eq $SectionStartIdentifier) -and -not ($startIndex -ge $OldContent.Count - 1)) {
        $startIndex++
    }

    if ($startIndex -eq $OldContent.Count - 1 -and $OldContent[$startIndex] -ne $SectionStartIdentifier) {
        # Section doesn't exist, append at the end
        $startContent = $OldContent
        if (-not [String]::IsNullOrEmpty($OldContent[$startIndex])) {
            $startContent += @('')
        }
        $endContent = @()
    } else {
        # Section exists, replace it
        $startContent = $OldContent[0..($startIndex - 1)]

        if ($ContentType -eq 'nextH2') {
            # Find the next H2 section
            $endIndex = $startIndex + 1
            while (-not $OldContent[$endIndex].StartsWith('## ') -and -not (($endIndex + 1) -ge $OldContent.count)) {
                $endIndex++
            }

            if ($endIndex -ne $OldContent.Count - 1 -and $OldContent[$endIndex].StartsWith('## ')) {
                $endContent = $OldContent[$endIndex..($OldContent.Count - 1)]
            } else {
                $endContent = @()
            }
        } else {
            $endContent = @()
        }
    }

    # Build result
    $result = $startContent + $NewContent + $endContent
    return $result | Where-Object { $_ -ne $null }
}

#endregion

#region Main Process

<#
.PARAMETER ScriptFilePath
    Optional. The path to the PowerShell script to document. Defaults to the current directory.

.PARAMETER ReadMeFilePath
    Optional. The path to the README file. Defaults to 'README.md' in the same folder as the script.

.PARAMETER SectionsToRefresh
    Optional. The sections to update. By default refreshes all supported sections.
    Currently supports: 'Description', 'Parameters', 'Examples', 'Outputs', 'Dependencies', 'Navigation'

.EXAMPLE
    . src\utl\Set-PowerShellReadMe.ps1
    Set-PowerShellReadMe -ScriptFilePath 'c:\_git\az-devops-governance\src\res\connection\main.ps1'

    Generates or updates the README.md file for the specified PowerShell script.

.EXAMPLE
    . src\utl\Set-PowerShellReadMe.ps1
    Set-PowerShellReadMe -ScriptFilePath '.\main.ps1' -SectionsToRefresh @('Parameters', 'Examples')

    Updates only the Parameters and Examples sections in the README.

.NOTES
    Version: 1.0
    Author: Martin Swinkels
#>
function Set-PowerShellReadMe {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true)]
        [string] $ScriptFilePath,

        [Parameter(Mandatory = $false)]
        [string] $ReadMeFilePath = (Join-Path (Split-Path $ScriptFilePath -Parent) 'README.md'),

        [Parameter(Mandatory = $false)]
        [ValidateSet('Description', 'Navigation', 'Parameters', 'ParameterSets', 'Examples', 'Outputs', 'Support', 'Dependencies', 'Resources')]
        [string[]] $SectionsToRefresh = @(
            'Description'
            'Navigation'
            'Parameters'
            'ParameterSets'
            'Examples'
            'Outputs'
            'Support'
            'Dependencies'
            'Resources'
        )
    )

    begin {
        Write-Debug ('{0} entered' -f $MyInvocation.MyCommand)
    }

    process {
        try {
            # Validate input
            $ScriptFilePath = Resolve-Path -Path $ScriptFilePath -ErrorAction Stop

            if (-not (Test-Path $ScriptFilePath -PathType 'Leaf')) {
                throw "[$ScriptFilePath] is not a valid file path."
            }

            if ((Split-Path -Path $ScriptFilePath -Extension) -ne '.ps1') {
                throw "[$ScriptFilePath] is not a PowerShell script file."
            }

            Write-Verbose "Processing script: $ScriptFilePath"

            # Extract script metadata
            $metadata = Get-ScriptMetadata -ScriptPath $ScriptFilePath
            $scriptName = Split-Path -Path $ScriptFilePath -Leaf

            # Read existing README if it exists
            if (Test-Path $ReadMeFilePath) {
                $readMeContent = @(Get-Content -Path $ReadMeFilePath -Encoding utf8)
            } else {
                $readMeContent = @()
            }

            # Preserve Notes section if it exists
            $notes = @()
            if ($match = $readMeContent | Select-String -Pattern '^## (Notes|NOTES)$') {
                $startIndex = $match.LineNumber - 1
                $endIndex = $startIndex + 1

                while (-not (($endIndex + 1) -gt $readMeContent.count) -and $readMeContent[$endIndex] -notlike '## *') {
                    $endIndex++
                }

                $notes = $readMeContent[$startIndex..$endIndex]
                # Update header to CAPS
                $notes[0] = '## NOTES'
            }

            # Initialize README
            $readMeContent = Initialize-ReadMe -ScriptName $scriptName -Metadata $metadata -ScriptPath $ScriptFilePath

            # Build all sections first to determine what Navigation should contain
            $tempContent = $readMeContent

            # Update sections
            if ($SectionsToRefresh -contains 'Description') {
                $tempContent = Set-DescriptionSection -ReadMeContent $tempContent -Metadata $metadata
            }

            if ($SectionsToRefresh -contains 'ParameterSets') {
                $tempContent = Set-ParameterSetsSection -ReadMeContent $tempContent -ScriptPath $ScriptFilePath -Metadata $metadata
            }

            if ($SectionsToRefresh -contains 'Parameters') {
                $tempContent = Set-ParametersSection -ReadMeContent $tempContent -Metadata $metadata
            }

            if ($SectionsToRefresh -contains 'Examples') {
                $tempContent = Set-ExamplesSection -ReadMeContent $tempContent -Metadata $metadata
            }

            if ($SectionsToRefresh -contains 'Outputs') {
                $tempContent = Set-OutputsSection -ReadMeContent $tempContent -Metadata $metadata
            }

            if ($SectionsToRefresh -contains 'Support') {
                $tempContent = Set-SupportSection -ReadMeContent $tempContent -Metadata $metadata
            }

            if ($SectionsToRefresh -contains 'Dependencies') {
                $tempContent = Set-DependenciesSection -ReadMeContent $tempContent -Metadata $metadata
            }

            if ($SectionsToRefresh -contains 'Resources') {
                $tempContent = Set-ResourcesSection -ReadMeContent $tempContent -ScriptPath $ScriptFilePath
            }

            # Now generate Navigation at the top based on all sections
            if ($SectionsToRefresh -contains 'Navigation') {
                # Extract sections from temp content
                $sections = @()
                foreach ($line in $tempContent) {
                    if ($line -match '^## (.+)$' -and $matches[1] -ne 'Navigation') {
                        $sectionName = $matches[1]
                        $anchor = $sectionName.ToLower() -replace '\s+', '-' -replace '[^a-z0-9-]', ''
                        $sections += @{
                            Name   = $sectionName
                            Anchor = $anchor
                        }
                    }
                }

                if ($sections.Count -gt 0) {
                    # Add Notes to navigation if it exists
                    if ($notes.Count -gt 0) {
                        $sections += @{
                            Name   = 'NOTES'
                            Anchor = 'notes'
                        }
                    }

                    # Insert Navigation right after the title/synopsis section
                    $navContent = @()
                    $navContent += '<!-- omit from toc -->'
                    $navContent += '## NAVIGATION'
                    $navContent += ''
                    foreach ($section in $sections) {
                        $navContent += "- [$($section.Name)](#$($section.Anchor))"
                    }
                    $navContent += ''

                    # Find where to insert (after synopsis, before first ## section)
                    $insertIndex = 0
                    for ($i = 0; $i -lt $tempContent.Count; $i++) {
                        if ($tempContent[$i] -match '^## ') {
                            $insertIndex = $i
                            break
                        }
                    }

                    # Build final content with Navigation inserted
                    $readMeContent = $tempContent[0..($insertIndex - 1)] + $navContent + $tempContent[$insertIndex..($tempContent.Count - 1)]
                } else {
                    $readMeContent = $tempContent
                }
            } else {
                $readMeContent = $tempContent
            }

            # Restore Notes section
            if ($notes.Count -gt 0) {
                $readMeContent += @('')
                $readMeContent += $notes
            }

            # Write README file
            if (Test-Path $ReadMeFilePath) {
                if ($PSCmdlet.ShouldProcess("File in path [$ReadMeFilePath]", 'Overwrite')) {
                    Set-Content -Path $ReadMeFilePath -Value $readMeContent -Force -Encoding utf8
                }
                Write-Verbose "File [$ReadMeFilePath] updated"
            } else {
                if ($PSCmdlet.ShouldProcess("File in path [$ReadMeFilePath]", 'Create')) {
                    $null = New-Item -Path $ReadMeFilePath -Value ($readMeContent | Out-String) -Force
                }
                Write-Verbose "File [$ReadMeFilePath] created"
            }

            Write-Output "README generated successfully: $ReadMeFilePath"

        } catch {
            throw $_
        }
    }
    end {
        Write-Debug ('{0} exited' -f $MyInvocation.MyCommand)
    }
}

#endregion
