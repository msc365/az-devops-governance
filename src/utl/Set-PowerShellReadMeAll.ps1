#Requires -Version 7.0
<#
.SYNOPSIS
    Batch processes multiple PowerShell scripts to generate or update their README.md files.

.DESCRIPTION
    This script recursively finds all main.ps1 files in a specified folder tree and generates
    or updates their README.md documentation files. It provides a convenient way to ensure
    all PowerShell scripts in a project have up-to-date documentation.

.PARAMETER Path
    Required.  The root path to search for PowerShell scripts.

.PARAMETER ScriptFilter
    Optional. The file name pattern to search for. Defaults to 'main.ps1'.

.PARAMETER Force
    Optional. Skip confirmation prompt and process all files immediately.

.EXAMPLE
    .\src\utl\Set-PowerShellReadMeAll.ps1 -Path '.\src\res'

    Finds all main.ps1 files in the src\res folder tree and generates/updates their READMEs.

.EXAMPLE
    .\src\utl\Set-PowerShellReadMeAll.ps1 -Path '.\src' -ScriptFilter '*.ps1' -Force

    Processes all PowerShell scripts in the src folder tree without confirmation.

.NOTES
    Version: 1.0
    Author: Martin Swinkels
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string] $Path = './src/res',

    [Parameter(Mandatory = $false)]
    [string] $ScriptFilter = 'main.ps1',

    [Parameter()]
    [switch] $Force
)

begin {
    Write-Debug ('{0} entered' -f $MyInvocation.MyCommand)

    # Ensure the Set-PowerShellReadMe.ps1 script is available
    $setReadMeScript = Join-Path -Path $PSScriptRoot -ChildPath 'Set-PowerShellReadMe.ps1'

    if (-not (Test-Path -Path $setReadMeScript)) {
        throw "Required script not found: $setReadMeScript"
    }

    # Load the Set-PowerShellReadMe function
    . $setReadMeScript
}

process {
    try {
        # Validate path
        if (-not (Test-Path -Path $Path)) {
            throw "Path not found: $Path"
        }

        $Path = Resolve-Path -Path $Path

        # Prompt user to confirm unless -Force is used
        if (-not $Force.IsPresent) {
            $prompt = @(
                'This script will generate or update README.md files for all matching PowerShell scripts in the folder tree.'
                "Path: $Path"
                "Filter: $ScriptFilter"
                'Any custom changes will be lost if not saved in the ## Notes section.'
                "Do you want to continue? 'Yes [Y]' 'No [N]'"
            ) -join "`n"

            $result = Read-Host -Prompt $prompt
            $result = $result.ToLower()

            if ($result -ne 'y' -and $result -ne 'yes') {
                Write-Information 'Operation cancelled by user.' -InformationAction Continue
                return
            }
        }

        # Start timer
        $timer = [System.Diagnostics.Stopwatch]::StartNew()

        # Find all matching PowerShell script files
        Write-Host "Searching for '$ScriptFilter' files in '$Path'..." -ForegroundColor Cyan
        $scriptFiles = Get-ChildItem -Path $Path -Recurse -Filter $ScriptFilter -File

        if ($scriptFiles.Count -eq 0) {
            Write-Warning "No files matching '$ScriptFilter' found in '$Path'"
            return
        }

        Write-Host "Found $($scriptFiles.Count) script file(s)" -ForegroundColor Green
        Write-Host ''

        $count = 0
        $successCount = 0
        $failedFiles = @()

        # Process each file
        foreach ($file in $scriptFiles) {
            $count++

            Write-Host "[$count/$($scriptFiles.Count)] Processing: " -NoNewline -ForegroundColor Cyan
            Write-Host $file.FullName -ForegroundColor White

            try {
                # Call Set-PowerShellReadMe for each file
                Set-PowerShellReadMe -ScriptFilePath $file.FullName -Verbose:$VerbosePreference -ErrorAction Stop
                $successCount++
                Write-Host '  ✓ Success' -ForegroundColor Green
            } catch {
                Write-Host "  ✗ Failed: $($_.Exception.Message)" -ForegroundColor Red
                $failedFiles += @{
                    File  = $file.FullName
                    Error = $_.Exception.Message
                }
            }

            Write-Host ''
        }

        # Stop timer
        $timer.Stop()
        $elapsed = $timer.Elapsed

        # Summary
        Write-Host '======================================' -ForegroundColor Cyan
        Write-Host 'Summary' -ForegroundColor Cyan
        Write-Host '======================================' -ForegroundColor Cyan
        Write-Host "Total files processed: $count"
        Write-Host "Successful: $successCount" -ForegroundColor Green
        Write-Host "Failed: $($failedFiles.Count)" -ForegroundColor $(if ($failedFiles.Count -gt 0) { 'Red' } else { 'Green' })
        Write-Host "Elapsed time: $($elapsed.ToString('hh\:mm\:ss'))"
        Write-Host ''

        # Display failed files if any
        if ($failedFiles.Count -gt 0) {
            Write-Host 'Failed files:' -ForegroundColor Red
            foreach ($failed in $failedFiles) {
                Write-Host "  - $($failed.File)" -ForegroundColor Red
                Write-Host "    Error: $($failed.Error)" -ForegroundColor Yellow
            }
        }

    } catch {
        throw $_
    }
}

end {
    Write-Debug ('{0} exited' -f $MyInvocation.MyCommand)
}
