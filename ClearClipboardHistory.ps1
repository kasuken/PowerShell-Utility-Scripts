<#
.SYNOPSIS
    Clears the clipboard and removes clipboard history (if supported).

.DESCRIPTION
    This script empties the clipboard to ensure no sensitive data remains 
    and removes clipboard history from Windows 10/11 systems where the feature is supported.

.NOTES
    Author: Emanuele Bartolesi
    Version: 1.0
    Created: 2024-11-17

.EXAMPLE
    ./ClearClipboardHistory.ps1
#>

# Function to clear the current clipboard content
function Clear-Clipboard {
    Write-Host "Clearing current clipboard content..." -ForegroundColor Yellow
    try {
        Set-Clipboard -Value $null
        Write-Host "Clipboard content cleared." -ForegroundColor Green
    } catch {
        Write-Warning "Failed to clear the clipboard: $_"
    }
}

# Function to clear clipboard history (Windows 10/11 feature)
function Clear-ClipboardHistory {
    Write-Host "Attempting to clear clipboard history..." -ForegroundColor Yellow
    try {
        # Run the command to clear clipboard history (requires Windows 10/11)
        Invoke-Expression "cmd.exe /c echo | clip"
        $RegPath = "HKCU:\Software\Microsoft\Clipboard"
        if (Test-Path $RegPath) {
            Remove-Item -Path $RegPath -Recurse -Force -ErrorAction Stop
            Write-Host "Clipboard history cleared." -ForegroundColor Green
        } else {
            Write-Host "Clipboard history not found. This feature may not be enabled on your system." -ForegroundColor Cyan
        }
    } catch {
        Write-Warning "Failed to clear clipboard history: $_"
    }
}

# Main execution
Write-Host "Starting Clipboard Cleanup..." -ForegroundColor Cyan

Clear-Clipboard
Clear-ClipboardHistory

Write-Host "Clipboard cleanup completed." -ForegroundColor Green
