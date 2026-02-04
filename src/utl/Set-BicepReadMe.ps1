#requires -version 7.3

#region helper functions
function Initialize-ReadMe {
    <#
    .SYNOPSIS
        Initialize the readme file
    .DESCRIPTION
        Create the initial skeleton of the section headers, name & description.
    .NOTES
    .LINK
    .EXAMPLE
    #>
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $true,
            HelpMessage = 'Required. The path to the readme file to initialize')]
        [string]
        $ReadMeFilePath,

        [Parameter(
            Mandatory = $true,
            HelpMessage = 'Required. The full identifier of the module. For example: ''sql/managed-instance/administrator''')]
        [string]
        $FullModuleIdentifier,

        [Parameter(
            Mandatory = $true,
            HelpMessage = 'Mandatory. The template file content object to crawl data from')]
        [hashtable]
        $TemplateFileContent

    )

    begin {
        Write-Debug ('{0} entered' -f $MyInvocation.MyCommand)
    }

    process {
        try {

            $moduleName = $TemplateFileContent.metadata.name
            $moduleDescription = $TemplateFileContent.metadata.description

            # Reproduce identifier name from folder structure e.g. 'management' / 'management-group' / 'subscription'
            $rootIdentifierName, $parentIdentifierName, $childIdentifierName = $FullModuleIdentifier -split '[\/|\\]', 3

            # Format the identifier names
            $formattedRootIdentifierName = (Get-Culture).TextInfo.ToTitleCase(($rootIdentifierName -replace '[^0-9A-Z]', ' ')) -replace ' '
            $formattedParentIdentifierName = (Get-Culture).TextInfo.ToTitleCase(($parentIdentifierName -replace '[^0-9A-Z]', ' ')) -replace ' '
            $formattedChildIdentifierName = (Get-Culture).TextInfo.ToTitleCase(($childIdentifierName -replace '[^0-9A-Z]', ' ')) -replace ' '

            # Format the header type, e.g. 'Management/managementGroup/subscription'
            $headerType = ("$formattedRootIdentifierName/$($formattedParentIdentifierName -replace '^(.)',
            { $_.Value.ToLower() })/$($formattedChildIdentifierName -replace '^(.)',
            { $_.Value.ToLower() })" -replace 'Modules$', '').TrimEnd('/')

            $initialContent = @(
                '<!-- markdownlint-disable -->',
                '<!-- omit from toc -->',
                "# $($moduleName) ``[$($headerType)]``",
                '',
                "$($moduleDescription)",
                ''
                # '## Resource Types',
                # '',
                # '## Parameters',
                # '',
                # '## Outputs'
                # '',
                # '## Cross-referenced modules'
            ) | Where-Object { $null -ne $_ } # Filter null values
            $readMeFileContent = $initialContent

            return $readMeFileContent

        } catch {
            throw $_
        }
    }

    end {
        Write-Debug ('{0} exited' -f $MyInvocation.MyCommand)
    }
}
function Set-ResourceTypesSection {
    <#
    .SYNOPSIS
        Update the 'Resource Types' section of the given readme file
    .DESCRIPTION
    .NOTES
    .LINK
    .EXAMPLE
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'ResourceTypesToExclude', Justification = 'Variable used inside Where-Object block.')]
    param (
        [Parameter(
            Mandatory,
            HelpMessage = 'Mandatory. The template file content object to crawl data from')]
        [hashtable]
        $TemplateFileContent,

        [Parameter(
            Mandatory,
            HelpMessage = 'Mandatory. The readme file content object array to update')]
        [object[]]
        $ReadMeFileContent,

        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Optional. The identifier of the ''outputs'' section. Defaults to ''## Resource Types''')]
        [string]
        $SectionStartIdentifier = '## Resource Types',

        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Optional. The resource types to exclude from the list. Defaults to ''Microsoft.Resources/deployments''')]
        [string[]]
        $ResourceTypesToExclude = @(
            'Microsoft.Resources/deployments'
        )
    )

    $relevantResourceTypeObjects = Get-NestedResourceList $TemplateFileContent | Where-Object {
        $_.type -notin $ResourceTypesToExclude -and $_
    } | Select-Object 'Type', 'ApiVersion' -Unique | Sort-Object -Culture 'en-US' -Property 'Type'

    if (-not $relevantResourceTypeObjects) {
        # no resource types in the template
        $sectionContent = '_None_'
    } else {

        # Process content
        $sectionContent = [System.Collections.ArrayList]@(
            '| Resource Type | API Version |',
            '| :-- | :-- |'
        )

        $ProgressPreference = 'SilentlyContinue'
        $VerbosePreference = 'SilentlyContinue'

        foreach ($resourceTypeObject in $relevantResourceTypeObjects) {

            $ProviderNamespace, $ResourceType = $resourceTypeObject.Type -split '/', 2

            # Validate if Reference URL is working
            $TemplatesBaseUrl = 'https://learn.microsoft.com/en-us/azure/templates'
            $ResourceReferenceUrl = '{0}/{1}/{2}/{3}' -f $TemplatesBaseUrl, $ProviderNamespace, $resourceTypeObject.ApiVersion, $ResourceType

            if (-not (Test-Url $ResourceReferenceUrl)) {
                # Validate if Reference URL is working using the latest documented API version (with no API version in the URL)
                $ResourceReferenceUrl = '{0}/{1}/{2}' -f $TemplatesBaseUrl, $ProviderNamespace, $ResourceType
            }

            if (-not (Test-Url $ResourceReferenceUrl)) {
                # Check if the resource is a child resource
                if ($ResourceType.Split('/').length -gt 1) {
                    $ResourceReferenceUrl = '{0}/{1}/{2}' -f $TemplatesBaseUrl, $ProviderNamespace, $ResourceType.Split('/')[0]

                } else {
                    # Use the default Templates URL (Last resort)
                    $ResourceReferenceUrl = '{0}' -f $TemplatesBaseUrl
                }
            }

            $sectionContent += ('| `{0}` | [{1}]({2}) |' -f $resourceTypeObject.type, $resourceTypeObject.apiVersion, $ResourceReferenceUrl)
        }

        $ProgressPreference = 'Continue'
        $VerbosePreference = 'Continue'
    }
    # Build result
    if ($PSCmdlet.ShouldProcess('Original file with new resource type content', 'Merge')) {
        $updatedFileContent = Merge-FileWithNewContent -oldContent $ReadMeFileContent -newContent $sectionContent -SectionStartIdentifier $SectionStartIdentifier -contentType 'nextH2'
    }

    return $updatedFileContent

}
function Set-UsageExamplesSection {
    <#
    .SYNOPSIS
        Sorry, not implemented yet.

    .DESCRIPTION
        Generate 'Usage examples' for the ReadMe out of the parameter files currently used to test the template

    .PARAMETER ModuleRoot
        Mandatory. The file path to the module's root

    .PARAMETER FullModuleIdentifier
        Mandatory. The full identifier of the module (i.e., ProviderNamespace + ResourceType)

    .PARAMETER TemplateFileContent
        Mandatory. The template file content object to crawl data from

    .PARAMETER ReadMeFileContent
        Mandatory. The readme file content array to update

    .PARAMETER AddJson
        Optional. A switch to control whether or not to add a ARM-JSON-Parameter file example. Defaults to true.

    .PARAMETER AddBicep
        Optional. A switch to control whether or not to add a Bicep usage example. Defaults to true.

    .PARAMETER SectionStartIdentifier
        Optional. The identifier of the 'outputs' section. Defaults to '## Usage examples'

    .NOTES
    .LINK
    .EXAMPLE
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory = $true)]
        [string] $ModuleRoot,

        [Parameter(Mandatory = $true)]
        [string] $FullModuleIdentifier,

        [Parameter(Mandatory)]
        [hashtable] $TemplateFileContent,

        [Parameter(Mandatory = $true)]
        [object[]] $ReadMeFileContent,

        [Parameter(Mandatory = $false)]
        [bool] $AddJson = $true,

        [Parameter(Mandatory = $false)]
        [bool] $AddBicep = $true,

        [Parameter(Mandatory = $false)]
        [bool] $AddBicepParametersFile = $true,

        [Parameter(Mandatory = $false)]
        [bool] $UseLocalTargetLink = $true,

        [Parameter(Mandatory = $false)]
        [string] $SectionStartIdentifier = '## Usage examples'
    )

    begin {
        Write-Debug ('{0} entered' -f $MyInvocation.MyCommand)
    }

    process {
        try {

            $moduleIdentifier = (Split-Path $TemplateFilePath -Parent) -split '[\/|\\]iac[\/|\\](res|ptn|utl)[\/|\\]'
            $targetLink = ('{0}/{1}' -f $moduleIdentifier[1], $moduleIdentifier[2]) -replace '\\', '/'
            $targetVersion = '<version>'

            if ($UseLocalTargetLink) {
                $sectionContentTargetLink = '`iac/{0}/main.bicep`.' -f $targetLink
            } else {
                $sectionContentTargetLink = '`br/public:{0}:{1}`.' -f $targetLink, $targetVersion
            }

            $sectionContent = [System.Collections.ArrayList]@(
                "The following section provides usage examples for the module, which were used to validate and deploy the module successfully. For a full reference, please review the module's test folder in its repository.",
                '',
                '> **Note** <br>'
                '> Each example lists all the required parameters first, followed by the rest - each in alphabetical order.',
                '',
                '> **Note** <br>'
                ('> To reference the module, please use the following syntax {0}' -f $sectionContentTargetLink),
                ''
            )

            # Init values

            $specialConversionHash = @{
                'public-ip-addresses' = 'publicIPAddresses'
                'public-ip-prefixes'  = 'publicIPPrefixes'
            }

            # Get moduleName as $fullModuleIdentifier leaf
            $moduleName = $fullModuleIdentifier.Split('/')[1]
            if ($specialConversionHash.ContainsKey($moduleName)) {

                # Convert moduleName using specialConversionHash
                $moduleNameCamelCase = $specialConversionHash[$moduleName]
            } else {

                # Convert moduleName from kebab-case to camelCase
                $first, $rest = $moduleName -split '-', 2
                $moduleNameCamelCase = $first.ToLower() + (Get-Culture).TextInfo.ToTitleCase($rest) -replace '-'
            }

            $testFilePaths = (Get-ChildItem -Path $ModuleRoot -Recurse -Filter 'main.test.bicep').FullName | Sort-Object -Culture 'en-US'

            if ($TemplateFileContent.parameters.Count -gt 0) {

                $requiredParametersList = $TemplateFileContent.parameters.Keys | Where-Object {

                    Get-IsParameterRequired -TemplateFileContent $TemplateFileContent -Parameter $TemplateFileContent.parameters[$_]

                } | Sort-Object -Culture 'en-US'

            } else {
                $requiredParametersList = @()
            }


            ############################
            ##   Process test files   ##
            ############################

            # Prepare data (using thread-safe multithreading) to consume later
            $buildTestFileMap = [System.Collections.Concurrent.ConcurrentDictionary[string, object]]::new()
            $testFilePaths | ForEach-Object -Parallel {
                $dict = $using:buildTestFileMap

                $folderName = Split-Path (Split-Path -Path $_) -Leaf
                $builtTemplate = (bicep build $_ --stdout 2>$null) | Out-String

                if ([String]::IsNullOrEmpty($builtTemplate)) {
                    throw "Failed to build template [$_]. Try running the command ``bicep build $_ --stdout`` locally for troubleshooting. Make sure you have the latest Bicep CLI installed."
                }
                $templateHashTable = ConvertFrom-Json $builtTemplate -AsHashtable

                $null = $dict.TryAdd($folderName, $templateHashTable)
            }

            # Process data
            $pathIndex = 1
            $usageExampleSectionHeaders = @()
            $testFilesContent = @()
            foreach ($testFilePath in $testFilePaths) {

                # Read content
                $rawContentArray = Get-Content -Path $testFilePath
                $folderName = Split-Path (Split-Path -Path $testFilePath) -Leaf
                $compiledTestFileContent = $buildTestFileMap[$folderName]
                $rawContent = Get-Content -Path $testFilePath -Encoding 'utf8' | Out-String

                # Format example header
                if ($compiledTestFileContent.metadata.Keys -contains 'name') {
                    $exampleTitle = $compiledTestFileContent.metadata.name
                } else {
                    if ((Split-Path (Split-Path $testFilePath -Parent) -Leaf) -ne '.test') {
                        $exampleTitle = Split-Path (Split-Path $testFilePath -Parent) -Leaf
                    } else {
                        $exampleTitle = ((Split-Path $testFilePath -LeafBase) -replace '\.', ' ') -replace ' parameters', ''
                    }
                    $textInfo = (Get-Culture -Name 'en-US').TextInfo
                    $exampleTitle = $textInfo.ToTitleCase($exampleTitle)
                }

                $fullTestFileTitle = '### Example {0}: _{1}_' -f $pathIndex, $exampleTitle
                $testFilesContent += @(
                    $fullTestFileTitle
                )
                $usageExampleSectionHeaders += @{
                    title  = $exampleTitle
                    header = $fullTestFileTitle
                }

                # If a description is added in the template's metadata, we can add it too
                if ($compiledTestFileContent.metadata.Keys -contains 'description') {
                    $testFilesContent += @(
                        '',
                        $compiledTestFileContent.metadata.description,
                        ''
                    )
                }

                # ------------------------- #
                #   Prepare Bicep to JSON   #
                # ------------------------- #

                $isModuleDeploymentRegex = "^module testDeployment '..\/.*main.bicep' = "

                if ($rawContentArray -match $isModuleDeploymentRegex) {
                    # Classic module deployment

                    # [1/6] Search for the relevant parameter start & end index
                    $bicepTestStartIndex = ($rawContentArray | Select-String ("^module testDeployment '..\/.*main.bicep' = ") | ForEach-Object { $_.LineNumber - 1 })[0]

                    $bicepTestEndIndex = $bicepTestStartIndex
                    do {
                        $bicepTestEndIndex++
                    } while ($rawContentArray[$bicepTestEndIndex] -notin @('}', '}]', ']') -and $bicepTestEndIndex -lt $rawContentArray.Count)

                    if ($bicepTestEndIndex -eq $rawContentArray.Count) {
                        throw "End index of test block for test file [$testFilePath] not found."
                    }

                    $rawBicepExample = $rawContentArray[$bicepTestStartIndex..$bicepTestEndIndex]

                    if (-not ($rawBicepExample | Select-String ('\s+params:.*'))) {
                        # Handle case where params are not provided
                        $paramsBlockArray = @()
                    } else {
                        # Extract params block out of the Bicep example
                        $paramsStartIndex = ($rawBicepExample | Select-String ('\s+params:.*') | ForEach-Object { $_.LineNumber - 1 })[0]
                        $paramsIndent = ($rawBicepExample[$paramsStartIndex] | Select-String '(\s+).*').Matches.Groups[1].Length


                        # Handle case where params are empty
                        if ($rawBicepExample[$paramsStartIndex] -match '^.*params:\s*\{\s*\}\s*$') {
                            $paramsBlockArray = @()
                        } else {
                            # Handle case where params are provided
                            $paramsEndIndex = $paramsStartIndex
                            do {
                                $paramsEndIndex++
                            } while ($rawBicepExample[$paramsEndIndex] -notmatch "^\s{$paramsIndent}\}" -and
                                $rawBicepExample[$paramsEndIndex] -notmatch "^\s{$paramsIndent}\}\]" -and
                                $rawBicepExample[$paramsEndIndex] -notmatch "^\s{$paramsIndent}\]" -and
                                $paramsEndIndex -lt $rawBicepExample.Count)

                            if ($paramsEndIndex -eq $rawBicepExample.Count) {
                                throw "End index of 'params' block for test file [$testFilePath] not found."
                            }

                            $paramsBlock = $rawBicepExample[($paramsStartIndex + 1) .. ($paramsEndIndex - 1)]
                            $paramsBlockArray = $paramsBlock -replace "^\s{$paramsIndent}" # Remove excess leading spaces

                            # [2/6] Replace placeholders
                            $serviceShort = ([regex]::Match($rawContent, "(?m)^param serviceShort string = '(.+)'\s*$")).Captures.Groups[1].Value

                            $paramsBlockString = ($paramsBlockArray | Out-String)
                            $paramsBlockString = $paramsBlockString -replace '\$\{serviceShort\}', $serviceShort
                            $paramsBlockString = $paramsBlockString -replace '\$\{namePrefix\}[-|\.|_]?', '' # Replacing with empty to not expose prefix and avoid potential deployment conflicts
                            $paramsBlockString = $paramsBlockString -replace '(?m):\s*location\s*$', ': ''<location>'''

                            # [3/6] Format header, remove scope property & any empty line
                            $paramsBlockArray = $paramsBlockString -split '\n' | Where-Object { -not [String]::IsNullOrEmpty($_) }
                            $paramsBlockArray = $paramsBlockArray | ForEach-Object { "  $_" }
                        }
                    }

                    # [4/6] Convert Bicep parameter block to JSON parameter block to enable processing
                    $conversionInputObject = @{
                        BicepParamBlock = ($paramsBlockArray | Out-String).TrimEnd()
                        CurrentFilePath = $testFilePath
                    }
                    $paramsInJSONFormat = ConvertTo-FormattedJSONParameterObject @conversionInputObject

                    # [5/6] Convert JSON parameters back to Bicep and order & format them
                    $conversionInputObject = @{
                        JSONParameters         = $paramsInJSONFormat
                        RequiredParametersList = $RequiredParametersList
                    }
                    $bicepExample = ConvertTo-FormattedBicep @conversionInputObject

                    # [6/6] Convert the Bicep format to a Bicep parameters file format
                    if ($bicepExample.length -gt 0) {
                        $bicepParamBlockArray = $bicepExample -split '\r?\n'
                        $topLevelParamIndent = ([regex]::Match($bicepParamBlockArray[0], '^(\s+).*')).Captures.Groups[1].Value.Length
                        $bicepParametersFileExample = $bicepParamBlockArray | ForEach-Object {
                            $line = $_
                            $line = $line -replace "^(\s{$topLevelParamIndent})([a-zA-Z]*)(:)(.*)", 'param $2 =$4' # Update any [    xyz: abc] to [param xyz = abc]
                            $line = $line -replace "^\s{$topLevelParamIndent}", '' # Update any [    xyz: abc] to [xyz: abc]
                            $line
                        }
                    }

                    # --------------------- #
                    #   Add Bicep example   #
                    # --------------------- #
                    if ($addBicep) {

                        $formattedBicepExample = @(
                            if ($UseLocalTargetLink) {
                                "module $moduleNameCamelCase 'iac/$($targetLink)/main.bicep' = {"
                            } else {
                                "module $moduleNameCamelCase 'br/private:$($targetLink):$($targetVersion)' = {"
                            },
                            "  name: '$($moduleNameCamelCase)Deployment'"
                            '  params: {'
                        ) + $bicepExample +
                        @( '  }',
                            '}'
                        )

                        # Build result
                        $testFilesContent += @(
                            '',
                            '<details>'
                            ''
                            '<summary>via Bicep module</summary>'
                            ''
                            '```bicep',
                            ($formattedBicepExample | ForEach-Object { "$_" }).TrimEnd(),
                            '```',
                            '',
                            '</details>',
                            '<p>'
                        )
                    }

                    # -------------------- #
                    #   Add JSON example   #
                    # -------------------- #
                    if ($addJson) {

                        # [1/2] Get all parameters from the parameter object and order them recursively
                        $orderingInputObject = @{
                            ParametersJSON         = $paramsInJSONFormat | ConvertTo-Json -Depth 99
                            RequiredParametersList = $RequiredParametersList
                        }
                        $orderedJSONExample = Build-OrderedJSONObject @orderingInputObject

                        # [2/2] Create the final content block
                        $testFilesContent += @(
                            '',
                            '<details>'
                            ''
                            '<summary>via JSON parameters file</summary>'
                            ''
                            '```json',
                            $orderedJSONExample.Trim()
                            '```',
                            '',
                            '</details>',
                            '<p>'
                        )
                    }

                    # ---------------------------------------- #
                    #     Add Bicep parameters file example    #
                    # ---------------------------------------- #
                    if ($AddBicepParametersFile) {

                        $formattedBicepParametersFileExample = @(
                            if ($UseLocalTargetLink) {
                                "using 'iac/$($targetLink)/main.bicep'"
                            } else {
                                "using 'br/private:$($targetLink):$($targetVersion)'"
                            },
                            ''
                        ) + $bicepParametersFileExample


                        # Build result
                        $testFilesContent += @(
                            '',
                            '<details>'
                            ''
                            '<summary>via Bicep parameters file</summary>'
                            ''
                            '```bicep-params',
                            ($formattedBicepParametersFileExample | ForEach-Object { "$_" }).TrimEnd(),
                            '```',
                            '',
                            '</details>',
                            '<p>'
                        )
                    }
                } else {
                    # Non-module deployment (e.g., utility deployment)

                    # ----------------------------- #
                    #   Add non-formatted example   #
                    # ----------------------------- #
                    $testFilesContent += @(
                        '',
                        '<details>'
                        ''
                        '<summary>via Bicep module</summary>'
                        ''
                        '```bicep',
                        $rawContentArray,
                        '```',
                        '',
                        '</details>',
                        '<p>'
                    )
                }


                $testFilesContent += @(
                    ''
                )

                $pathIndex++
            }
            foreach ($rawHeader in $usageExampleSectionHeaders) {
                $navigationHeader = (($rawHeader.header -replace '<\/?.+?>|[^A-Za-z0-9\s-]').Trim() -replace '\s+', '-').ToLower() # Remove any html and non-identifer elements
                $sectionContent += '- [{0}](#{1})' -f $rawHeader.title, $navigationHeader
            }
            $sectionContent += ''


            $sectionContent += $testFilesContent

            ######################
            ##   Built result   ##
            ######################
            if ($sectionContent) {
                if ($PSCmdlet.ShouldProcess('Original file with new template references content', 'Merge')) {
                    return Merge-FileWithNewContent -oldContent $ReadMeFileContent -newContent $sectionContent -SectionStartIdentifier $SectionStartIdentifier -ContentType 'nextH2'
                }
            } else {
                return $ReadMeFileContent
            }

        } catch {
            throw $_
        }
    }

    end {
        Write-Debug ('{0} exited' -f $MyInvocation.MyCommand)
    }
}
function Set-ParametersSection {
    <#
    .SYNOPSIS
    .DESCRIPTION
    .NOTES
    .LINK
    .EXAMPLE
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(
            Mandatory,
            HelpMessage = 'Mandatory. The template file content object to crawl data from')]
        [hashtable]
        $TemplateFileContent,

        [Parameter(
            Mandatory,
            HelpMessage = 'Mandatory. The readme file content object array to update')]
        [object[]]
        $ReadMeFileContent,

        [Parameter(
            Mandatory = $false,
            HelpMessage = "Optional. The identifier of the 'outputs' section. Defaults to '## Parameters'")]
        [string]
        $SectionStartIdentifier = '## Parameters',

        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Optional. The order of the columns in the section. Defaults to ''Required'', ''Conditional'', ''Optional'', ''Generated''')]
        [string[]]
        $ColumnsInOrder = @(
            'Required',
            'Conditional',
            'Optional',
            'Generated'
        )
    )

    # Invoking recursive function to resolve parameters
    $newSectionContent = Set-DefinitionSection -TemplateFileContent $TemplateFileContent -ColumnsInOrder $ColumnsInOrder

    # Build result
    if ($PSCmdlet.ShouldProcess('Original file with new parameters content', 'Merge')) {

        $inputParams = @{
            OldContent             = $ReadMeFileContent
            NewContent             = $newSectionContent
            SectionStartIdentifier = $SectionStartIdentifier
            ContentType            = 'nextH2'
        }
        $updatedFileContent = Merge-FileWithNewContent @inputParams
    }

    return $updatedFileContent
}
function Set-DefinitionSection {
    <#
    .SYNOPSIS
        Update parts of the 'parameters' section of the given readme file, if user defined types are used
    .DESCRIPTION
    .NOTES
    .LINK
    .EXAMPLE
    #>
    param (
        [Parameter(
            Mandatory,
            HelpMessage = 'Mandatory. The template file content object to crawl data from')]
        [hashtable]
        $TemplateFileContent,

        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Optional. Hashtable of the user defined properties. If not provided, the top-level parameters are used')]
        [hashtable]
        $Properties,

        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Optional. The name of the parent parameter, that has the user defined types')]
        [string]
        $ParentName,

        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Optional. The link to the parent parameter, that has the user defined types')]
        [string]
        $ParentIdentifierLink,

        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Optional. The order of the columns in the section. Defaults to ''Required'', ''Conditional'', ''Optional'', ''Generated''')]
        [string[]]
        $ColumnsInOrder = @(
            'Required',
            'Conditional',
            'Optional',
            'Generated'
        )
    )

    if (-not $Properties -and -not $TemplateFileContent.parameters) {
        # no Parameters / properties on this level or in the template
        return '_None_'
    } elseif (-not $Properties) {
        # Top-level invocation, get all descriptions
        $descriptions = $TemplateFileContent.parameters.Values.metadata.description

        # Add name as property for later reference
        $TemplateFileContent.parameters.Keys | ForEach-Object { $TemplateFileContent.parameters[$_]['name'] = $_ }

        # Error handling: Throw error if any parameter is missing a category
        if ($paramsWithoutCategory = $TemplateFileContent.parameters.Values | Where-Object {
                $_.metadata.description -notmatch '^\w+?\.'
            }) {
            $formattedParam = $paramsWithoutCategory | ForEach-Object {
                [PSCustomObject]@{
                    name        = $_.name;
                    description = $_.metadata.description
                }
            } | ConvertTo-Json -Compress

            Write-Error ("Each parameter description should start with a category like [Required. / Optional. / Conditional. ]. The following parameters are missing such a category: `n$formattedParam`n")
        }
    } else {
        $descriptions = $Properties.Values.metadata.description

        # Add name as property for later reference
        $Properties.Keys | ForEach-Object { $Properties[$_]['name'] = $_ }

        # Error handling: Throw error if any parameter is missing a category
        if ($paramsWithoutCategory = $Properties.Values | Where-Object {
                $_.metadata.description -notmatch '^\w+?\.'
            }) {
            $formattedParam = $paramsWithoutCategory | ForEach-Object {
                [PSCustomObject]@{
                    name        = $_.name;
                    description = $_.metadata.description
                }
            } | ConvertTo-Json -Compress

            Write-Error ("Each parameter description should start with a category like [Required. / Optional. / Conditional. ]. The following parameters are missing such a category: `n$formattedParam`n")
        }
    }

    # Get the module parameter categories
    $paramCategories = $descriptions | ForEach-Object { $_.Split('.')[0] } | Select-Object -Unique

    # Sort categories
    $sortedParamCategories = $ColumnsInOrder | Where-Object { $paramCategories -contains $_ }

    # Add all others that exist but are not specified in the columnsInOrder parameter
    $sortedParamCategories += $paramCategories | Where-Object { $ColumnsInOrder -notcontains $_ }

    $newSectionContent = [System.Collections.ArrayList]@()
    $tableSectionContent = [System.Collections.ArrayList]@()
    $listSectionContent = [System.Collections.ArrayList]@()

    foreach ($category in $sortedParamCategories) {

        # Prepare, filter to relevant items
        if (-not $Properties) {
            # Top-level invocation
            [array] $categoryParameters = $TemplateFileContent.parameters.Values | Where-Object {
                $_.metadata.description -like "$category. *"
            } | Sort-Object -Culture 'en-US' -Property 'Name'
        } else {
            $categoryParameters = $Properties.Values | Where-Object {
                $_.metadata.description -like "$category. *"
            } | Sort-Object -Culture 'en-US' -Property 'Name'
        }

        $tableSectionContent += @(
            ('**{0} parameters**' -f $category),
            '',
            '| Parameter | Type | Description |',
            '| :-- | :-- | :-- |'
        )

        # Gather details
        foreach ($parameter in $categoryParameters) {

            $paramIdentifier = (-not [String]::IsNullOrEmpty($ParentName)) ? '{0}.{1}' -f $ParentName, $parameter.name : $parameter.name
            $paramHeader = '### Parameter: `{0}`' -f $paramIdentifier
            $paramIdentifierLink = (-not [String]::IsNullOrEmpty($ParentIdentifierLink)) ? ('{0}{1}' -f $ParentIdentifierLink, $parameter.name).ToLower() :  ('#{0}' -f $paramHeader.TrimStart('#').Trim().ToLower()) -replace '[:|`]' -replace ' ', '-'

            # Definition type (if any)
            if ($parameter.Keys -contains '$ref') {

                $identifier = Split-Path $parameter.'$ref' -Leaf
                $definition = $TemplateFileContent.definitions[$identifier]
                $type = $definition['type']
                $minLength = $definition['minLength']
                $maxLength = $definition['maxLength']
                $rawAllowedValues = $definition['allowedValues']

            } elseif ($parameter.Keys -contains 'items' -and $parameter.items.type -in @('object', 'array') -or $parameter.type -eq 'object') {

                # Array has nested non-primitive type (array/object) - and if array,
                # the UDT itself is declared as the array
                $definition = $parameter
                $type = $parameter.type
                $minLength = $parameter.minLength
                $maxLength = $parameter.maxLength
                $rawAllowedValues = $parameter.allowedValues

            } elseif ($parameter.Keys -contains 'items' -and $parameter.items.keys -contains '$ref') {

                # Array has nested non-primitive type (array) - and the parameter is defined as an array of the UDT
                $identifier = Split-Path $parameter.items.'$ref' -Leaf
                $definition = $TemplateFileContent.definitions[$identifier]
                $type = $parameter.type
                $minLength = $parameter.minLength
                $maxLength = $parameter.maxLength
                $rawAllowedValues = $definition['allowedValues']

            } else {

                $definition = $null
                $type = $parameter.type
                $minLength = $parameter.minLength
                $maxLength = $parameter.maxLength
                $rawAllowedValues = $parameter.allowedValues
            }

            $isRequired = (Get-IsParameterRequired -TemplateFileContent $TemplateFileContent -Parameter $parameter) ? 'Yes' : 'No'
            $description = $parameter.ContainsKey('metadata') ? $parameter['metadata']['description'].substring("$category. ".Length).Replace("`n- ", '<li>').Replace("`r`n", '<p>').Replace("`n", '<p>') : $null
            $example = ($parameter.ContainsKey('metadata') -and $parameter['metadata'].ContainsKey('example')) ? $parameter['metadata']['example'] : $null

            # Table content
            # Build table for definition properties
            $tableSectionContent += ('| [`{0}`]({1}) | {2} | {3} |' -f $parameter.name, $paramIdentifierLink, $type, $description)

            # List content
            # Format default values
            if ($parameter.defaultValue -is [array]) {
                if ($parameter.defaultValue.count -eq 0) {
                    $defaultValue = '[]'
                } else {
                    # Wrapping on object to work with formatted Bicep script
                    $bicepJsonDefaultParameterObject = @{
                        $parameter.name = ($parameter.defaultValue ?? @())
                    }

                    $bicepRawformattedDefault = ConvertTo-FormattedBicep -JsonParameters $bicepJsonDefaultParameterObject
                    $leadingSpacesToTrim = ($bicepRawformattedDefault -match '^(\s+).+') ? $matches[1].Length : 0

                    # Unwrapping the object
                    $bicepCleanedFormattedDefault = $bicepRawformattedDefault -replace ('{0}: ' -f $parameter.name)

                    $defaultValue = $bicepCleanedFormattedDefault -split '\n' | ForEach-Object {
                        # Removing excess leading spaces
                        $_ -replace "^\s{$leadingSpacesToTrim}"
                    }
                }
            } elseif ($parameter.defaultValue -is [hashtable]) {
                if ($parameter.defaultValue.count -eq 0) {
                    $defaultValue = '{}'
                } else {
                    $bicepDefaultValue = ConvertTo-FormattedBicep -JsonParameters $parameter.defaultValue
                    $defaultValue = "{`n$bicepDefaultValue`n}"
                }
            } elseif ($parameter.defaultValue -is [string] -and ($parameter.defaultValue -notmatch '\[\w+\(.*\).*\]')) {
                $defaultValue = '''' + $parameter.defaultValue + ''''
            } else {
                $defaultValue = $parameter.defaultValue
            }

            if (-not [String]::IsNullOrEmpty($defaultValue)) {
                if (($defaultValue -split '\n').count -eq 1) {
                    $formattedDefaultValue = '- Default: `{0}`' -f $defaultValue
                } else {
                    $formattedDefaultValue = @(
                        '- Default:',
                        '  ```Bicep',
                        ($defaultValue -split '\n' | ForEach-Object { "  $_" } | Out-String).TrimEnd(),
                        '  ```'
                    )
                }
            } else {
                $formattedDefaultValue = $null
            }

            # Format allowed values
            if ($rawAllowedValues -is [array]) {

                # Wrapping on object to work with formatted Bicep script
                $bicepJsonAllowedParameterObject = @{
                    $parameter.name = ($rawAllowedValues ?? @())
                }
                $bicepRawformattedAllowed = ConvertTo-FormattedBicep -JsonParameters $bicepJsonAllowedParameterObject
                $leadingSpacesToTrim = ($bicepRawformattedAllowed -match '^(\s+).+') ? $matches[1].Length : 0

                # Unwrapping the object
                $bicepCleanedFormattedAllowed = $bicepRawformattedAllowed -replace ('{0}: ' -f $parameter.name)

                # Removing excess leading spaces
                $allowedValues = $bicepCleanedFormattedAllowed -split '\n' | ForEach-Object {
                    $_ -replace "^\s{$leadingSpacesToTrim}"
                }
            } elseif ($rawAllowedValues -is [hashtable]) {
                $bicepAllowedValues = ConvertTo-FormattedBicep -JsonParameters $rawAllowedValues
                $allowedValues = "{`n$bicepAllowedValues`n}"
            } else {
                $allowedValues = $rawAllowedValues
            }

            if (-not [String]::IsNullOrEmpty($allowedValues)) {
                if (($allowedValues -split '\n').count -eq 1) {
                    $formattedAllowedValues = '- Default: `{0}`' -f $allowedValues
                } else {
                    $formattedAllowedValues = @(
                        '- Allowed:',
                        '  ```Bicep',
                        ($allowedValues -split '\n' |
                            Where-Object { -not [String]::IsNullOrEmpty($_) } |
                            ForEach-Object { "  $_" } | Out-String).TrimEnd(),
                        '  ```'
                    )
                }
            } else {
                $formattedAllowedValues = $null
            }

            # Format example
            if (-not [String]::IsNullOrEmpty($example)) {

                # allign content to the left by removing trailing whitespaces
                $leadingSpacesToTrim = ($example -match '^(\s+).+') ? $matches[1].Length : 0
                $exampleLines = $example -split '\n'

                # Removing excess leading spaces
                $example = ($exampleLines |
                        Where-Object { -not [String]::IsNullOrEmpty($_) } |
                        ForEach-Object { "  $_" -replace "^\s{$leadingSpacesToTrim}" } | Out-String).TrimEnd()

                if ($exampleLines.count -eq 1) {
                    $formattedExample = '- Example: `{0}`' -f $example.TrimStart()
                } else {
                    $formattedExample = @(
                        '- Example:',
                        '  ```Bicep',
                        $example,
                        '  ```'
                    )
                }
            } else {
                $formattedExample = $null
            }

            # Build list item
            $listSectionContent += @(
                $paramHeader,
                ($parameter.ContainsKey('metadata') ? '' : $null),
                $description
                ($parameter.ContainsKey('metadata') ? '' : $null),
                ('- Required: {0}' -f $isRequired),
                ('- Type: {0}' -f $type),
                ((-not [String]::IsNullOrEmpty($minLength)) ? '- Min length: {0}' -f $minLength : $null),
                ((-not [String]::IsNullOrEmpty($maxLength)) ? '- Max length: {0}' -f $maxLength : $null),
                ((-not [String]::IsNullOrEmpty($formattedDefaultValue)) ? $formattedDefaultValue : $null),
                ((-not [String]::IsNullOrEmpty($formattedAllowedValues)) ? $formattedAllowedValues : $null),
                ((-not [String]::IsNullOrEmpty($formattedExample)) ? $formattedExample : $null)
                ''
            ) | Where-Object { $null -ne $_ }

            # recursive call for children
            if ($definition) {
                # 'items' refers to an array
                # 'properties' is the default for UDTs, 'additionalProperties' represents a used '*' identifier
                if ($definition.Keys -contains 'items' -and ($definition.items.properties.Keys -or $definition.items.additionalProperties.Keys)) {

                    if ($definition.items.properties.Keys) {
                        $childProperties = $definition.items.properties
                        $sectionContent = Set-DefinitionSection -TemplateFileContent $TemplateFileContent -Properties $childProperties -ParentName $paramIdentifier -ParentIdentifierLink $paramIdentifierLink -ColumnsInOrder $ColumnsInOrder
                        $listSectionContent += $sectionContent
                    }

                    if ($definition.items.additionalProperties.Keys) {
                        $childProperties = $definition.items.additionalProperties
                        $formattedProperties = @{ '>Any_other_property<' = $childProperties }
                        $sectionContent = Set-DefinitionSection -TemplateFileContent $TemplateFileContent -Properties $formattedProperties -ParentName $paramIdentifier -ParentIdentifierLink $paramIdentifierLink -ColumnsInOrder $ColumnsInOrder
                        $listSectionContent += $sectionContent
                    }
                } elseif ($definition.type -eq 'object' -and ($definition.properties.Keys -or $definition.additionalProperties.Keys)) {

                    if ($definition.properties.Keys) {
                        $childProperties = $definition.properties
                        $sectionContent = Set-DefinitionSection -TemplateFileContent $TemplateFileContent -Properties $childProperties -ParentName $paramIdentifier -ParentIdentifierLink $paramIdentifierLink -ColumnsInOrder $ColumnsInOrder
                        $listSectionContent += $sectionContent
                    }

                    if ($definition.additionalProperties.Keys) {
                        $childProperties = $definition.additionalProperties
                        $formattedProperties = @{ '>Any_other_property<' = $childProperties }
                        $sectionContent = Set-DefinitionSection -TemplateFileContent $TemplateFileContent -Properties $formattedProperties -ParentName $paramIdentifier -ParentIdentifierLink $paramIdentifierLink -ColumnsInOrder $ColumnsInOrder
                        $listSectionContent += $sectionContent
                    }
                }
            }
        }

        $tableSectionContent += ''
    }

    $newSectionContent += $tableSectionContent
    $newSectionContent += $listSectionContent
    return $newSectionContent
}
function Set-OutputsSection {
    <#
    .SYNOPSIS
        Update the 'outputs' section of the given readme file
    .DESCRIPTION
    .NOTES
    .LINK
    .EXAMPLE
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(
            Mandatory,
            HelpMessage = 'Mandatory. The template file content object to crawl data from')]
        [hashtable]
        $TemplateFileContent,

        [Parameter(
            Mandatory,
            HelpMessage = 'Mandatory. The readme file content object array to update')]
        [object[]]
        $ReadMeFileContent,

        [Parameter(
            Mandatory = $false,
            HelpMessage = "Optional. The identifier of the 'outputs' section. Defaults to '## Outputs'")]
        [string]
        $SectionStartIdentifier = '## Outputs'
    )

    # Process content
    if (-not $TemplateFileContent.outputs) {
        # no outputs in the template
        $sectionContent = '_None_'

    } elseif ($TemplateFileContent.outputs.Values.metadata) {

        # Prepare content, template has output description
        $sectionContent = [System.Collections.ArrayList]@(
            '| Output | Type | Description |',
            '| :-- | :-- | :-- |'
        )

        # Gather details
        foreach ($outputName in ($templateFileContent.outputs.Keys | Sort-Object -Culture 'en-US')) {
            $output = $TemplateFileContent.outputs[$outputName]
            $description = $output.metadata.description.Replace("`r`n", '<p>').Replace("`n", '<p>')
            $sectionContent += ("| ``{0}`` | {1} | {2} |" -f $outputName, $output.type, $description)
        }
    } else {

        # Prepare content, template has no output description
        $sectionContent = [System.Collections.ArrayList]@(
            '| Output | Type |',
            '| :-- | :-- |'
        )
        foreach ($outputName in ($templateFileContent.outputs.Keys | Sort-Object -Culture 'en-US')) {
            $output = $TemplateFileContent.outputs[$outputName]
            $sectionContent += ("| ``{0}`` | {1} |" -f $outputName, $output.type)
        }
    }

    if ($sectionContent.Count -eq 2) {
        # No content was added, adding placeholder
        $sectionContent = @('_None_')
    }

    # Build result
    if ($PSCmdlet.ShouldProcess('Original file with new output content', 'Merge')) {
        $updatedFileContent = Merge-FileWithNewContent -oldContent $ReadMeFileContent -newContent $sectionContent -SectionStartIdentifier $SectionStartIdentifier -contentType 'nextH2'
    }
    return $updatedFileContent
}
function Set-CrossReferencesSection {
    <#
    .SYNOPSIS
        Add module references (cross-references) to the module's readme

    .DESCRIPTION
        This includes both local (i.e., file path), as well as remote references (e.g., ACR)

    .PARAMETER ModuleRoot
        The root path of the module

    .PARAMETER FullModuleIdentifier
        The full identifier of the module. For example: 'ProviderNamespace/resourceType'

    .PARAMETER TemplateFileContent
        The template file content object to crawl data from

    .PARAMETER ReadMeFileContent
        The readme file content object array to update

    .PARAMETER PreLoadedContent
        Pre-Loaded content. May be used to reuse the same data for multiple invocations. For example:
        @{
            CrossReferencedModuleList = @{} // Optional. Cross Module References to consider when refreshing the readme. Can be provided to speed up the generation. If not provided, is fetched by this script.
        }

    .PARAMETER SectionStartIdentifier
        The identifier of the 'outputs' section. Defaults to '## Cross-referenced modules'

    .NOTES
    .LINK
    .EXAMPLE
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory)]
        [string] $ModuleRoot,

        [Parameter(Mandatory)]
        [string] $FullModuleIdentifier,

        [Parameter(Mandatory)]
        [hashtable] $TemplateFileContent,

        [Parameter(Mandatory)]
        [object[]] $ReadMeFileContent,

        [Parameter(Mandatory = $false)]
        [hashtable] $PreLoadedContent = @{},

        [Parameter(Mandatory = $false)]
        [string] $SectionStartIdentifier = '## Cross-referenced modules'
    )

    # Load content, if required
    if ($PreLoadedContent.Keys -notcontains 'CrossReferencedModuleList') {
        $CrossReferencedModuleList = Get-CrossReferencedModuleList -Path $ModuleRoot
    } else {
        $CrossReferencedModuleList = $PreLoadedContent.CrossReferencedModuleList
    }

    $dependencies = $CrossReferencedModuleList[$FullModuleIdentifier]

    if (-not $dependencies -or ($dependencies -and -not $dependencies['localPathReferences'] -and -not $dependencies['remoteReferences'])) {
        # no cross references in the template
        return $ReadMeFileContent
    }

    # Process content
    $sectionContent = [System.Collections.ArrayList]@(
        'This section gives you an overview of all local-referenced module files (i.e., other modules that are referenced in this module) and all remote-referenced files (i.e., Bicep modules that are referenced from a Bicep Registry or Template Specs).',
        '',
        '| Reference | Type |',
        '| :-- | :-- |'
    )

    if ($dependencies.Keys -contains 'localPathReferences' -and $dependencies['localPathReferences']) {
        foreach ($reference in ($dependencies['localPathReferences'] | Sort-Object -Culture 'en-US')) {
            $sectionContent += ("| ``{0}`` | {1} |" -f $reference, 'Local reference')
        }
    }

    if ($dependencies.Keys -contains 'remoteReferences' -and $dependencies['remoteReferences']) {
        foreach ($reference in ($dependencies['remoteReferences'] | Sort-Object -Culture 'en-US')) {
            $sectionContent += ("| ``{0}`` | {1} |" -f $reference, 'Remote reference')
        }
    }

    # Build result
    if ($PSCmdlet.ShouldProcess('Original file with new output content', 'Merge')) {
        $updatedFileContent = Merge-FileWithNewContent -oldContent $ReadMeFileContent -newContent $sectionContent -SectionStartIdentifier $SectionStartIdentifier -contentType 'nextH2'
    }
    return $updatedFileContent
}
function Set-TableOfContent {
    <#
    .SYNOPSIS
        Generate a table of content section for the given readme file
    .DESCRIPTION
    .NOTES
    .LINK
    .EXAMPLE
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(
            Mandatory,
            HelpMessage = 'Mandatory. The readme file content object array to update')]
        [object[]]
        $ReadMeFileContent,

        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Optional. The identifier of the ''navigation'' section. Defaults to ''## Navigation''')]
        [string]
        $SectionStartIdentifier = '## Navigation'
    )

    $newSectionContent = [System.Collections.ArrayList]@()

    # Prevent 'Markdown All in One' unexpected TOC recognition
    $newSectionContent += '<!-- no toc -->'

    $contentPointer = 3
    while ($ReadMeFileContent[$contentPointer] -notlike '#*') {
        $contentPointer++
    }

    $headers = $ReadMeFileContent.Split('\n') | Where-Object { $_ -like '## *' }

    if ($headers -notcontains $SectionStartIdentifier) {
        $beforeContent = $ReadMeFileContent[0 .. ($contentPointer - 1)]
        $afterContent = $ReadMeFileContent[$contentPointer .. ($ReadMeFileContent.Count - 1)]

        $ReadMeFileContent = $beforeContent + @($SectionStartIdentifier, '') + $afterContent
    }

    $headers | Where-Object { $_ -ne $SectionStartIdentifier } | ForEach-Object {
        $newSectionContent += '- [{0}](#{1})' -f $_.Replace('#', '').Trim(), $_.Replace('#', '').Trim().Replace(' ', '-').Replace('.', '').ToLower()
    }

    # Build result
    if ($PSCmdlet.ShouldProcess('Original file with new navigation content', 'Merge')) {
        $updatedFileContent = Merge-FileWithNewContent -oldContent $ReadMeFileContent -newContent $newSectionContent -SectionStartIdentifier $SectionStartIdentifier -contentType 'nextH2'
    }

    return $updatedFileContent
}
function Test-Url {
    <#
    .SYNOPSIS
        Test if an URL points to a valid online endpoint
    .DESCRIPTION
    .NOTES
    .LINK
    .EXAMPLE
    #>
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory,
            HelpMessage = 'Mandatory. The URL to test')]
        [string]
        $URL,

        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Optional. The number of retries to attempt. Defaults to 3')]
        [int]
        $Retries = 3
    )

    $currentAttempt = 1

    while ($currentAttempt -le $Retries) {
        try {
            $null = Invoke-WebRequest -Uri $URL
            return $true
        } catch {
            $currentAttempt++
            Start-Sleep -Seconds 1
        }
    }

    return $false
}
function Get-NestedResourceList {
    <#
    .SYNOPSIS
        Get a list of all resources (provider + service) in the given template content
    .DESCRIPTION
        Crawls through any children and nested deployment templates
    .NOTES
    .LINK
    .EXAMPLE
    #>
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory,
            HelpMessage = 'Mandatory. The template file content object to crawl data from')]
        [Alias('Path')]
        [hashtable]
        $TemplateFileContent
    )

    $res = @()
    $currLevelResources = @()

    if ($TemplateFileContent.resources) {
        if ($TemplateFileContent.resources -is [System.Collections.Hashtable]) {
            # With the introduction of user defined types, a compiled template's resources are not part of an ordered hashtable instead of an array.
            $currLevelResources += $TemplateFileContent.resources.Keys | ForEach-Object {
                $TemplateFileContent.resources[$_]
            } | Where-Object {
                $_.existing -ne $true
            }
        } else {
            # Default array
            $currLevelResources += $TemplateFileContent.resources
        }
    }
    foreach ($resource in $currLevelResources) {
        $res += $resource

        if ($resource.type -eq 'Microsoft.Resources/deployments') {
            if ($resource.properties.template -is [System.Collections.Hashtable]) {
                $res += Get-NestedResourceList -TemplateFileContent $resource.properties.template
            }
        } else {
            $res += Get-NestedResourceList -TemplateFileContent $resource
        }
    }
    return $res
}
function Get-IsParameterRequired {
    <#
    .SYNOPSIS
        Based on the provided parameter metadata, determine whether the parameter is required or not
    .NOTES
    .LINK
    .EXAMPLE
    #>
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory,
            HelpMessage = 'Mandatory. The parameter metadata to analyze')]
        [hashtable]
        $Parameter,

        [Parameter(
            Mandatory,
            HelpMessage = 'Mandatory. The template file content object to crawl data from')]
        [hashtable]
        $TemplateFileContent
    )

    begin {
        Write-Debug ('{0} entered' -f $MyInvocation.MyCommand)
    }

    process {
        try {

            $hasParameterNoDefault = $Parameter.Keys -notcontains 'defaultValue'
            $isParameterNullable = $Parameter['nullable']

            # User defined type
            $isUserDefinedType = $Parameter.Keys -contains '$ref'
            $isUserDefinedTypeNullable = $Parameter.Keys -contains '$ref' ? $TemplateFileContent.definitions[(Split-Path $Parameter.'$ref' -Leaf)]['nullable'] : $false

            # Evaluation
            # The parameter is required IF it
            # - has no default value,
            # - is not nullable
            # - has no nullable user-defined type
            return $hasParameterNoDefault -and -not $isParameterNullable -and -not ($isUserDefinedType -and $isUserDefinedTypeNullable)

        } catch {
            throw $_
        }
    }

    end {
        Write-Debug ('{0} exited' -f $MyInvocation.MyCommand)
    }
}
function ConvertTo-OrderedHashtable {
    <#
    .SYNOPSIS
        Based on the provided parameter metadata, determine whether the parameter is required or not
    .NOTES
    .LINK
    .EXAMPLE
    #>
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $true,
            HelpMessage = 'Mandatory. The Json object to convert, must be string to workaround auto-conversion')]
        [string]
        $JsonInputObject
    )

    $JsonObject = ConvertFrom-Json $JsonInputObject -AsHashtable -Depth 99 -NoEnumerate
    $orderedLevel = [ordered]@{}

    if (-not ($JsonObject.GetType().BaseType.Name -eq 'Hashtable')) {
        return $JsonObject # E.g. in primitive data types [1,2,3]
    }

    foreach ($currentLevelKey in ($JsonObject.Keys | Sort-Object -Culture 'en-US')) {

        if ($null -eq $JsonObject[$currentLevelKey]) {
            # Handle case in which the value is 'null' and hence has no type
            $orderedLevel[$currentLevelKey] = $null
            continue
        }

        switch ($JsonObject[$currentLevelKey].GetType().BaseType.Name) {
            { $PSItem -in @('Hashtable') } {
                $orderedLevel[$currentLevelKey] = ConvertTo-OrderedHashtable -JsonInputObject ($JsonObject[$currentLevelKey] | ConvertTo-Json -Depth 99)
            }
            'Array' {
                $arrayOutput = @()

                # Case: Array of arrays
                $arrayElements = $JsonObject[$currentLevelKey] | Where-Object { $_.GetType().BaseType.Name -eq 'Array' }
                foreach ($array in $arrayElements) {
                    if ($array.Count -gt 1) {
                        # Only sort for arrays with more than one item. Otherwise single-item arrays are casted
                        $array = $array | Sort-Object -Culture 'en-US'
                    }
                    $arrayOutput += , (ConvertTo-OrderedHashtable -JsonInputObject ($array | ConvertTo-Json -Depth 99))
                }

                # Case: Array of objects
                $hashTableElements = $JsonObject[$currentLevelKey] | Where-Object { $_.GetType().BaseType.Name -eq 'Hashtable' }
                foreach ($hashTable in $hashTableElements) {
                    $arrayOutput += , (ConvertTo-OrderedHashtable -JsonInputObject ($hashTable | ConvertTo-Json -Depth 99))
                }

                # Case: Primitive data types
                $primitiveElements = $JsonObject[$currentLevelKey] | Where-Object { $_.GetType().BaseType.Name -notin @('Array', 'Hashtable') } | ConvertTo-Json -Depth 99 | ConvertFrom-Json -AsHashtable -NoEnumerate -Depth 99
                if ($primitiveElements.Count -gt 1) {
                    $primitiveElements = $primitiveElements | Sort-Object -Culture 'en-US'
                }
                $arrayOutput += $primitiveElements

                if ($array.Count -gt 1) {
                    # Only sort for arrays with more than one item. Otherwise single-item arrays are casted
                    $arrayOutput = $arrayOutput | Sort-Object -Culture 'en-US'
                }
                $orderedLevel[$currentLevelKey] = $arrayOutput
            }
            default {
                # string/int/etc.
                $orderedLevel[$currentLevelKey] = $JsonObject[$currentLevelKey]
            }
        }
    }

    return $orderedLevel
}
function ConvertTo-FormattedBicep {
    <#
    .SYNOPSIS
        Convert the given parameter Json object into a formatted Bicep object (i.e., sorted, with required/non-required comments)
    .DESCRIPTION
    .NOTES
    .LINK
    .EXAMPLE
    #>
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory,
            HelpMessage = 'Mandatory. The Json object to convert')]
        [hashtable]
        $JsonParameters,

        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Optional. A list of all required top-level (i.e. non-nested) parameter names')]
        [AllowEmptyCollection()]
        [string[]]
        $RequiredParametersList = @()
    )

    # Remove 'value' parameter property, if any (e.g. when dealing with a classic parameter file)
    $JsonParametersWithoutValue = @{}
    foreach ($parameterName in $JsonParameters.psbase.Keys) {
        $keysOnLevel = $JsonParameters[$parameterName].Keys
        if ($keysOnLevel.count -eq 1 -and $keysOnLevel -eq 'value') {
            $JsonParametersWithoutValue[$parameterName] = $JsonParameters[$parameterName].value
        } else {
            $JsonParametersWithoutValue[$parameterName] = $JsonParameters[$parameterName]
        }
    }

    # Order parameters recursively
    if ($JsonParametersWithoutValue.psbase.Keys.Count -gt 0) {
        $orderedJsonParameters = Get-OrderedParametersJson -ParametersJson ($JsonParametersWithoutValue | ConvertTo-Json -Depth 99) -RequiredParametersList $RequiredParametersList
    } else {
        $orderedJsonParameters = @{}
    }

    # Remove any Json specific formatting
    $templateParameterObject = $orderedJsonParameters | ConvertTo-Json -Depth 99
    if ($templateParameterObject -ne '{}') {
        $bicepParamsArray = $templateParameterObject -split '\r?\n' | ForEach-Object {
            $line = $_
            $line = $line -replace "'", "\'" # Update any [ "field": "[[concat('tags[', parameters('tagName'), ']')]"] to [ "field": "[[concat(\'tags[\', parameters(\'tagName\'), \']\')]"]
            $line = $line -replace '"', "'" # Update any [xyz: "xyz"] to [xyz: 'xyz']
            $line = $line -replace ',$', '' # Update any [xyz: abc,xyz,] to [xyz: abc,xyz]
            $line = $line -replace "'(\w+)':", '$1:' # Update any  ['xyz': xyz] to [xyz: xyz]
            $line = $line -replace "'(.+.getSecret\('.+'\))'", '$1' # Update any  [xyz: 'xyz.GetSecret()'] to [xyz: xyz.GetSecret()]
            $line
        }
        $bicepParamsArray = $bicepParamsArray[1..($bicepParamsArray.count - 2)]

        # Format 'getSecret' references
        $bicepParamsArray = $bicepParamsArray | ForEach-Object {
            if ($_ -match ".+: '(\w+)\.getSecret\(\\'([0-9a-zA-Z-<>]+)\\'\)'") {
                # e.g. change [pfxCertificate: 'kv1.getSecret(\'<certSecretName>\')'] to [pfxCertificate: kv1.getSecret('<certSecretName>')]
                "{0}: {1}.getSecret('{2}')" -f ($_ -split ':')[0], $matches[1], $matches[2]
            } else {
                $_
            }
        }
    } else {
        $bicepParamsArray = @()
    }

    # Format params with indent
    $bicepParams = ($bicepParamsArray | ForEach-Object { "  $_" } | Out-String).TrimEnd()

    # Add comment where required and optional parameters start
    $splitInputObject = @{
        BicepParams            = $bicepParams
        RequiredParametersList = $RequiredParametersList
        AllParametersList      = $JsonParameters.psBase.Keys
    }
    $commentedBicepParams = Add-BicepParameterTypeComment @splitInputObject

    return $commentedBicepParams
}
function ConvertTo-FormattedJSONParameterObject {
    <#
    .SYNOPSIS
    Convert the given Bicep parameter block to JSON parameter block

    .DESCRIPTION
    Convert the given Bicep parameter block to JSON parameter block

    .PARAMETER BicepParamBlock
    Mandatory. The Bicep parameter block to process

    .PARAMETER CurrentFilePath
    Mandatory. The Path of the file containing the param block

    .EXAMPLE
    ConvertTo-FormattedJSONParameterObject -BicepParamBlock "name: 'module'\nlock: 'CanNotDelete'" -CurrentFilePath 'c:/main.test.bicep'

    Convert the Bicep string "name: 'module'\nlock: 'CanNotDelete'" into a parameter JSON object. Would result into:

    @{
        lock = @{
            value = 'module'
        }
        lock = @{
            value = 'CanNotDelete'
        }
    }
    #>
    [CmdletBinding()]
    param (
        [Parameter()]
        [string] $BicepParamBlock,

        [Parameter()]
        [string] $CurrentFilePath
    )

    if ([String]::IsNullOrEmpty($BicepParamBlock)) {
        # Case: No mandatory parameters
        return @{}
    }

    # [1/4] Detect top level params for later processing
    $bicepParamBlockArray = $BicepParamBlock -split '\n'
    $topLevelParamIndent = ([regex]::Match($bicepParamBlockArray[0], '^(\s+).*')).Captures.Groups[1].Value.Length
    $topLevelParams = $bicepParamBlockArray | Where-Object { $_ -match "^\s{$topLevelParamIndent}[0-9a-zA-Z]+:.*" } | ForEach-Object { ($_ -split ':')[0].Trim() }

    # [2/4] Add JSON-specific syntax to the Bicep param block to enable us to treat is as such
    # [2.1] Syntax: Outer brackets
    $paramInJsonFormat = @(
        '{',
        $BicepParamBlock
        '}'
    ) | Out-String

    # [2.2] Syntax: All double quotes must be escaped & single-quotes are double-quotes
    $paramInJsonFormat = $paramInJsonFormat -replace '"', '\"'
    $paramInJsonFormat = $paramInJsonFormat -replace "'", '"'

    # [2.3] Split the object to format line-by-line (& also remove any empty lines)
    $paramInJSONFormatArray = $paramInJsonFormat -split '\n' | Where-Object { -not [String]::IsNullOrEmpty($_.Trim()) }

    for ($index = 0; $index -lt $paramInJSONFormatArray.Count; $index++) {

        $line = $paramInJSONFormatArray[$index]

        if ($line -match '^\s*\/\/.*') {
            # Line is comment
            continue
        }

        # [2.4] Syntax:
        # - Everything left of a leftest ':' should be wrapped in quotes (as a parameter name is always a string)
        # - However, we don't want to accidentally catch something like "CriticalAddonsOnly=true:NoSchedule"
        [regex]$pattern = '^\s*\"{0}([0-9a-zA-Z_]+):'
        $line = $pattern.replace($line, '"$1":', 1)

        # [2.5] Syntax: Replace Bicep resource ID references
        $mayHaveValue = $line -match '^\s*.+?:\s+'
        if ($mayHaveValue) {

            $lineValue = ($line -split '^\s*.+?:\s+')[1].Trim() # i.e., optional spaces, followed by a name ("xzy"), followed by ':', folowed by at least a space

            # Individual checks
            $isLineWithEmptyObjectValue = $line -match '^.+:\s*{\s*}\s*$' # e.g., test: {}
            $isLineWithObjectPropertyReferenceValue = $lineValue -match '(?<=[^"])\b\.\b(?=[^"]*$)' # e.g., resourceGroupResources.outputs.virtualWWANResourceId, but not "domainName": "onmicrosoft.com"
            $isLineWithReferenceInLineKey = ($line -split ':')[0].Trim() -like '*.*'
            $isLineWithStringNestedReference = $lineValue -match "['|`"]{1}.*\$\{.+" # e.g., "Download ${initializeSoftwareScriptName}"  or '${last(...)}'
            $isLineWithStringValue = $lineValue -match '^".+"$' # e.g. "value"
            $isLineWithFunction = $lineValue -match '^[a-zA-Z0-9]+\(.+' # e.g., split(something) or loadFileAsBase64("./test.pfx")
            $isLineWithPlainValue = $lineValue -match '^\w+$' # e.g. adminPassword: password
            $isLineWithPrimitiveValue = $lineValue -match '^\s*true|false|[0-9]+$' # e.g., isSecure: true
            $isLineContainingCondition = $lineValue -match '^\w+ [=!?|&]{2} .+\?.+\:.+$' # e.g., iteration == "init" ? "A" : "B"

            # Special case: Multi-line function
            $isLineWithMultilineFunction = $lineValue -match '[a-zA-Z]+\s*\([^\)]*\){0}\s*$' # e.g., roleDefinitionIdOrName: subscriptionResourceId( \n 'Microsoft.Authorization/roleDefinitions', \n 'acdd72a7-3385-48ef-bd42-f606fba81ae7' \n )
            $lineProcessed = $false

            if ($isLineWithMultilineFunction) {
                # Search leading indent so that we can use it to identify at which line the function ends
                $indent = ([regex]::Match($paramInJSONFormatArray[$index], '^(\s+)')).Captures.Groups[1].Value.Length

                $functionStartIndex = $index
                $functionEndIndex = $functionStartIndex
                do {
                    $functionEndIndex++
                } while ($paramInJSONFormatArray[$functionEndIndex] -match "^\s{$($indent+1),}" -and $functionEndIndex -lt $paramInJSONFormatArray.Count)

                if ($functionEndIndex -eq $paramInJSONFormatArray.Count) {
                    throw "End index of a multi-line function block for test file [$CurrentFilePath] not found."
                }

                # Overwrite the first line with a default value (i.e., "property": "<property>")
                $line = '{0}: "<{1}>"' -f ($line -split ':')[0], ([regex]::Match(($line -split ':')[0], '"(.+)"')).Captures.Groups[1].Value

                $linesOfFunction = $functionEndIndex - $functionStartIndex

                # Nullify all but first line
                for ($functionIndex = 1; $functionIndex -le $linesOfFunction; $functionIndex++) {
                    $functionLineIndex = $index + $functionIndex
                    $paramInJSONFormatArray[$functionLineIndex] = $null
                }

                # Increase index to skip the function lines
                $index += $indexToIncrease
                $lineProcessed = $true
            } else {
                $hasInlineObject = $line -match '{' -and $line -match '}'
                $colonCount = ([regex]::Matches($line, ':')).Count
                $isSingleLineNestedObject = $hasInlineObject -and $colonCount -gt 1
                if ($isSingleLineNestedObject) {
                    $parameterNameMatch = [regex]::Match(($line -split ':')[0], '"(.+)"')
                    $parameterName = $parameterNameMatch.Success ? $parameterNameMatch.Groups[1].Value : ($line -split ':')[0].Trim().Trim('"')
                    $line = '{0}: "<{1}>"' -f ($line -split ':')[0], $parameterName
                    $lineProcessed = $true
                }
                # Combined checks
                # In case of an output reference like '"virtualWanId": resourceGroupResources.outputs.virtualWWANResourceId' we'll only show "<virtualWanId>" (but NOT e.g. 'reference': {})
                if (-not $lineProcessed) {
                    $isLineWithObjectPropertyReference = -not $isLineWithEmptyObjectValue -and -not $isLineWithStringValue -and $isLineWithObjectPropertyReferenceValue
                    # In case of a parameter/variable reference like 'adminPassword: password' we'll only show "<adminPassword>" (but NOT e.g. enableMe: true)
                    $isLineWithParameterOrVariableReferenceValue = $isLineWithPlainValue -and -not $isLineWithPrimitiveValue
                    # In case of any contained line like ''${resourceGroupResources.outputs.managedIdentityResourceId}': {}' we'll only show "managedIdentityResourceId: {}"
                    $isLineWithObjectReferenceKeyAndEmptyObjectValue = $isLineWithEmptyObjectValue -and $isLineWithReferenceInLineKey
                    # In case of any contained function like '"backupVaultResourceGroup": (split(resourceGroupResources.outputs.recoveryServicesVaultResourceId, "/"))[4]' we'll only show "<backupVaultResourceGroup>"

                    if ($isLineWithObjectPropertyReference -or $isLineWithStringNestedReference -or $isLineWithFunction -or $isLineWithParameterOrVariableReferenceValue -or $isLineContainingCondition) {
                        $line = '{0}: "<{1}>"' -f ($line -split ':')[0], ([regex]::Match(($line -split ':')[0], '"(.+)"')).Captures.Groups[1].Value
                    } elseif ($isLineWithObjectReferenceKeyAndEmptyObjectValue) {
                        $line = '"<{0}>": {1}' -f (($line -split ':')[0] -split '\.')[ -1].TrimEnd('}"'), $lineValue
                    }
                }
            }
        } else {
            if ($line -notlike '*"*"*' -and $line -like '*.*') {
                # In case of a array value like '[ \n -> resourceGroupResources.outputs.managedIdentityPrincipalId <- \n ]' we'll only show "<managedIdentityPrincipalId>""
                $line = '"<{0}>"' -f $line.Split('.')[-1].Trim()
            } elseif ($line -match '^\s*[a-zA-Z]+\s*$') {
                # If there is simply only a value such as a variable reference, we'll wrap it as a string to replace. For example a reference of a variable `addressPrefix` will be replaced with `"<addressPrefix>"`
                $line = '"<{0}>"' -f $line.Trim()
            } elseif ($line -match "['|`"]{1}.*\$\{.+") {
                # If the line contains a string with a reference, we're replacing the reference with a placeholder. For example "pwsh \"${initializeSoftwareScriptName}\"" would only show "pwsh <value>"
                $line = $line -replace '\$\{.+\}', '<value>'
            }
        }

        $paramInJSONFormatArray[$index] = $line
    }

    # [2.6] Remove empty lines
    $paramInJSONFormatArray = $paramInJSONFormatArray | Where-Object { $_ }

    # [2.7] Syntax: Add comma everywhere unless:
    # - the current line has an opening 'object: {' or 'array: [' character
    # - the line after the current line has a closing 'object: }' or 'array: ]' character
    # - it's the last closing bracket
    # - is a comment
    for ($index = 0; $index -lt $paramInJSONFormatArray.Count; $index++) {
        $isOpeningObjectOrArray = $paramInJSONFormatArray[$index] -match '[\{|\[]\s*$'
        $nextLineIsClosingObjectOrArray = ($index -lt $paramInJSONFormatArray.Count - 1) -and $paramInJSONFormatArray[$index + 1] -match '^\s*[\]|\}]\s*$'
        $isLastLine = $index -eq $paramInJSONFormatArray.Count - 1
        $isComment = $paramInJSONFormatArray[$index] -match '^\s*\/\/.*'
        if ($isOpeningObjectOrArray -or $nextLineIsClosingObjectOrArray -or $isLastLine -or $isComment) {
            continue
        }

        if ( $paramInJSONFormatArray[$index] -match '(?<![:\/])\/\/.*$' ) {
            # Has inline comment (i.e., a situation where you have '//' not enclosed by quotes)
            $lineElements = $paramInJSONFormatArray[$index] -split '(?<![:\/])\/\/.*$'
            $paramInJSONFormatArray[$index] = '{0}, // {1}' -f $lineElements[0].Trim(), $lineElements[1].Trim()

        } else {
            $paramInJSONFormatArray[$index] = '{0},' -f $paramInJSONFormatArray[$index].Trim()
        }
    }

    # [2.8] Format the final JSON string to an object to enable processing
    try {
        $paramInJsonFormatObject = $paramInJSONFormatArray | Out-String | ConvertFrom-Json -AsHashtable -Depth 99 -ErrorAction 'Stop'
    } catch {
        throw ('Failed to process file [{0}]. Please check if it properly formatted. Original error message: [{1}]' -f $CurrentFilePath, $_.Exception.Message)
    }
    # [3/4] Inject top-level 'value`' properties
    $paramInJsonFormatObjectWithValue = @{}
    foreach ($paramKey in $topLevelParams) {
        $paramInJsonFormatObjectWithValue[$paramKey] = @{
            value = $paramInJsonFormatObject[$paramKey]
        }
    }

    # [4/4] Return result
    return $paramInJsonFormatObjectWithValue
}
function Build-OrderedJSONObject {
    <#
    .SYNOPSIS
    Sort the given JSON parameters into a new JSON parameter object, all parameter sorted into required & non-required parameters, each sorted alphabetically

    .DESCRIPTION
    Sort the given JSON parameters into a new JSON parameter object, all parameter sorted into required & non-required parameters, each sorted alphabetically.
    The location where required & non-required parameters start is highlighted with by a corresponding comment

    .PARAMETER ParametersJSON
    Mandatory. The parameter JSON object to process

    .PARAMETER RequiredParametersList
    Mandatory. A list of all required top-level (i.e. non-nested) parameter names

    .EXAMPLE
    Build-OrderedJSONObject -RequiredParametersList @('name') -ParametersJSON '{ "lock": { "value": "CanNotDelete" }, "name": { "value": "module" } }'

    Build a formatted Parameter-JSON object with one required parameter. Would result into:

    '{
        "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
        "contentVersion": "1.0.0.0",
        "parameters": {
            // Required parameters
            "name": {
                "value": "module"
            },
            // Non-required parameters
            "lock": {
                "value": "CanNotDelete"
            }
        }
    }'
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string] $ParametersJSON,

        [Parameter(Mandatory = $false)]
        [AllowEmptyCollection()]
        [string[]] $RequiredParametersList = @()
    )

    # [1/9] Sort parameter alphabetically
    $orderedJSONParameters = Get-OrderedParametersJSON -ParametersJSON $ParametersJSON -RequiredParametersList $RequiredParametersList

    # [2/9] Build the ordered parameter file syntax back up
    $jsonExample = ([ordered]@{
            '$schema'      = 'https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#'
            contentVersion = '1.0.0.0'
            parameters     = (-not [String]::IsNullOrEmpty($orderedJSONParameters)) ? $orderedJSONParameters : @{}
        } | ConvertTo-Json -Depth 99)

    # [3/8] If we have at least one required and one other parameter we want to add a comment
    if ($RequiredParametersList.Count -ge 1 -and $OrderedJSONParameters.Keys.Count -ge 2) {

        $jsonExampleArray = $jsonExample -split '\n'

        # [4/8] Check where the 'last' required parameter is located in the example (and what its indent is)
        $parameterToSplitAt = $RequiredParametersList[-1]
        $parameterStartIndex = ($jsonExampleArray | Select-String '.*"parameters": \{.*' | ForEach-Object { $_.LineNumber - 1 })[0]
        $requiredParameterIndent = ([regex]::Match($jsonExampleArray[($parameterStartIndex + 1)], '^(\s+).*')).Captures.Groups[1].Value.Length

        # [5/8] Add a comment where the required parameters start
        $jsonExampleArray = $jsonExampleArray[0..$parameterStartIndex] + ('{0}// Required parameters' -f (' ' * $requiredParameterIndent)) + $jsonExampleArray[(($parameterStartIndex + 1) .. ($jsonExampleArray.Count))]

        # [6/8] Find the location if the last required parameter
        $requiredParameterStartIndex = ($jsonExampleArray | Select-String "^[\s]{$requiredParameterIndent}`"$parameterToSplitAt`": \{.*" | ForEach-Object { $_.LineNumber - 1 })[0]

        # [7/8] If we have more than only required parameters, let's add a corresponding comment
        if ($orderedJSONParameters.Keys.Count -gt $RequiredParametersList.Count ) {
            # Search in rest of array for the next closing bracket with the same indent - and then add the search index (1) & initial index (1) count back in
            $requiredParameterEndIndex = ($jsonExampleArray[($requiredParameterStartIndex + 1)..($jsonExampleArray.Count)] | Select-String "^[\s]{$requiredParameterIndent}\}" | ForEach-Object { $_.LineNumber - 1 })[0] + 1 + $requiredParameterStartIndex

            # Add a comment where the non-required parameters start
            $jsonExampleArray = $jsonExampleArray[0..$requiredParameterEndIndex] + ('{0}// Non-required parameters' -f (' ' * $requiredParameterIndent)) + $jsonExampleArray[(($requiredParameterEndIndex + 1) .. ($jsonExampleArray.Count))]
        }

        # [8/8] Convert the processed array back into a string
        return $jsonExampleArray | Out-String
    }

    return $jsonExample
}
function Add-BicepParameterTypeComment {
    <#
    .SYNOPSIS
        Add comments to indicate required & non-required parameters to the given Bicep example
    .DESCRIPTION
    .NOTES
        'Required' is only added if the example has at least one required parameter
        'Non-Required' is only added if the example has at least one required parameter and at least one non-required parameter
    .LINK
    .EXAMPLE
    #>
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory,
            HelpMessage = 'Mandatory. The Bicep parameter block to add the comments to (i.e., should contain everything in between the brackets of a ''params: {...} block)''')]
        [AllowEmptyString()]
        [string]
        $BicepParams,

        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Mandatory. A list of all top-level (i.e. non-nested) parameter names')]
        [AllowEmptyCollection()]
        [string[]]
        $AllParametersList = @(),

        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Mandatory. A list of all required top-level (i.e. non-nested) parameter names')]
        [AllowEmptyCollection()]
        [string[]]
        $RequiredParametersList = @()
    )

    if ($RequiredParametersList.Count -ge 1 -and $AllParametersList.Count -ge 2) {

        $BicepParamsArray = $BicepParams -split '\n'

        # Check where the 'last' required parameter is located in the example (and what its indent is)
        $parameterToSplitAt = $RequiredParametersList[-1]
        $requiredParameterIndent = ([regex]::Match($BicepParamsArray[0], '^(\s+).*')).Captures.Groups[1].Value.Length

        # Add a comment where the required parameters start
        $BicepParamsArray = @('{0}// Required parameters' -f (' ' * $requiredParameterIndent)) + $BicepParamsArray[(0 .. ($BicepParamsArray.Count))]

        # Find the location if the last required parameter
        $requiredParameterStartIndex = ($BicepParamsArray | Select-String ('^[\s]{0}{1}:.+' -f "{$requiredParameterIndent}", $parameterToSplitAt) | ForEach-Object { $_.LineNumber - 1 })[0]

        # If we have more than only required parameters, let's add a corresponding comment
        if ($AllParametersList.Count -gt $RequiredParametersList.Count) {
            $nextLineIndent = ([regex]::Match($BicepParamsArray[$requiredParameterStartIndex + 1], '^(\s+).*')).Captures.Groups[1].Value.Length
            if ($nextLineIndent -gt $requiredParameterIndent) {
                # Case Param is object/array: Search in rest of array for the next closing bracket with the same indent - and then add the search index (1) & initial index (1) count back in
                $requiredParameterEndIndex = ($BicepParamsArray[($requiredParameterStartIndex + 1)..($BicepParamsArray.Count)] | Select-String "^[\s]{$requiredParameterIndent}\S+" | ForEach-Object { $_.LineNumber - 1 })[0] + 1 + $requiredParameterStartIndex
            } else {
                # Case Param is single line bool/string/int: Add an index (1) for the 'required' comment
                $requiredParameterEndIndex = $requiredParameterStartIndex
            }

            # Add a comment where the non-required parameters start
            $BicepParamsArray = $BicepParamsArray[0..$requiredParameterEndIndex] + ('{0}// Non-required parameters' -f (' ' * $requiredParameterIndent)) + $BicepParamsArray[(($requiredParameterEndIndex + 1) .. ($BicepParamsArray.Count))]
        }

        return ($BicepParamsArray | Out-String).TrimEnd()
    }

    return $BicepParams
}
function Get-OrderedParametersJson {
    <#
    .SYNOPSIS
        Sort the given Json paramters into required and non-required parameters, each sorted alphabetically
    .DESCRIPTION
    .NOTES
    .LINK
    .EXAMPLE
    #>
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory,
            HelpMessage = 'Mandatory. The Json object to order')]
        [string]
        $ParametersJson,

        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Optional. A list of all required top-level (i.e. non-nested) parameter names')]
        [AllowEmptyCollection()]
        [string[]]
        $RequiredParametersList = @()
    )

    # Get all parameters from the parameter object and order them recursively
    $orderedContentInJsonFormat = ConvertTo-OrderedHashtable -JsonInputObject $parametersJson

    # Sort 'required' parameters to the front
    $orderedJsonParameters = [ordered]@{}
    # We must use PS-Base to handle conflicts of HashTable properties and keys (e.g. for a key 'keys').
    $orderedTopLevelParameterNames = $orderedContentInJsonFormat.psbase.Keys
    # Add required parameters first
    $orderedTopLevelParameterNames | Where-Object { $_ -in $RequiredParametersList } | ForEach-Object {
        $orderedJsonParameters[$_] = $orderedContentInJsonFormat[$_]
    }
    # Add rest after
    $orderedTopLevelParameterNames | Where-Object { $_ -notin $RequiredParametersList } | ForEach-Object {
        $orderedJsonParameters[$_] = $orderedContentInJsonFormat[$_]
    }

    # Handle empty dictionaries (in case the parmaeter file was empty)
    if ($orderedJsonParameters.count -eq 0) {
        $orderedJsonParameters = ''
    }

    return $orderedJsonParameters
}
function Merge-FileWithNewContent {
    <#
    .SYNOPSIS
        Merge the sections prior and after the updated content with the new content into on connected content array
    .DESCRIPTION
    .NOTES
    .LINK
    .EXAMPLE
    #>
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory,
            HelpMessage = 'Mandatory. The original content to update')]
        [object[]]
        $OldContent,

        [Parameter(
            Mandatory,
            HelpMessage = 'Mandatory. The new content to merge into the original')]
        [object[]]
        $NewContent,

        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Optional. Tell the function that you''re currently processing a sub-section (indented by one #) by providing the parent identifier')]
        [string]
        $ParentStartIdentifier = '',

        [Parameter(
            Mandatory,
            HelpMessage = 'Mandatory. The identifier/header to search for. If not found, the new section is added at the end of the content array')]
        [string]
        $SectionStartIdentifier,

        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Optional. The type of content to search for. Defaults to ''none''')]
        [ValidateSet(
            'table',
            'list',
            'none',
            'nextH2'
        )]
        [string]
        $ContentType = 'none'
    )

    $startIndex = 0
    while (-not ($OldContent[$startIndex] -eq $SectionStartIdentifier) -and -not ($startIndex -ge $OldContent.Count - 1)) {
        $startIndex++
    }

    # In case we're processing a child section (indented by one #) we should search until the main section starts / end of file is reached
    if ($startIndex -eq $OldContent.Count - 1 -and -not [String]::IsNullOrEmpty($ParentStartIdentifier)) {
        $level = $ParentStartIdentifier.TrimStart().Split(' ')[0]

        $parentSectionStartIndex = 0
        while (-not ($OldContent[$parentSectionStartIndex] -like "*$ParentStartIdentifier") -and -not ($parentSectionStartIndex -ge $OldContent.Count - 1)) {
            $parentSectionStartIndex++
        }

        $startIndex = $parentSectionStartIndex + 1
        while (-not ($OldContent[$startIndex] -like "$level *") -and -not ($startIndex -ge $OldContent.Count - 1)) {
            $startIndex++
        }

        if ($OldContent[$startIndex] -like "$level *") {
            $startIndex--
        }
    }

    if ($startIndex -eq $OldContent.Count - 1 -and [String]::IsNullOrEmpty($ParentStartIdentifier)) {
        # Section is not existing (end of file)
        $startContent = $OldContent
        if ($OldContent[$startIndex] -ne $SectionStartIdentifier ) {
            # Add newline if necessary
            if (-not [String]::IsNullOrEmpty($OldContent[$startIndex])) {
                $startContent += @('')
            }
            # Add section header
            $startContent = $startContent + @($SectionStartIdentifier)
        }
        $endContent = @()
    } else {
        switch ($ContentType) {
            'table' {
                $tableStartIndex = $startIndex + 1
                while (-not $OldContent[$tableStartIndex].StartsWith('|') -and -not ($tableStartIndex -ge $OldContent.count) -and -not ($OldContent[$tableStartIndex].StartsWith('#'))) {
                    $tableStartIndex++
                }
                if ($OldContent[$tableStartIndex].StartsWith('#')) {
                    # Seems like there is no table yet
                    $tableStartIndex = $startIndex + 1
                }

                $startContent = $OldContent[0..($tableStartIndex - 1)]

                if ($startIndex -eq $ReadMeFileContent.Count - 1) {
                    # Not found section until end of file. Assuming it does not exist
                    $endContent = @()
                    if ($ReadMeFileContent[$startIndex] -notcontains $SectionStartIdentifier) {
                        $newContent = @('', $SectionStartIdentifier) + $newContent
                    }
                } else {
                    $endIndex = Get-EndIndex -ReadMeFileContent $OldContent -startIndex $tableStartIndex -ContentType $ContentType
                    if ($endIndex -ne $OldContent.Count - 1) {
                        $endContent = $OldContent[$endIndex..($OldContent.Count - 1)]
                    }
                }
            }
            'list' {
                $listStartIndex = $startIndex + 1
                while (-not $OldContent[$listStartIndex].StartsWith('- ') -and -not ($listStartIndex -ge $OldContent.count) -and -not ($OldContent[$listStartIndex].StartsWith('# '))) {
                    $listStartIndex++
                }
                if ($OldContent[$listStartIndex].StartsWith('#')) {
                    # Seems like there is no table yet
                    $listStartIndex = $listStartIndex + 1
                }

                $startContent = $OldContent[0..($listStartIndex - 1)]

                if ($startIndex -eq $ReadMeFileContent.Count - 1) {
                    # Not found section until end of file. Assuming it does not exist
                    $endContent = @()
                    if ($ReadMeFileContent[$startIndex] -notcontains $SectionStartIdentifier) {
                        $newContent = @('', $SectionStartIdentifier) + $newContent
                    }
                } else {
                    $endIndex = Get-EndIndex -ReadMeFileContent $OldContent -startIndex $listStartIndex -ContentType $ContentType
                    if ($endIndex -ne $OldContent.Count - 1) {
                        $endContent = $OldContent[$endIndex..($OldContent.Count - 1)]
                    }
                }
            }
            'none' {
                if ($OldContent[$startIndex + 1] -like "$level *" -and -not [String]::IsNullOrEmpty($ParentStartIdentifier)) {
                    # section was not found - let's insert it at the end of the sub-section
                    $startContent = $OldContent[0..($startIndex)]
                    $newContent = @($SectionStartIdentifier, '') + $newContent
                    $endContent = $OldContent[($startIndex + 1)..($OldContent.Count - 1)]
                } else {
                    # section was found
                    $startContent = $OldContent[0..($startIndex)]
                    $endIndex = Get-EndIndex -ReadMeFileContent $OldContent -startIndex $startIndex -ContentType $ContentType
                    if ($endIndex -ne $OldContent.Count - 1) {
                        $endContent = $OldContent[$endIndex..($OldContent.Count - 1)]
                    }
                }
            }
            'nextH2' {
                $endIndex = $startIndex + 1

                while (-not $OldContent[$endIndex].StartsWith('## ') -and -not (($endIndex + 1) -ge $OldContent.count)) {
                    $endIndex++
                }

                $startContent = $OldContent[0..($startIndex)]
                if ($endIndex -ne $OldContent.Count - 1) {
                    $endContent = $OldContent[$endIndex..($OldContent.Count - 1)]
                }
            }
            default {}
        }
    }

    # Add a little space
    if ($startContent -and (-not [String]::IsNullOrEmpty($startContent[-1]))) { $startContent += @('') }
    if ($endContent -and (-not [String]::IsNullOrEmpty($endContent[0]))) { $endContent = @('') + $endContent }

    # Build result
    $newContent = (($startContent + $newContent + $endContent) | Out-String).TrimEnd().Replace("`r", '').Split("`n")
    return $newContent
}
function Get-EndIndex {
    <#
    .SYNOPSIS
        Find the array index that represents the end of the current section
    .DESCRIPTION
    .NOTES
    .LINK
    .EXAMPLE
    #>
    param(
        [Parameter(
            Mandatory,
            HelpMessage = 'Mandatory. The content array to search in')]
        [object[]]
        $ReadMeFileContent,

        [Parameter(
            Mandatory,
            HelpMessage = 'Mandatory. The index to start the search from, should usually be the current section''s header index')]
        [int]
        $startIndex,

        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Optional. The type of content to search for. Defaults to ''none''')]
        [ValidateSet(
            'table',
            'list',
            'none'
        )]
        [string]
        $ContentType = 'none'
    )

    # shift one further
    $endIndex = $startIndex + 1

    if ($endIndex -ge $readMeFileContent.Count) {
        # We are at the end of the file
        return $startIndex
    }

    switch ($ContentType) {
        'list' {
            # Identify end of list
            while ($ReadMeFileContent[$endIndex].StartsWith('- ') -and -not ($endIndex -ge $readMeFileContent.Count - 1) -and -not $ReadMeFileContent[$endIndex].StartsWith('#')) {
                $endIndex++
            }
        }
        'table' {
            # Identify end of table
            while ($ReadMeFileContent[$endIndex].StartsWith('|') -and -not ($endIndex -ge $readMeFileContent.Count - 1) -and -not $ReadMeFileContent[$endIndex].StartsWith('#')) {
                $endIndex++
            }
        }
        default {
            # Identify next section
            while (-not $ReadMeFileContent[$endIndex].StartsWith('#') -and -not ($endIndex -ge $readMeFileContent.Count - 1)) {
                $endIndex++
            }
        }
    }

    if ($ReadMeFileContent[$endIndex].StartsWith('#')) {
        # We're already in the next section. Hence the section was empty
        $endIndex--
    }

    return $endIndex
}
function Get-CrossReferencedModuleList {
    <#
    .SYNOPSIS
        Find the array index that represents the end of the current section

    .DESCRIPTION
        As an output you will receive a hashtable that (for each provider namespace) lists the:
        - Directly deployed resources (e.g. via "resource myDeployment 'Microsoft.(..)/(..)@(..)'")
        - Linked remote module tempaltes (e.g. via "module rg 'br/modules:(..):(..)'")

    .PARAMETER Path
        Mandatory. The modules path.

    .NOTES
    .LINK
    .EXAMPLE
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string] $Path
    )

    $repoRoot = ($Path -split '[\/|\\]iac[\/|\\](res|ptn|utl)[\/|\\]')[0]
    # $repoRoot = ($Path -split '[\/|\\]{1}(iac|deployments)[\/|\\]{1}')[0]
    $resultSet = [ordered]@{}

    # Collect data
    if ($Path -like '*iac*') {
        # No files in the [/utilities/] and none in the [/tests/] folder
        $regExNotmatch = '.*[\\|\/]utilities[\\|\/].*|.*[\\|\/]tests[\\|\/].*'
    }
    # elseif ($Path -like '*deploy*') {
    #     # No files in the [/iac/] folder and none in the [/tests/] folder
    #     $regExNotmatch = '.*[\\|\/]iac[\\|\/].*|.*[\\|\/]tests[\\|\/].*'
    # }

    $moduleTemplatePaths = (Get-ChildItem -Path $Path -Recurse -File -Filter '*.bicep').FullName | Where-Object {
        $_ -notmatch $regExNotmatch
    } | Sort-Object -Culture 'en-US'

    $templateMap = @{}
    foreach ($moduleTemplatePath in $moduleTemplatePaths) {
        $templateMap[$moduleTemplatePath] = Get-Content -Path $moduleTemplatePath
    }

    # Process data
    foreach ($moduleTemplatePath in $moduleTemplatePaths) {

        $referenceObject = Get-ReferenceObject -ModuleTemplateFilePath $moduleTemplatePath -TemplateMap $templateMap

        # Convert local absolute references to relative references
        $referenceObject.localPathReferences = $referenceObject.localPathReferences | ForEach-Object {
            # Remove root
            $result = $_ -replace ('{0}[\/|\\]' -f [Regex]::Escape($repoRoot)), ''
            # Use only folder name
            $result = Split-Path $result -Parent
            # Replaces slashes
            $result = $result -replace '\\', '/'

            return $result
        }

        $moduleFolderPath = Split-Path $moduleTemplatePath -Parent

        ## iac/ptn/<provider>/<resourceType>
        $resourceTypeIdentifier = ($moduleFolderPath -split '[\/|\\]iac[\/|\\](res|ptn|utl)[\/|\\]')[2] -replace '\\', '/'

        # if ($moduleFolderPath -like '*iac*') {
        #     $resourceTypeIdentifier = ($moduleFolderPath -split '[\/|\\]{1}res[\/|\\]{1}')[1] -replace '\\', '/'
        # }
        # if ($moduleFolderPath -like '*deployments*') {
        #     $resourceTypeIdentifier = ($moduleFolderPath -split '[\/|\\]{1}deployments[\/|\\]{1}')[1] -replace '\\', '/'
        # }

        # since the moduleTemplatePath can contain folders outside of modules, skip those
        if ($resourceTypeIdentifier -ne '') {
            $providerNamespace = ($resourceTypeIdentifier -split '[\/|\\]')[0]

            # Check if there's a resource type beyond the provider namespace
            if ($resourceTypeIdentifier.Length -gt $providerNamespace.Length) {
                $resourceType = $resourceTypeIdentifier.Substring($providerNamespace.Length + 1)
                $resultSet["$providerNamespace/$resourceType"] = $referenceObject
            } else {
                # If no resource type (single-level path), use empty string or skip
                $resultSet[$providerNamespace] = $referenceObject
            }
        }

        # $providerNamespace = ($resourceTypeIdentifier -split '[\/|\\]')[0]
        # $resourceType = $resourceTypeIdentifier -replace "$providerNamespace[\/|\\]", ''

        # $resultSet["$providerNamespace/$resourceType"] = $referenceObject
    }

    return $resultSet
}
function Get-ReferenceObject {
    <#
    .SYNOPSIS
        Get all references of a given module template

    .DESCRIPTION
        This includes local references, online/remote references & resource deployments

    .PARAMETER ModuleTemplateFilePath
        Mandatory. The path to the template to search the references for

    .PARAMETER TemplateMap
        Mandatory. The hashtable of templatePath-templateContent to search in
    .NOTES
    .LINK
    .EXAMPLE
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string] $ModuleTemplateFilePath,

        [Parameter(Mandatory)]
        [hashtable] $TemplateMap
    )

    $involvedFilePaths = Get-LocallyReferencedFileList -FilePath $ModuleTemplateFilePath -TemplateMap $TemplateMap

    $resultSet = @{
        resourceReferences  = @()
        remoteReferences    = @()

        localPathReferences = $involvedFilePaths | Where-Object {
            $involvedFilePath = $_
            # We only care about module templates
            (Split-Path $involvedFilePath -Leaf) -eq 'main.bicep' -and
            # We only care about a direct references and no children when it comes to returning local references
            (@(@($involvedFilePaths) + @($ModuleTemplateFilePath)) | Where-Object {
                # i.e., if a path has its parent in the list, kick it out
                (Split-Path $involvedFilePath) -match ('{0}[\/|\\].+' -f [Regex]::Escape((Split-Path $_ -Parent)))
            }).count -eq 0
        }
    }

    foreach ($involvedFilePath in (@($ModuleTemplateFilePath) + @($involvedFilePaths))) {
        $moduleContent = $TemplateMap[$involvedFilePath]

        $resultSet.resourceReferences += @() + $moduleContent | Where-Object { $_ -match "^resource .+ '(.+)' .+$" } | ForEach-Object { $matches[1] }
        $resultSet.remoteReferences += @() + $moduleContent | Where-Object { $_ -match "^module .+ '(.+:.+)' .+$" } | ForEach-Object { $matches[1] }
    }

    return @{
        resourceReferences  = $resultSet.resourceReferences | Sort-Object -Culture 'en-US' -Unique
        remoteReferences    = $resultSet.remoteReferences | Sort-Object -Culture 'en-US' -Unique
        localPathReferences = $resultSet.localPathReferences | Sort-Object -Culture 'en-US' -Unique
    }
}
function Get-LocallyReferencedFileList {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string] $FilePath,

        [Parameter(Mandatory = $false)]
        [hashtable] $TemplateMap = @{}
    )

    $resList = @()

    $fileContent = ($TemplateMap.Count -gt 0 -and $TemplateMap.Keys -contains $FilePath) ? $TemplateMap[$FilePath] : (Get-Content $FilePath)

    # original: { $_ -match "^module .+ '(.+.bicep)' .+$" }
    # replaced: { $_ -match "^module (?!.*\bmodule\b).+ '(.+.bicep)' .+$" }
    $resList += $fileContent | Where-Object { $_ -match "^module (?!.*\bmodule\b).+ '(.+.bicep)' .+$" } | ForEach-Object { (Resolve-Path (Join-Path (Split-Path $FilePath) $matches[1])).Path }

    if ($resList.Count -gt 0) {
        foreach ($containedFilePath in $resList) {
            $resList += Get-LocallyReferencedFileList -FilePath $containedFilePath -TemplateMap $TemplateMap
        }
    }

    return  $resList
}
#endregion

function Set-BicepReadMe {
    <#
    .SYNOPSIS
        Update/add the readme that matches the given template file

    .DESCRIPTION
        Update/add the readme that matches the given template file, supports both ARM & bicep templates

    .PARAMETER TemplateFilePath
        Mandatory. The path to the template to update.

    .PARAMETER ReadMeFilePath
        Optional. The path to the readme to update. Defaults to 'README.md' file in the same folder as the template.

    .PARAMETER SectionsToRefresh
        Optional. The sections to update. By default it refreshes all that are supported.
        Currently supports: 'Resource Types', 'Parameters', 'Outputs', 'Navigation'

    .NOTES
    .LINK
    .EXAMPLE

    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory)]
        [string] $TemplateFilePath,

        [Parameter(Mandatory = $false)]
        [string] $ReadMeFilePath = (Join-Path (Split-Path $TemplateFilePath -Parent) 'README.md'),

        [Parameter(Mandatory = $false)]
        [ValidateSet('Resource Types', 'Usage examples', 'Parameters', 'Outputs', 'Cross References', 'Navigation')]
        [string[]] $SectionsToRefresh = @('Resource Types', 'Usage examples', 'Parameters', 'Outputs', 'Cross References', 'Navigation')
    )

    begin {
        Write-Debug ('{0} entered' -f $MyInvocation.MyCommand)
    }

    process {
        try {

            #region Validate input params

            # Check template and make full path
            $TemplateFilePath = Resolve-Path -Path $TemplateFilePath -ErrorAction Stop

            if (-not (Test-Path $TemplateFilePath -PathType 'Leaf')) {
                throw "[$TemplateFilePath] is no valid file path."
            }

            # Build template, if required and get content
            if ((Split-Path -Path $TemplateFilePath -Extension) -eq '.bicep') {
                $templateFileContent = bicep build $TemplateFilePath --stdout | ConvertFrom-Json -AsHashtable
            } else {
                $templateFileContent = ConvertFrom-Json (Get-Content $TemplateFilePath -Encoding 'utf8' -Raw) -ErrorAction 'Stop' -AsHashtable
            }

            if (-not $templateFileContent) {
                throw "Failed to compile [$TemplateFilePath]"
            }

            #endregion

            #region Preserve ReadMe notes

            # Read original readme, if any. Then delete it to build from scratch
            if ((Test-Path $ReadMeFilePath) -and -not ([String]::IsNullOrEmpty((Get-Content $ReadMeFilePath -Raw)))) {
                $readMeFileContent = Get-Content -Path $ReadMeFilePath -Encoding 'utf8'
            }

            # Make sure we preserve any manual notes a user might have added in the corresponding section
            if ($match = $readMeFileContent | Select-String -Pattern '## Notes') {
                $startIndex = $match.LineNumber

                $endIndex = $startIndex + 1

                while (-not (($endIndex + 1) -gt $readMeFileContent.count) -and $readMeFileContent[($endIndex + 1)] -notlike '## *') {
                    $endIndex++
                }

                $notes = $readMeFileContent[($startIndex - 1)..$endIndex]
            } else {
                $notes = @()
            }

            #endregion

            #region Initialize readme

            $moduleRoot = Split-Path $TemplateFilePath -Parent

            $fullModuleIdentifier = ($moduleRoot -split '[\/|\\]iac[\/|\\](res|ptn|utl)[\/|\\]')[2] -replace '\\', '/'
            # $fullModuleIdentifier = ($moduleRoot -split '[\/|\\]{1}(ptn|res|deployments)[\/|\\]{1}')[2] -replace '\\', '/'

            # Custom modules are modules having the same resource type but different properties based on the name
            # E.g., web/site/config--appsetting vs web/site/config--authsettingv2
            $customModuleSeparator = '--'
            if ($fullModuleIdentifier.Contains($customModuleSeparator)) {
                $fullModuleIdentifier = $fullModuleIdentifier.split($customModuleSeparator)[0]
            }

            $inputObject = @{
                ReadMeFilePath       = $ReadMeFilePath
                FullModuleIdentifier = $fullModuleIdentifier
                TemplateFileContent  = $templateFileContent
            }
            $readMeFileContent = Initialize-ReadMe @inputObject

            #endregion

            #region Handle [Resource Types] section

            if ($SectionsToRefresh -contains 'Resource Types') {
                $inputObject = @{
                    ReadMeFileContent   = $readMeFileContent
                    TemplateFileContent = $templateFileContent
                }
                $readMeFileContent = Set-ResourceTypesSection @inputObject
            }

            #endregion

            #region Handle [Usage examples] section

            $hasTests = (Get-ChildItem -Path $moduleRoot -Recurse -Filter 'main.test.bicep' -File -Force).count -gt 0

            if ($SectionsToRefresh -contains 'Usage examples' -and $hasTests) {
                $inputObject = @{
                    ModuleRoot           = $moduleRoot
                    FullModuleIdentifier = $fullModuleIdentifier
                    ReadMeFileContent    = $readMeFileContent
                    TemplateFileContent  = $templateFileContent
                }
                $readMeFileContent = Set-UsageExamplesSection @inputObject
            }

            #endregion

            #region Handle [Parameters] section

            if ($SectionsToRefresh -contains 'Parameters') {

                $inputParams = @{
                    ReadMeFileContent   = $readMeFileContent
                    TemplateFileContent = $templateFileContent
                }
                $readMeFileContent = Set-ParametersSection @inputParams
            }

            #endregion

            #region Handle [Outputs] section

            if ($SectionsToRefresh -contains 'Outputs') {
                $inputObject = @{
                    ReadMeFileContent   = $readMeFileContent
                    TemplateFileContent = $templateFileContent
                }
                $readMeFileContent = Set-OutputsSection @inputObject
            }

            #endregion

            #region Handle [Cross-reference modules] section

            if ($SectionsToRefresh -contains 'Cross References') {
                $inputObject = @{
                    ModuleRoot           = $ModuleRoot
                    FullModuleIdentifier = $fullModuleIdentifier
                    ReadMeFileContent    = $readMeFileContent
                    TemplateFileContent  = $templateFileContent
                    PreLoadedContent     = $PreLoadedContent
                }
                $readMeFileContent = Set-CrossReferencesSection @inputObject
            }

            #endregion

            #region Handle [Notes] section

            if ($notes) {
                $readMeFileContent += @( '' )
                $readMeFileContent += $notes
            }

            #endregion

            #region Handle [Navigation] section

            if ($SectionsToRefresh -contains 'Navigation') {
                $inputObject = @{
                    ReadMeFileContent = $readMeFileContent
                }
                $readMeFileContent = Set-TableOfContent @inputObject
            }

            #endregion

            if (Test-Path $ReadMeFilePath) {
                if ($PSCmdlet.ShouldProcess("File in path [$ReadMeFilePath]", 'Overwrite')) {
                    Set-Content -Path $ReadMeFilePath -Value $readMeFileContent -Force -Encoding 'utf8'
                }
                Write-Verbose "File [$ReadMeFilePath] updated"
            } else {
                if ($PSCmdlet.ShouldProcess("File in path [$ReadMeFilePath]", 'Create')) {
                    $null = New-Item -Path $ReadMeFilePath -Value ($readMeFileContent | Out-String) -Force
                }
                Write-Verbose "File [$ReadMeFilePath] created"
            }

        } catch {
            throw $_
        }
    }

    end {
        Write-Debug ('{0} exited' -f $MyInvocation.MyCommand)
    }
}
function Set-BicepReadMeAll {
    <#
.SYNOPSIS
    This script is used to update/create the README.md file for all Bicep modules in the current folder tree.
.NOTES
.LINK
.EXAMPLE
    Load the script and call the function with the required parameters:
    . src\utl\Set-BicepReadMe.ps1

    Set-BicepReadMeAll -TemplateFilePath 'iac\res'
#>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string] $TemplateFilePath
    )

    begin {
        Write-Debug ('{0} entered' -f $MyInvocation.MyCommand)
    }

    process {
        try {

            # Prompt user to confirm
            $prompt = @(
                'This script will overwrite the README.md file for all Bicep modules in the current folder tree.'
                'Any custom changes will be lost if not saved in the ## Notes section.'
                'Do you want to continue? ''Yes [Y]'' ''No [N]'''
            )

            $result = Read-Host -Prompt $prompt
            $result = $result.ToLower()

            if ($result -eq 'yes' -or $result -eq 'y') {

                # Start timer
                $timer = [System.Diagnostics.Stopwatch]::StartNew()

                # Recursively find all main.bicep files in the folder tree
                $files = Get-ChildItem -Path $TemplateFilePath -Recurse -Filter 'main.bicep'

                Write-Output "Found $($files.Count) main.bicep files"

                $count = 0
                # Loop through each found file and call the Set-BicepReadMe function
                foreach ($file in $files) {
                    $count++
                    Write-Output "Processing file $count of $($files.Count): $($file.FullName)"

                    # Call the Set-BicepReadMe function
                    Set-BicepReadMe -TemplateFilePath $file.FullName
                }

                # Stop timer and get elapsed time
                $timer.Stop()
                $elapsed = $timer.Elapsed

                Write-Output "Elapsed time: $($elapsed.ToString('hh\:mm\:ss'))"
            } elseif ($result -eq 'no' -or $result -eq 'n') {
                Write-Information 'Script stopped by user.' -InformationAction Continue
                exit
            } else {
                Write-Information "Invalid input. Please type 'Yes' or 'No'." -InformationAction Continue
                exit
            }

        } catch {
            throw $_
        }
    }

    end {
        Write-Debug ('{0} exited' -f $MyInvocation.MyCommand)
    }
}
