<#
.SYNOPSIS
    Generates a detailed system information report in Markdown format.

.DESCRIPTION
    Collects key details such as OS version, hardware specs, memory, disk usage,
    network configuration, and installed hotfixes. Outputs the report as a Markdown file.

.PARAMETER OutputPath
    Path for the Markdown report file. Defaults to "SystemInfoReport.md" in the current directory.

.EXAMPLE
    ./SystemInfoReport.ps1
.EXAMPLE
    ./SystemInfoReport.ps1 -OutputPath "C:\Reports\MyPC_Report.md"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = (Join-Path (Get-Location) "SystemInfoReport.md")
)

# Collect system information
$os     = Get-CimInstance Win32_OperatingSystem
$cs     = Get-CimInstance Win32_ComputerSystem
$cpu    = Get-CimInstance Win32_Processor
$bios   = Get-CimInstance Win32_BIOS
$disks  = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3"
$net    = Get-CimInstance Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled }
$hotfix = Get-HotFix | Sort-Object InstalledOn -Descending

# Build Markdown
$md = @()
$md += "# 🖥️ System Information Report"
$md += ""
$md += "Generated on: **$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')**"
$md += ""
$md += "## 📌 Operating System"
$md += "- Caption: $($os.Caption)"
$md += "- Version: $($os.Version)"
$md += "- Build Number: $($os.BuildNumber)"
$md += "- Install Date: $([Management.ManagementDateTimeConverter]::ToDateTime($os.InstallDate))"
$md += "- Last Boot: $([Management.ManagementDateTimeConverter]::ToDateTime($os.LastBootUpTime))"
$md += "- Uptime (Days): $([math]::Round((New-TimeSpan -Start ([Management.ManagementDateTimeConverter]::ToDateTime($os.LastBootUpTime)) -End (Get-Date)).TotalDays,2))"
$md += ""
$md += "## 💻 Hardware"
$md += "- Manufacturer: $($cs.Manufacturer)"
$md += "- Model: $($cs.Model)"
$md += "- BIOS Version: $($bios.SMBIOSBIOSVersion)"
$md += "- CPU: $($cpu.Name)"
$md += "- Cores: $($cpu.NumberOfCores)"
$md += "- Logical Processors: $($cpu.NumberOfLogicalProcessors)"
$md += "- Total Memory (GB): $([math]::Round($cs.TotalPhysicalMemory/1GB,2))"
$md += ""
$md += "## 💾 Storage"
foreach ($d in $disks) {
    $md += "- Drive $($d.DeviceID): $([math]::Round($d.Size/1GB,2)) GB total, $([math]::Round($d.FreeSpace/1GB,2)) GB free"
}
$md += ""
$md += "## 🌐 Network Adapters"
foreach ($n in $net) {
    $md += "- $($n.Description)"
    $md += "  - IP: $($n.IPAddress -join ', ')"
    $md += "  - MAC: $($n.MACAddress)"
    $md += "  - Gateway: $($n.DefaultIPGateway -join ', ')"
    $md += "  - DNS: $($n.DNSServerSearchOrder -join ', ')"
}
$md += ""
$md += "## 🔒 Installed Hotfixes (Last 5)"
$hotfix | Select-Object -First 5 | ForEach-Object {
    $md += "- $($_.HotFixID) installed on $($_.InstalledOn)"
}
$md += ""

# Write to file
$md -join "`r`n" | Out-File -FilePath $OutputPath -Encoding UTF8

Write-Host "System Information Report generated at: $OutputPath" -ForegroundColor Green
