<#
.SYNOPSIS
    Lists and removes applications from the system startup.

.DESCRIPTION
    This script retrieves applications configured to start on system boot
    from common startup locations (registry and startup folder) and provides
    an option to remove them.

.NOTES
    Author: Emanuele Bartolesi
    Version: 1.0
    Created: 2024-11-17

.EXAMPLE
    ./ManageStartupApps.ps1
#>

[CmdletBinding()]
param (
    [switch]$ListOnly
)

# Function to retrieve startup items from the registry
function Get-StartupAppsFromRegistry {
    $StartupPaths = @(
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run",
        "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run"
    )

    foreach ($Path in $StartupPaths) {
        if (Test-Path $Path) {
            Get-ItemProperty -Path $Path | ForEach-Object {
                [PSCustomObject]@{
                    Name = $_.PSChildName
                    Path = $Path
                    Command = $_.PSObject.Properties.Value
                    Source = "Registry"
                }
            }
        }
    }
}

# Function to retrieve startup items from the startup folder
function Get-StartupAppsFromFolder {
    $StartupFolders = @(
        "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup",
        "$env:ALLUSERSPROFILE\Microsoft\Windows\Start Menu\Programs\Startup"
    )

    foreach ($Folder in $StartupFolders) {
        if (Test-Path $Folder) {
            Get-ChildItem -Path $Folder -File | ForEach-Object {
                [PSCustomObject]@{
                    Name = $_.Name
                    Path = $Folder
                    Command = $_.FullName
                    Source = "Startup Folder"
                }
            }
        }
    }
}

# Function to remove a startup item
function Remove-StartupApp {
    param (
        [string]$Name,
        [string]$Source,
        [string]$Path
    )

    try {
        switch ($Source) {
            "Registry" {
                Remove-ItemProperty -Path $Path -Name $Name -ErrorAction Stop
                Write-Host "Removed $Name from registry startup path: $Path" -ForegroundColor Green
            }
            "Startup Folder" {
                Remove-Item -Path (Join-Path -Path $Path -ChildPath $Name) -ErrorAction Stop
                Write-Host "Removed $Name from startup folder: $Path" -ForegroundColor Green
            }
        }
    } catch {
        Write-Warning "Failed to remove $Name: $_"
    }
}

# Main script execution
Write-Host "Retrieving startup applications..." -ForegroundColor Cyan

# Retrieve startup apps from both registry and folder
$StartupApps = Get-StartupAppsFromRegistry
$StartupApps += Get-StartupAppsFromFolder

if (-not $StartupApps) {
    Write-Host "No startup applications found." -ForegroundColor Yellow
    return
}

# Display the list of startup apps
$StartupApps | Format-Table -AutoSize

if ($ListOnly) {
    Write-Host "List-only mode enabled. Exiting..." -ForegroundColor Cyan
    return
}

# Prompt user to remove apps
$SelectedApps = $StartupApps | Out-GridView -Title "Select Startup Apps to Remove" -PassThru

if (-not $SelectedApps) {
    Write-Host "No apps selected for removal. Exiting..." -ForegroundColor Cyan
    return
}

# Remove selected apps
foreach ($App in $SelectedApps) {
    Remove-StartupApp -Name $App.Name -Source $App.Source -Path $App.Path
}

Write-Host "Startup app management completed." -ForegroundColor Green
