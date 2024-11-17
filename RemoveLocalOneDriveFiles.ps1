<#
.SYNOPSIS
    Removes local copies of OneDrive files while keeping them online.

.DESCRIPTION
    This script goes through your OneDrive folder and removes the local copies of files by marking them as "Online-Only" using the `attrib` command. This frees up disk space without deleting the files from the cloud.

.NOTES
    Author: Emanuele Bartolesi
    Version: 1.0
    Created: 2024-11-17

.PARAMETER OneDrivePath
    Path to the local OneDrive folder (default: "$env:USERPROFILE\OneDrive").

.EXAMPLE
    ./RemoveLocalOneDriveFiles.ps1

.EXAMPLE
    ./RemoveLocalOneDriveFiles.ps1 -OneDrivePath "C:\Users\YourName\OneDrive"
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$OneDrivePath = "$env:USERPROFILE\OneDrive"
)

# Function to free up space for a specific folder
function Free-UpSpace {
    param (
        [string]$Path
    )

    Write-Host "Processing folder: $Path" -ForegroundColor Yellow

    if (Test-Path $Path) {
        # Mark all files in the folder as "Online-Only" using the `attrib` command
        Get-ChildItem -Path $Path -Recurse -File | ForEach-Object {
            try {
                Write-Verbose "Setting file as 'Online-Only': $($_.FullName)"
                attrib +U -P $_.FullName
            } catch {
                Write-Warning "Failed to process file: $($_.FullName). Error: $_"
            }
        }

        Write-Host "Local files in '$Path' are now 'Online-Only'." -ForegroundColor Green
    } else {
        Write-Warning "The path '$Path' does not exist. Please check the OneDrive path."
    }
}

# Main script execution
Write-Host "Removing local copies of OneDrive files..." -ForegroundColor Cyan

# Call the function to free up space
Free-UpSpace -Path $OneDrivePath

Write-Host "Local OneDrive files have been set to 'Online-Only'." -ForegroundColor Green
