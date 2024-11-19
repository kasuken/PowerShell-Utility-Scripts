<#
.SYNOPSIS
    Clears the Microsoft Teams cache to resolve performance or functionality issues.

.DESCRIPTION
    This script stops Microsoft Teams if it is running, deletes the cache files, 
    and restarts Teams to ensure a clean start.

.NOTES
    Author: Emanuele Bartolesi
    Version: 1.0
    Created: 2024-11-19

.EXAMPLE
    ./ClearTeamsCache.ps1
#>

# Function to stop Microsoft Teams
function Stop-Teams {
    Write-Host "Checking if Microsoft Teams is running..." -ForegroundColor Yellow
    $TeamsProcesses = Get-Process -Name Teams -ErrorAction SilentlyContinue
    if ($TeamsProcesses) {
        Write-Host "Stopping Microsoft Teams..." -ForegroundColor Yellow
        Stop-Process -Name Teams -Force
        Write-Host "Microsoft Teams stopped." -ForegroundColor Green
    } else {
        Write-Host "Microsoft Teams is not running." -ForegroundColor Cyan
    }
}

# Function to clear Teams cache
function Clear-TeamsCache {
    $CachePaths = @(
        "$env:APPDATA\Microsoft\Teams\Application Cache\Cache",
        "$env:APPDATA\Microsoft\Teams\Blob_storage",
        "$env:APPDATA\Microsoft\Teams\Cache",
        "$env:APPDATA\Microsoft\Teams\databases",
        "$env:APPDATA\Microsoft\Teams\GPUCache",
        "$env:APPDATA\Microsoft\Teams\IndexedDB",
        "$env:APPDATA\Microsoft\Teams\Local Storage",
        "$env:APPDATA\Microsoft\Teams\tmp"
    )

    Write-Host "Clearing Microsoft Teams cache files..." -ForegroundColor Yellow
    foreach ($Path in $CachePaths) {
        if (Test-Path $Path) {
            Remove-Item -Path $Path -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "Cleared cache at: $Path" -ForegroundColor Green
        } else {
            Write-Host "Path not found: $Path" -ForegroundColor Cyan
        }
    }
    Write-Host "Microsoft Teams cache cleared successfully." -ForegroundColor Green
}

# Function to restart Microsoft Teams
function Restart-Teams {
    Write-Host "Restarting Microsoft Teams..." -ForegroundColor Yellow
    Start-Process -FilePath "$env:LOCALAPPDATA\Microsoft\Teams\current\Teams.exe"
    Write-Host "Microsoft Teams restarted successfully." -ForegroundColor Green
}

# Main script execution
Write-Host "Starting Teams Cache Cleanup..." -ForegroundColor Cyan
Stop-Teams
Clear-TeamsCache
Restart-Teams
Write-Host "Microsoft Teams cache cleanup completed." -ForegroundColor Cyan
