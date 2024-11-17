<#
.SYNOPSIS
    Tests network upload and download speeds and logs the results.

.DESCRIPTION
    This script uses a public speed test API to measure upload and download speeds
    and optionally logs the results for future reference.

.NOTES
    Author: Emanuele Bartolesi
    Version: 1.0
    Created: 2024-11-17

.PARAMETER LogPath
    Optional path to save the test results in a CSV file.

.EXAMPLE
    ./NetworkSpeedTest.ps1

.EXAMPLE
    ./NetworkSpeedTest.ps1 -LogPath "C:\Logs\NetworkSpeedTest.csv"
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$LogPath = "$env:USERPROFILE\Documents\NetworkSpeedTestLog.csv"
)

# Function to test network speed
function Test-NetworkSpeed {
    try {
        Write-Host "Testing network speed..." -ForegroundColor Cyan

        # Using the public speed test API
        $ApiUrl = "https://www.speedtest.net/api/js/speedtest-config.php"
        $SpeedTestData = Invoke-RestMethod -Uri $ApiUrl -Method Get -ErrorAction Stop

        $DownloadSpeed = [math]::Round($SpeedTestData.speeds.download / 1024, 2) # Mbps
        $UploadSpeed = [math]::Round($SpeedTestData.speeds.upload / 1024, 2)     # Mbps
        $Ping = $SpeedTestData.ping.latency                                      # ms

        [PSCustomObject]@{
            Timestamp      = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            DownloadSpeed  = $DownloadSpeed
            UploadSpeed    = $UploadSpeed
            Ping           = $Ping
        }
    } catch {
        Write-Warning "Failed to test network speed: $_"
        return $null
    }
}

# Function to log results
function Log-Results {
    param (
        [PSCustomObject]$Results,
        [string]$LogFile
    )

    if ($null -eq $Results) {
        Write-Warning "No results to log."
        return
    }

    # Write results to CSV
    if (-not (Test-Path $LogFile)) {
        $Results | Export-Csv -Path $LogFile -NoTypeInformation -Encoding UTF8
        Write-Host "Log file created at: $LogFile" -ForegroundColor Green
    } else {
        $Results | Export-Csv -Path $LogFile -NoTypeInformation -Encoding UTF8 -Append
        Write-Host "Results appended to log file: $LogFile" -ForegroundColor Green
    }
}

# Main execution
$Results = Test-NetworkSpeed

if ($Results) {
    Write-Host "Network Speed Test Results:" -ForegroundColor Green
    $Results | Format-Table -AutoSize

    if ($LogPath) {
        Log-Results -Results $Results -LogFile $LogPath
    }
}

Write-Host "Network speed test completed." -ForegroundColor Cyan
