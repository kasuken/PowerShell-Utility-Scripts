<#
.SYNOPSIS
    Automatically backs up important folders to a specified destination.

.DESCRIPTION
    This script copies files from predefined source folders (e.g., Documents) to a target destination.
    The folder structure is preserved, and only new or updated files are copied.

.NOTES
    Author: Emanuele Bartolesi
    Version: 1.0
    Created: 2024-11-17

.PARAMETER SourcePaths
    Array of folder paths to back up.

.PARAMETER DestinationPath
    Path to the backup location (e.g., an external drive or cloud folder).

.PARAMETER LogFilePath
    Path to the log file where backup activity is recorded.

.EXAMPLE
    ./AutomatedFolderBackup.ps1 -SourcePaths "C:\Users\YourName\Documents" -DestinationPath "E:\Backups" -LogFilePath "C:\Logs\BackupLog.txt"
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string[]]$SourcePaths,

    [Parameter(Mandatory = $true)]
    [string]$DestinationPath,

    [Parameter(Mandatory = $false)]
    [string]$LogFilePath = "$env:USERPROFILE\Documents\BackupLog.txt"
)

# Function to log messages
function Write-Log {
    param (
        [string]$Message
    )
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogEntry = "$Timestamp - $Message"
    Write-Output $LogEntry
    Add-Content -Path $LogFilePath -Value $LogEntry
}

# Function to perform the backup
function Perform-Backup {
    param (
        [string[]]$SourceFolders,
        [string]$Destination
    )
    foreach ($Source in $SourceFolders) {
        if (Test-Path $Source) {
            $DestinationFolder = Join-Path -Path $Destination -ChildPath (Split-Path -Path $Source -Leaf)
            if (-not (Test-Path $DestinationFolder)) {
                New-Item -ItemType Directory -Path $DestinationFolder | Out-Null
                Write-Log "Created destination folder: $DestinationFolder"
            }

            Write-Log "Starting backup for folder: $Source"
            # Use Robocopy for efficient file copying
            $RobocopyArgs = @(
                $Source
                $DestinationFolder
                "/E"                # Copy all subdirectories, including empty ones
                "/XO"               # Exclude older files
                "/XN"               # Exclude newer files
                "/R:2"              # Retry 2 times on failure
                "/W:5"              # Wait 5 seconds between retries
                "/LOG+:$LogFilePath" # Append to log file
            )
            Start-Process -FilePath "robocopy" -ArgumentList $RobocopyArgs -NoNewWindow -Wait
            Write-Log "Backup completed for folder: $Source"
        } else {
            Write-Log "Source folder not found: $Source"
        }
    }
}

# Main script execution
Write-Log "Starting automated folder backup..."

# Ensure the destination path exists
if (-not (Test-Path $DestinationPath)) {
    New-Item -ItemType Directory -Path $DestinationPath | Out-Null
    Write-Log "Created destination path: $DestinationPath"
}

# Perform the backup
Perform-Backup -SourceFolders $SourcePaths -Destination $DestinationPath

Write-Log "Automated folder backup completed successfully."
Write-Host "Backup completed. Check the log for details: $LogFilePath" -ForegroundColor Green
