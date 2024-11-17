<#
.SYNOPSIS
    Automatically locks the screen after inactivity or at a scheduled time.

.DESCRIPTION
    This script locks the screen:
    - After a specified period of inactivity.
    - At a user-defined scheduled time.
    It can monitor user activity and lock the screen proactively.

.NOTES
    Author: Emanuele Bartolesi
    Version: 1.0
    Created: 2024-11-17

.PARAMETER InactivityTimeout
    Number of seconds of inactivity before locking the screen.

.PARAMETER ScheduledTime
    Time in HH:mm format (24-hour clock) to lock the screen.

.EXAMPLE
    ./AutoLockScreen.ps1 -InactivityTimeout 300

.EXAMPLE
    ./AutoLockScreen.ps1 -ScheduledTime "22:00"

.EXAMPLE
    ./AutoLockScreen.ps1 -InactivityTimeout 300 -ScheduledTime "22:00"
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [int]$InactivityTimeout,

    [Parameter(Mandatory = $false)]
    [string]$ScheduledTime
)

# Function to monitor inactivity and lock screen
function Monitor-Inactivity {
    param (
        [int]$Timeout
    )
    Write-Host "Monitoring inactivity. Timeout: $Timeout seconds..." -ForegroundColor Yellow
    $WMIQuery = "SELECT * FROM Win32_PerfFormattedData_PerfOS_System"
    $LastInputTime = (Get-CimInstance -Query $WMIQuery).SystemUpTime

    while ($true) {
        Start-Sleep -Seconds 5
        $CurrentInputTime = (Get-CimInstance -Query $WMIQuery).SystemUpTime
        $IdleTime = $CurrentInputTime - $LastInputTime

        if ($IdleTime -gt $Timeout) {
            Write-Host "Inactivity timeout reached. Locking the screen..." -ForegroundColor Green
            Lock-Screen
            break
        }
    }
}

# Function to calculate delay until a scheduled time
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

# Function to lock the screen
function Lock-Screen {
    Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public class LockWorkstation {
    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool LockWorkStation();
}
"@
    [LockWorkstation]::LockWorkStation()
}

# Main script logic
Write-Host "Starting Auto-Lock Screen Script..." -ForegroundColor Cyan

# Monitor inactivity if timeout is specified
if ($InactivityTimeout) {
    Start-Job -ScriptBlock {
        Monitor-Inactivity -Timeout $using:InactivityTimeout
    }
    Write-Host "Inactivity monitoring started." -ForegroundColor Green
}

# Schedule lock if a time is specified
if ($ScheduledTime) {
    Write-Host "Scheduling screen lock at $ScheduledTime..." -ForegroundColor Yellow
    $DelayMilliseconds = Get-DelayUntil -Time $ScheduledTime
    Start-Sleep -Milliseconds $DelayMilliseconds
    Write-Host "Scheduled time reached. Locking the screen..." -ForegroundColor Green
    Lock-Screen
}

Write-Host "Auto-lock screen script execution completed." -ForegroundColor Cyan
