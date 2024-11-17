<#
.SYNOPSIS
    Automates system shutdown, restart, or sleep mode at a scheduled time.

.DESCRIPTION
    This script schedules and performs system power actions (shutdown, restart, or sleep) at a specified time. 
    It provides options for user configuration and logs the actions.

.NOTES
    Author: Emanuele Bartolesi
    Version: 1.0
    Created: 2024-11-17

.PARAMETER Action
    Specifies the action to take: Shutdown, Restart, or Sleep.

.PARAMETER ScheduledTime
    Specifies the time for the action in HH:mm format (24-hour clock).

.PARAMETER LogFilePath
    Path to the log file where power actions are recorded.

.EXAMPLE
    ./AutomatedPowerControl.ps1 -Action Shutdown -ScheduledTime "23:30" -LogFilePath "C:\Logs\PowerControlLog.txt"
    
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [ValidateSet("Shutdown", "Restart", "Sleep")]
    [string]$Action,

    [Parameter(Mandatory = $true)]
    [string]$ScheduledTime,

    [Parameter(Mandatory = $false)]
    [string]$LogFilePath = "$env:USERPROFILE\Documents\PowerControlLog.txt"
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

# Function to calculate the delay until the scheduled time
function Get-DelayUntil {
    param (
        [string]$Time
    )
    $CurrentTime = Get-Date
    $TargetTime = Get-Date -Format "yyyy-MM-dd" | ForEach-Object { "$_ $Time" } | Get-Date
    if ($TargetTime -lt $CurrentTime) {
        $TargetTime = $TargetTime.AddDays(1)
    }
    return ($TargetTime - $CurrentTime).TotalMilliseconds
}

# Main script execution
try {
    Write-Host "Automated Power Control Script" -ForegroundColor Cyan
    Write-Log "Script started. Scheduled action: $Action at $ScheduledTime"

    # Calculate delay until the scheduled time
    $DelayMilliseconds = Get-DelayUntil -Time $ScheduledTime
    Write-Log "Delay calculated: $DelayMilliseconds milliseconds"

    if ($DelayMilliseconds -le 0) {
        throw "Scheduled time must be in the future."
    }

    # Wait until the scheduled time
    Start-Sleep -Milliseconds $DelayMilliseconds

    # Perform the selected action
    switch ($Action) {
        "Shutdown" {
            Write-Log "Performing shutdown..."
            Stop-Computer -Force
        }
        "Restart" {
            Write-Log "Performing restart..."
            Restart-Computer -Force
        }
        "Sleep" {
            Write-Log "Putting system to sleep..."
            rundll32.exe powrprof.dll,SetSuspendState 0,1,0
        }
    }
} catch {
    Write-Warning "An error occurred: $_"
    Write-Log "Error: $_"
} finally {
    Write-Log "Script execution completed."
    Write-Host "Action completed. Check the log for details: $LogFilePath" -ForegroundColor Green
}
