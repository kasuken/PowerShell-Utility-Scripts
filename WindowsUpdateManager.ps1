<#
.SYNOPSIS
    Checks, downloads, and installs Windows Updates with optional automatic reboot.

.DESCRIPTION
    Prefers the PSWindowsUpdate module if available; otherwise uses the native
    Microsoft Update COM API (Microsoft.Update.Session). Supports:
      - Check only
      - Download only
      - Install (with optional reboot)
      - Include/exclude drivers
      - CSV export and log file
      - Minimal filtering by update categories

.PARAMETER Mode
    Operation mode: Check, Download, or Install.

.PARAMETER IncludeDrivers
    Include driver updates (off by default).

.PARAMETER Categories
    Optional list of category filters (e.g., 'Security Updates','Critical Updates').
    If provided, only updates that match any of these category names are considered.

.PARAMETER ExportCsv
    Optional path to export the list of found updates as CSV.

.PARAMETER LogPath
    Optional path to a log file (messages will be appended).

.PARAMETER AutoReboot
    If installation requires a reboot, restart the computer automatically.

.PARAMETER WhatIf
    Simulate actions where supported (not for the COM installation itself).

.EXAMPLE
    # Check for available updates (software only)
    .\WindowsUpdateManager.ps1 -Mode Check

.EXAMPLE
    # Download available updates including drivers, export to CSV
    .\WindowsUpdateManager.ps1 -Mode Download -IncludeDrivers -ExportCsv "C:\Reports\updates.csv"

.EXAMPLE
    # Install security/critical updates and reboot automatically if needed
    .\WindowsUpdateManager.ps1 -Mode Install -Categories "Security Updates","Critical Updates" -AutoReboot -Verbose
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('Check','Download','Install')]
    [string]$Mode,

    [Parameter()]
    [switch]$IncludeDrivers,

    [Parameter()]
    [string[]]$Categories,

    [Parameter()]
    [string]$ExportCsv,

    [Parameter()]
    [string]$LogPath,

    [Parameter()]
    [switch]$AutoReboot
)

# region Utilities
function Write-Log {
    param([string]$Message, [string]$Level = 'INFO')
    $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $line = "$ts [$Level] $Message"
    Write-Verbose $line
    if ($LogPath) {
        try { Add-Content -Path $LogPath -Value $line -Encoding UTF8 } catch {}
    }
}

function Normalize-Categories {
    param([object]$Update)
    try {
        if ($null -eq $Update.Categories) { return @() }
        return @($Update.Categories | ForEach-Object { $_.Name })
    } catch { return @() }
}

function Update-MatchesCategories {
    param([object]$Update, [string[]]$Wanted)
    if (-not $Wanted -or $Wanted.Count -eq 0) { return $true }
    $ucats = Normalize-Categories -Update $Update
    foreach ($w in $Wanted) {
        if ($ucats -contains $w) { return $true }
    }
    return $false
}

function Map-UpdateRecord {
    param([object]$Update)
    [PSCustomObject]@{
        Title        = $Update.Title
        KBs          = ($Update.KBArticleIDs -join ',')
        Categories   = (Normalize-Categories -Update $Update) -join '; '
        EulaAccepted = $Update.EulaAccepted
        IsDownloaded = $Update.IsDownloaded
        RebootReq    = $Update.RebootRequired
        MsrcSeverity = ($Update.MsrcSeverity | Out-String).Trim()
    }
}
# endregion Utilities

# region Try PSWindowsUpdate first
$usePsWindowsUpdate = $false
try {
    if (Get-Module -ListAvailable -Name PSWindowsUpdate) {
        Import-Module PSWindowsUpdate -ErrorAction Stop
        $usePsWindowsUpdate = $true
        Write-Log "Using PSWindowsUpdate module." 'INFO'
    } else {
        Write-Log "PSWindowsUpdate not found. Falling back to COM API." 'INFO'
    }
} catch {
    Write-Log "Failed to load PSWindowsUpdate: $_. Using COM API." 'WARN'
    $usePsWindowsUpdate = $false
}
# endregion

# region Implementations
function Invoke-WithPSWU {
    # Build include filters
    $includeDrivers = [bool]$IncludeDrivers
    $catFilter = $null
    if ($Categories -and $Categories.Count -gt 0) {
        # PSWindowsUpdate doesn't filter by arbitrary names directly;
        # we'll filter after query when presenting/installing.
        $catFilter = $Categories
    }

    # Query
    Write-Log "Querying updates (PSWindowsUpdate)..." 'INFO'
    $all = Get-WindowsUpdate -MicrosoftUpdate -AcceptAll -IgnoreReboot -NotCategory 'Definition Updates' -ErrorAction SilentlyContinue

    if ($null -eq $all) { $all = @() }

    # Filter drivers if excluded
    if (-not $includeDrivers) {
        $all = $all | Where-Object { $_.UpdateTitle -notmatch '(?i)\bdriver\b' -and $_.Title -notmatch '(?i)\bdriver\b' }
    }

    # Filter categories by name after query
    if ($catFilter) {
        $all = $all | Where-Object {
            $cats = @($_.Categories) -join ';'
            foreach ($w in $catFilter) { if ($cats -like "*$w*") { return $true } }
            return $false
        }
    }

    $mapped = $all | ForEach-Object {
        [PSCustomObject]@{
            Title        = $_.Title
            KBs          = ($_.KB -join ',')
            Categories   = (@($_.Categories) -join '; ')
            IsDownloaded = $false
            EulaAccepted = $true
            RebootReq    = $false
            MsrcSeverity = ''
            Raw          = $_
        }
    }

    if ($Mode -eq 'Check') {
        return $mapped
    }

    if ($Mode -in @('Download','Install')) {
        if ($mapped.Count -eq 0) { return @() }
        if ($PSCmdlet.ShouldProcess("Download updates", "Count=$($mapped.Count)")) {
            # PSWindowsUpdate does not have a "download only" flag in all versions,
            # but Install-WindowsUpdate with -Download can be used in newer versions.
            if ($Mode -eq 'Download' -and (Get-Command Install-WindowsUpdate -ErrorAction SilentlyContinue)) {
                Install-WindowsUpdate -MicrosoftUpdate -Download -AcceptAll -IgnoreReboot -ErrorAction SilentlyContinue | Out-Null
            }
        }
        if ($Mode -eq 'Install') {
            if ($PSCmdlet.ShouldProcess("Install updates", "Count=$($mapped.Count)")) {
                $res = Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -IgnoreReboot -ErrorAction SilentlyContinue
                $needsReboot = ($res | Where-Object { $_.NeedsReboot -eq $true }).Count -gt 0
                if ($needsReboot) {
                    Write-Log "Installation indicates reboot required." 'INFO'
                    if ($AutoReboot) {
                        Write-Log "AutoReboot enabled. Restarting now..." 'INFO'
                        Restart-Computer -Force
                    } else {
                        Write-Warning "A reboot is required to complete installation."
                    }
                }
            }
        }
        return $mapped
    }
}

function Invoke-WithCOM {
    Write-Log "Using COM API (Microsoft.Update.Session)." 'INFO'
    $session  = New-Object -ComObject Microsoft.Update.Session
    $searcher = $session.CreateUpdateSearcher()

    # Build WUA query
    # Base filters: not installed, type=software; optionally include drivers
    $typeFilter = if ($IncludeDrivers) { "Type='Software' or Type='Driver'" } else { "Type='Software'" }
    $criteria   = "IsInstalled=0 and IsHidden=0 and ($typeFilter)"
    Write-Log "Search criteria: $criteria" 'INFO'

    $searchResult = $searcher.Search($criteria)
    $updatesColl  = $searchResult.Updates

    # Map & filter by categories if provided
    $list = @()
    for ($i = 0; $i -lt $updatesColl.Count; $i++) {
        $u = $updatesColl.Item($i)
        if (-not (Update-MatchesCategories -Update $u -Wanted $Categories)) { continue }
        $list += $u
    }

    $mapped = $list | ForEach-Object { Map-UpdateRecord -Update $_ | Add-Member -NotePropertyName Raw -NotePropertyValue $_ -PassThru }

    if ($Mode -eq 'Check') { return $mapped }

    # Download set
    if ($Mode -in @('Download','Install') -and $mapped.Count -gt 0) {
        $toProcess = New-Object -ComObject Microsoft.Update.UpdateColl
        $mapped.Raw | ForEach-Object { [void]$toProcess.Add($_) }

        if ($Mode -in @('Download','Install')) {
            if ($PSCmdlet.ShouldProcess("Download updates (COM)", "Count=$($toProcess.Count)")) {
                $downloader = $session.CreateUpdateDownloader()
                $downloader.Updates = $toProcess
                $dlResult = $downloader.Download()
                Write-Log ("Download Result: {0}" -f $dlResult.ResultCode) 'INFO'
            }
        }

        if ($Mode -eq 'Install') {
            if ($PSCmdlet.ShouldProcess("Install updates (COM)", "Count=$($toProcess.Count)")) {
                # Accept EULAs if needed
                for ($i = 0; $i -lt $toProcess.Count; $i++) {
                    $u = $toProcess.Item($i)
                    if (-not $u.EulaAccepted) { $u.AcceptEula() | Out-Null }
                }
                $installer = $session.CreateUpdateInstaller()
                $installer.Updates = $toProcess
                $instResult = $installer.Install()
                Write-Log ("Install Result: {0}" -f $instResult.ResultCode) 'INFO'

                if ($instResult.RebootRequired) {
                    Write-Log "Installation indicates reboot required." 'INFO'
                    if ($AutoReboot) {
                        Write-Log "AutoReboot enabled. Restarting now..." 'INFO'
                        Restart-Computer -Force
                    } else {
                        Write-Warning "A reboot is required to complete installation."
                    }
                }
            }
        }
    }

    return $mapped
}
# endregion

# region Run
try {
    Write-Log "Starting WindowsUpdateManager in mode: $Mode" 'INFO'
    $results = if ($usePsWindowsUpdate) { Invoke-WithPSWU } else { Invoke-WithCOM }

    if ($results -and $results.Count -gt 0) {
        $table = $results | Select-Object Title, KBs, Categories, EulaAccepted, IsDownloaded, RebootReq, MsrcSeverity
        Write-Host "Updates found: $($results.Count)" -ForegroundColor Green
        $table | Format-Table -AutoSize

        if ($ExportCsv) {
            try {
                $dir = Split-Path -Path $ExportCsv -Parent
                if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
                $table | Export-Csv -Path $ExportCsv -NoTypeInformation -Encoding UTF8
                Write-Log "Exported CSV to $ExportCsv" 'INFO'
            } catch {
                Write-Warning "Failed to export CSV: $_"
            }
        }
    } else {
        Write-Host "No applicable updates found for the specified criteria." -ForegroundColor Yellow
    }
} catch {
    Write-Error "WindowsUpdateManager encountered an error: $_"
    Write-Log "Error: $_" 'ERROR'
}
# endregion