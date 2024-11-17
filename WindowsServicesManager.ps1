<#
.SYNOPSIS
    Manages Windows services interactively by listing, starting, stopping, or restarting them.

.DESCRIPTION
    This script lists services based on their status (Running, Stopped, Disabled) and allows the user to perform actions on selected services interactively.

.NOTES
    Author: Emanuele Bartolesi
    Version: 1.0
    Created: 2024-11-17

.PARAMETER Status
    Specifies the status of services to display: Running, Stopped, or Disabled. Default is Running.

.EXAMPLE
    ./WindowsServicesManager.ps1

.EXAMPLE
    ./WindowsServicesManager.ps1 -Status Stopped
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [ValidateSet("Running", "Stopped", "Disabled")]
    [string]$Status = "Running"
)

# Function to list services based on their status
function Get-ServicesByStatus {
    param (
        [string]$ServiceStatus
    )

    Write-Host "Fetching services with status: $ServiceStatus..." -ForegroundColor Yellow

    switch ($ServiceStatus) {
        "Running"  { Get-Service | Where-Object { $_.Status -eq 'Running' } }
        "Stopped"  { Get-Service | Where-Object { $_.Status -eq 'Stopped' } }
        "Disabled" {
            Get-WmiObject -Class Win32_Service | Where-Object { $_.StartMode -eq 'Disabled' } | ForEach-Object {
                [PSCustomObject]@{
                    Name        = $_.Name
                    DisplayName = $_.DisplayName
                    Status      = $_.State
                    StartMode   = $_.StartMode
                }
            }
        }
    }
}

# Function to manage selected services
function Manage-Service {
    param (
        [PSCustomObject]$Service
    )

    Write-Host "Selected Service: $($Service.DisplayName)" -ForegroundColor Cyan
    Write-Host "Options: [1] Start [2] Stop [3] Restart [4] Skip" -ForegroundColor Green

    $Action = Read-Host "Enter your choice"
    switch ($Action) {
        "1" {
            if ($Service.Status -eq "Stopped") {
                Start-Service -Name $Service.Name
                Write-Host "Service started: $($Service.DisplayName)" -ForegroundColor Green
            } else {
                Write-Host "Service is already running." -ForegroundColor Yellow
            }
        }
        "2" {
            if ($Service.Status -eq "Running") {
                Stop-Service -Name $Service.Name
                Write-Host "Service stopped: $($Service.DisplayName)" -ForegroundColor Green
            } else {
                Write-Host "Service is not running." -ForegroundColor Yellow
            }
        }
        "3" {
            if ($Service.Status -eq "Running") {
                Restart-Service -Name $Service.Name
                Write-Host "Service restarted: $($Service.DisplayName)" -ForegroundColor Green
            } else {
                Write-Host "Service is not running. Starting the service..." -ForegroundColor Yellow
                Start-Service -Name $Service.Name
            }
        }
        "4" {
            Write-Host "Skipping service: $($Service.DisplayName)" -ForegroundColor Cyan
        }
        default {
            Write-Host "Invalid choice. Skipping..." -ForegroundColor Red
        }
    }
}

# Main script execution
Write-Host "Windows Services Manager" -ForegroundColor Cyan

$Services = Get-ServicesByStatus -ServiceStatus $Status

if ($null -eq $Services) {
    Write-Host "No services found with status: $Status" -ForegroundColor Yellow
    return
}

Write-Host "Select a service to manage:" -ForegroundColor Green
$SelectedService = $Services | Out-GridView -Title "Select a Service to Manage" -PassThru

if ($null -ne $SelectedService) {
    Manage-Service -Service $SelectedService
} else {
    Write-Host "No service selected. Exiting..." -ForegroundColor Yellow
}

Write-Host "Windows Services Manager execution completed." -ForegroundColor Cyan
