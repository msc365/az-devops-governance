# PowerShell README Generator Utilities

This folder contains utilities for generating and maintaining README.md files for PowerShell scripts in this repository.

## Overview

These utilities are inspired by the `setReadMe.ps1` script used for Bicep templates, but adapted specifically for PowerShell script documentation. They automatically extract metadata, parameters, examples, and dependencies from PowerShell scripts to create comprehensive README documentation.

## Scripts

### Set-PowerShellReadMe.ps1

Generates or updates README.md files for individual PowerShell scripts.

**Features:**
- Extracts PSScriptInfo metadata (version, author, tags, etc.)
- Parses comment-based help (synopsis, description, parameters, examples)
- Analyzes parameter blocks for type information and requirements
- Detects module dependencies from #Requires and Import-Module statements
- Finds related scripts (modules, tests, deployment scripts)
- Generates formatted parameter tables
- Creates table of contents with navigation links
- Preserves manual notes in a dedicated "Notes" section

**Usage:**

```powershell
# Generate README for a single script
. .\src\utl\Set-PowerShellReadMe.ps1
Set-PowerShellReadMe -ScriptFilePath '.\src\res\service-connection\main.ps1'

# Update specific sections only
Set-PowerShellReadMe -ScriptFilePath '.\main.ps1' -SectionsToRefresh @('Parameters', 'Examples')

# Specify custom README path
Set-PowerShellReadMe -ScriptFilePath '.\main.ps1' -ReadMeFilePath '.\docs\README.md'
```

**Parameters:**
- `ScriptFilePath` - Path to the PowerShell script to document (mandatory)
- `ReadMeFilePath` - Path to the README file (optional, defaults to README.md in same folder)
- `SectionsToRefresh` - Array of sections to update (optional, defaults to all sections)

**Sections Generated:**
- Description
- Parameters (with type, required status, and defaults)
- Examples (from .EXAMPLE blocks)
- Outputs (from [OutputType] or .OUTPUTS)
- Dependencies (PowerShell modules)
- Related Scripts (module files, test files, deploy scripts)
- Navigation (table of contents)

---

### Set-PowerShellReadMeAll.ps1

Batch processes multiple PowerShell scripts to generate or update their README files.

**Features:**
- Recursively searches for PowerShell scripts in a folder tree
- Processes all matching scripts in a single operation
- Provides progress tracking and summary statistics
- Handles errors gracefully with detailed error reporting
- Includes timer for performance tracking

**Usage:**

```powershell
# Process all main.ps1 files in a folder tree
. .\src\utl\Set-PowerShellReadMeAll.ps1
Set-PowerShellReadMeAll -Path '.\src\res'

# Process all PowerShell scripts (not just main.ps1)
Set-PowerShellReadMeAll -Path '.\src' -ScriptFilter '*.ps1' -Force

# Interactive mode with confirmation
Set-PowerShellReadMeAll -Path '.\src\res'
```

**Parameters:**
- `Path` - Root path to search for scripts (mandatory)
- `ScriptFilter` - File name pattern to match (optional, defaults to 'main.ps1')
- `Force` - Skip confirmation prompt (optional)

**Output Example:**
```
Searching for 'main.ps1' files in 'C:\_git\az-devops-governance\src\res'...
Found 5 script file(s)

[1/5] Processing: C:\_git\az-devops-governance\src\res\environment\main.ps1
  ✓ Success

[2/5] Processing: C:\_git\az-devops-governance\src\res\group\main.ps1
  ✓ Success

...

======================================
Summary
======================================
Total files processed: 5
Successful: 5
Failed: 0
Elapsed time: 00:00:03
```

## Best Practices

### Writing Documentation-Friendly Scripts

To get the best results from these README generators, follow these practices:

1. **Use PSScriptInfo**: Include metadata at the top of your script
   ```powershell
   <#PSScriptInfo
       .VERSION 1.0
       .AUTHOR Your Name
       .COMPANYNAME Your Company
       .TAGS 'Azure', 'DevOps'
       .EXTERNALMODULEDEPENDENCIES Az.Accounts, Az.Resources
   #>
   ```

2. **Write Comprehensive Comment-Based Help**: Include synopsis, description, parameters, and examples
   ```powershell
   <#
   .SYNOPSIS
       Brief one-line description

   .DESCRIPTION
       Detailed multi-line description

   .PARAMETER ParameterName
       Description of what this parameter does

   .EXAMPLE
       .\script.ps1 -Parameter "value"
       Description of what this example does
   #>
   ```

3. **Use [OutputType] Attribute**: Specify the type your script returns
   ```powershell
   [CmdletBinding()]
   [OutputType([pscustomobject])]
   param(...)
   ```

4. **Document All Parameters**: Every parameter should have a .PARAMETER block

5. **Preserve Custom Content**: Use the "Notes" section for manual additions that won't be overwritten

### Maintaining READMEs

- Run `Set-PowerShellReadMeAll` periodically to keep all documentation up to date
- Always review generated READMEs before committing
- Store custom content in the "Notes" section which is preserved across updates
- Use `-SectionsToRefresh` to update specific sections without regenerating everything

## Comparison with Bicep setReadMe.ps1

| Feature | Bicep setReadMe.ps1 | PowerShell Set-PowerShellReadMe.ps1 |
|---------|---------------------|-------------------------------------|
| Target | Bicep templates | PowerShell scripts |
| Metadata Source | Template JSON | PSScriptInfo + Comment-based help |
| Parameters | From template schema | From param block + help |
| Examples | Test files (.test.bicep) | .EXAMPLE blocks |
| Dependencies | Module references | #Requires + Import-Module |
| Resource Types | Azure resources deployed | N/A |
| Cross References | Linked modules | Related scripts |

## Examples

### Example 1: Generate README for a Single Script

```powershell
. .\src\utl\Set-PowerShellReadMe.ps1
Set-PowerShellReadMe -ScriptFilePath '.\src\res\service-connection\main.ps1' -Verbose
```

### Example 2: Update All READMEs in a Folder

```powershell
. .\src\utl\Set-PowerShellReadMeAll.ps1
Set-PowerShellReadMeAll -Path '.\src\res' -Force
```

### Example 3: Update Only Parameters and Examples

```powershell
. .\src\utl\Set-PowerShellReadMe.ps1
Set-PowerShellReadMe `
    -ScriptFilePath '.\main.ps1' `
    -SectionsToRefresh @('Parameters', 'Examples')
```

## Troubleshooting

### README is Missing Sections

- Ensure your script has proper comment-based help
- Check that .PARAMETER blocks match actual parameter names
- Verify .EXAMPLE blocks are properly formatted

### Dependencies Not Detected

- Use `#Requires -Modules ModuleName` at the top of your script
- Or specify in PSScriptInfo: `.EXTERNALMODULEDEPENDENCIES`
- Import-Module statements are also detected (avoid variables in module names)

### Examples Not Showing

- Ensure .EXAMPLE blocks are in the comment-based help section
- Check that there's proper separation between sections (blank lines)
- Examples should be in the `<#...#>` block before the param section

## Version History

- **1.0** (2025-12-13) - Initial release
  - Set-PowerShellReadMe.ps1: Single script README generation
  - Set-PowerShellReadMeAll.ps1: Batch processing utility

## Author

Martin Swinkels

## See Also

- [PowerShell Comment-Based Help](https://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_comment_based_help)
- [PSScriptInfo](https://learn.microsoft.com/powershell/module/powershellget/about/about_module_manifest)
