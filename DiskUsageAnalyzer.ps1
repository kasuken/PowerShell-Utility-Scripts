<#
.SYNOPSIS
    Analyzes disk usage for specified directories and generates a folder size report.

.DESCRIPTION
    This script scans specified directories, calculates the sizes of each folder, 
    and generates a detailed report sorted by size. The report can be displayed in 
    the console or exported to a CSV file.

.NOTES
    Author: Emanuele Bartolesi
    Version: 1.0
    Created: 2024-11-17

.PARAMETER Directory
    The directory to analyze. Defaults to the current directory.

.PARAMETER ExportPath
    The path to save the report as a CSV file. Optional.

.PARAMETER MinSize
    Minimum size (in MB) to include in the report. Defaults to 0 MB.

.EXAMPLE
    ./DiskUsageAnalyzer.ps1 -Directory "C:\Users\YourName\Documents"

.EXAMPLE
    ./DiskUsageAnalyzer.ps1 -Directory "C:\Users" -ExportPath "C:\Reports\DiskUsageReport.csv" -MinSize 10
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$Directory = (Get-Location).Path,

    [Parameter(Mandatory = $false)]
    [string]$ExportPath,

    [Parameter(Mandatory = $false)]
    [int]$MinSize = 0
)

# Function to calculate folder size
function Get-FolderSize {
    param (
        [string]$FolderPath
    )
    $Size = (Get-ChildItem -Path $FolderPath -Recurse -ErrorAction SilentlyContinue |
             Measure-Object -Property Length -Sum).Sum
    return [math]::Round($Size / 1MB, 2) # Convert to MB
}

# Main script execution
try {
    Write-Host "Analyzing disk usage for: $Directory" -ForegroundColor Cyan
    if (-not (Test-Path $Directory)) {
        throw "The specified directory does not exist: $Directory"
    }

    $Folders = Get-ChildItem -Path $Directory -Directory -Force | ForEach-Object {
        $Size = Get-FolderSize -FolderPath $_.FullName
        [PSCustomObject]@{
            Folder     = $_.FullName
            SizeInMB   = $Size
            ItemCount  = (Get-ChildItem -Path $_.FullName -Recurse -ErrorAction SilentlyContinue | Measure-Object).Count
        }
    }

    # Filter by minimum size
    $FilteredFolders = $Folders | Where-Object { $_.SizeInMB -ge $MinSize } | Sort-Object -Property SizeInMB -Descending

    # Display results
    Write-Host "Disk Usage Report:" -ForegroundColor Green
    $FilteredFolders | Format-Table -AutoSize

    # Export results if needed
    if ($ExportPath) {
        Write-Host "Exporting report to: $ExportPath" -ForegroundColor Yellow
        $FilteredFolders | Export-Csv -Path $ExportPath -NoTypeInformation -Encoding UTF8
        Write-Host "Report exported successfully!" -ForegroundColor Green
    }

} catch {
    Write-Warning "An error occurred: $_"
} finally {
    Write-Host "Disk usage analysis completed." -ForegroundColor Cyan
}
