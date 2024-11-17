<#
.SYNOPSIS
    Performs a scheduled cleanup of temporary files, recycle bin, and browser caches.

.DESCRIPTION
    This script is designed to clean up unnecessary files from the system, including:
    - Temporary files
    - Recycle bin contents
    - Browser caches (Microsoft Edge, Google Chrome, and Mozilla Firefox)

.NOTES
    Author: Emanuele Bartolesi
    Version: 1.0
    Created: 2024-11-17

.EXAMPLE
    ./ScheduledSystemCleanup.ps1
#>

# Enable verbose output for detailed logging
[CmdletBinding()]
param (
    [switch]$VerboseLogging
)

# Define paths for cleanup
$TempPaths = @(
    "$env:TEMP\*",
    "$env:LOCALAPPDATA\Temp\*"
)
$BrowserCachePaths = @(
    "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache\*",
    "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache\*",
    "$env:APPDATA\Mozilla\Firefox\Profiles\*\cache2\entries\*"
)

# Function to remove files from a given path
function Clear-Files {
    param (
        [string[]]$Paths
    )

    foreach ($Path in $Paths) {
        Write-Verbose "Clearing files from: $Path"
        if (Test-Path $Path) {
            Get-ChildItem -Path $Path -Force -Recurse | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
            Write-Verbose "Files removed from: $Path"
        } else {
            Write-Verbose "Path not found: $Path"
        }
    }
}

# Function to empty the recycle bin
function Clear-RecycleBin {
    Write-Verbose "Emptying the recycle bin..."
    try {
        (New-Object -ComObject Shell.Application).Namespace(10).Items() | ForEach-Object { $_.InvokeVerb("delete") }
        Write-Verbose "Recycle bin emptied."
    } catch {
        Write-Warning "Failed to clear the recycle bin: $_"
    }
}

# Main cleanup process
Write-Host "Starting Scheduled System Cleanup..." -ForegroundColor Green

# Clear temporary files
Write-Host "Clearing temporary files..."
Clear-Files -Paths $TempPaths

# Empty recycle bin
Write-Host "Emptying recycle bin..."
Clear-RecycleBin

# Clear browser caches
Write-Host "Clearing browser caches..."
Clear-Files -Paths $BrowserCachePaths

Write-Host "System cleanup completed successfully!" -ForegroundColor Green

# End of script
