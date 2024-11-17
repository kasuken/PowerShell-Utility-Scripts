<#
.SYNOPSIS
    Performs a system health check by analyzing CPU, RAM, and disk usage.

.DESCRIPTION
    This script collects and reports system health metrics, including:
    - CPU usage
    - RAM usage
    - Disk usage (for all drives)
    The report can be displayed on the console or saved to a file.

.NOTES
    Author: Emanuele Bartolesi
    Version: 1.0
    Created: 2024-11-17

.PARAMETER SaveReport
    Optional path to save the system health report.

.EXAMPLE
    ./SystemHealthCheck.ps1

.EXAMPLE
    ./SystemHealthCheck.ps1 -SaveReport "C:\Reports\SystemHealthReport.txt"

    System Health Report:

    Metric               Value
    ------               -----
    CPU Usage (%)        15.23

    Metric            TotalMemoryGB UsedMemoryGB FreeMemoryGB UsagePercentage
    ------            ------------- ------------ ------------ ---------------
    RAM Usage (GB)    16            8.5          7.5          53.12

    Drive TotalSpaceGB UsedSpaceGB FreeSpaceGB UsagePercentage
    ----- ------------ ------------ ----------- ---------------
    C:    500          200          300         40
    D:    1000         750          250         75

#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$SaveReport
)

# Function to get CPU usage
function Get-CPUUsage {
    $CPUCounter = Get-Counter '\Processor(_Total)\% Processor Time'
    [PSCustomObject]@{
        Metric = "CPU Usage (%)"
        Value  = [math]::Round($CPUCounter.CounterSamples.CookedValue, 2)
    }
}

# Function to get RAM usage
function Get-RAMUsage {
    $Memory = Get-CimInstance -ClassName Win32_OperatingSystem
    $TotalMemory = [math]::Round($Memory.TotalVisibleMemorySize / 1MB, 2)
    $FreeMemory = [math]::Round($Memory.FreePhysicalMemory / 1MB, 2)
    $UsedMemory = [math]::Round($TotalMemory - $FreeMemory, 2)
    $UsagePercentage = [math]::Round(($UsedMemory / $TotalMemory) * 100, 2)
    
    [PSCustomObject]@{
        Metric           = "RAM Usage (GB)"
        TotalMemoryGB    = $TotalMemory
        UsedMemoryGB     = $UsedMemory
        FreeMemoryGB     = $FreeMemory
        UsagePercentage  = $UsagePercentage
    }
}

# Function to get Disk usage
function Get-DiskUsage {
    Get-PSDrive -PSProvider FileSystem | ForEach-Object {
        $TotalSpace = [math]::Round($_.Used + $_.Free / 1GB, 2)
        $UsedSpace = [math]::Round($_.Used / 1GB, 2)
        $FreeSpace = [math]::Round($_.Free / 1GB, 2)
        $UsagePercentage = [math]::Round(($UsedSpace / $TotalSpace) * 100, 2)

        [PSCustomObject]@{
            Drive           = $_.Name
            TotalSpaceGB    = $TotalSpace
            UsedSpaceGB     = $UsedSpace
            FreeSpaceGB     = $FreeSpace
            UsagePercentage = $UsagePercentage
        }
    }
}

# Collect system health metrics
Write-Host "Performing system health check..." -ForegroundColor Cyan
$CPUUsage = Get-CPUUsage
$RAMUsage = Get-RAMUsage
$DiskUsage = Get-DiskUsage

# Combine results into a report
$Report = @()
$Report += $CPUUsage
$Report += $RAMUsage
$Report += $DiskUsage

# Display the report
Write-Host "System Health Report:" -ForegroundColor Green
$Report | Format-Table -AutoSize

# Save the report to a file if specified
if ($SaveReport) {
    Write-Host "Saving report to: $SaveReport" -ForegroundColor Yellow
    $Report | Out-File -FilePath $SaveReport -Encoding UTF8
    Write-Host "Report saved successfully!" -ForegroundColor Green
}

Write-Host "System health check completed." -ForegroundColor Cyan
