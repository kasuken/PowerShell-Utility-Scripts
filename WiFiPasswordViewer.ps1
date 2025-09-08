<#
.SYNOPSIS
    Displays saved Wi-Fi (WLAN) profiles with SSID, security, and password.

.DESCRIPTION
    Uses `netsh wlan export profile key=clear` to export all WLAN profiles to a
    temporary folder, then parses the XML (language-independent) to extract:
      - SSID (Profile name)
      - Authentication (e.g., WPA2PSK)
      - Cipher (e.g., AES)
      - Password (keyMaterial), optionally masked
    By default, open networks (no password) are excluded.

.PARAMETER ExportCsv
    Optional path to export results as CSV (respects masking options).

.PARAMETER IncludeOpenNetworks
    Include profiles without a password (open networks). Default: excluded.

.PARAMETER Unmask
    Show passwords in clear text. Default: masked (********).

.PARAMETER Filter
    One or more wildcard patterns to include only SSIDs matching any pattern.

.PARAMETER LeaveExports
    Keep the exported XML files (for audit). By default, temporary exports are removed.

.EXAMPLE
    ./WiFiPasswordViewer.ps1

.EXAMPLE
    ./WiFiPasswordViewer.ps1 -Unmask -ExportCsv "C:\Reports\wifi-passwords.csv"

.EXAMPLE
    ./WiFiPasswordViewer.ps1 -IncludeOpenNetworks -Filter "Home*","Office*"
#>

[CmdletBinding()]
param(
    [Parameter()] [string]$ExportCsv,
    [Parameter()] [switch]$IncludeOpenNetworks,
    [Parameter()] [switch]$Unmask,
    [Parameter()] [string[]]$Filter,
    [Parameter()] [switch]$LeaveExports
)

function New-TempDir {
    $base = Join-Path $env:TEMP ("wlan_exports_" + [guid]::NewGuid().ToString("N"))
    New-Item -Path $base -ItemType Directory -Force | Out-Null
    return $base
}

function Mask-Secret {
    param([string]$Text)
    if ([string]::IsNullOrEmpty($Text)) { return "" }
    if ($Text.Length -le 4) { return ('*' * $Text.Length) }
    # show first and last char to help distinguish entries
    return ($Text.Substring(0,1) + ('*' * ($Text.Length-2)) + $Text.Substring($Text.Length-1,1))
}

function Read-WlanProfileXml {
    param([string]$Path)
    try {
        [xml]$xml = Get-Content -LiteralPath $Path -ErrorAction Stop
        $p = $xml.WLANProfile
        if ($null -eq $p) { return $null }

        $ssid  = $p.name
        $auth  = $p.MSM.security.authEncryption.authentication
        $cipher= $p.MSM.security.authEncryption.encryption
        $key   = $p.MSM.security.sharedKey.keyMaterial

        if (-not $auth)   { $auth   = "" }
        if (-not $cipher) { $cipher = "" }
        if (-not $key)    { $key    = "" }

        [PSCustomObject]@{
            SSID          = $ssid
            Authentication= $auth
            Cipher        = $cipher
            Password      = $key
            IsOpen        = [string]::IsNullOrEmpty($key)
            SourceXml     = $Path
        }
    }
    catch {
        Write-Verbose "Failed to parse $Path : $_"
        return $null
    }
}

# --- Main ---
Write-Host "Exporting WLAN profiles..." -ForegroundColor Cyan
$temp = New-TempDir
$exportCmd = "netsh wlan export profile key=clear folder=`"$temp`""
$null = Invoke-Expression $exportCmd

# Collect XML files (netsh names them like Wi-Fi-<SSID>.xml)
$xmls = Get-ChildItem -LiteralPath $temp -Filter "*.xml" -File -ErrorAction SilentlyContinue
if (-not $xmls -or $xmls.Count -eq 0) {
    Write-Warning "No WLAN profile XML files were exported. Are there saved Wi-Fi profiles on this system?"
    if (-not $LeaveExports) { Remove-Item -LiteralPath $temp -Recurse -Force -ErrorAction SilentlyContinue }
    return
}

$profiles = $xmls | ForEach-Object { Read-WlanProfileXml -Path $_.FullName } | Where-Object { $_ -ne $null }

# Filter by open networks
if (-not $IncludeOpenNetworks) {
    $profiles = $profiles | Where-Object { -not $_.IsOpen }
}

# Filter by SSID patterns, if provided
if ($Filter -and $Filter.Count -gt 0) {
    $patterns = $Filter
    $profiles = $profiles | Where-Object {
        $ssid = $_.SSID
        foreach ($p in $patterns) { if ($ssid -like $p) { return $true } }
        return $false
    }
}

if (-not $profiles -or $profiles.Count -eq 0) {
    Write-Host "No profiles matched the current filters." -ForegroundColor Yellow
    if (-not $LeaveExports) { Remove-Item -LiteralPath $temp -Recurse -Force -ErrorAction SilentlyContinue }
    return
}

# Build final output (mask by default)
$final = $profiles | ForEach-Object {
    [PSCustomObject]@{
        SSID           = $_.SSID
        Authentication = $_.Authentication
        Cipher         = $_.Cipher
        Password       = if ($Unmask) { $_.Password } else { Mask-Secret -Text $_.Password }
        OpenNetwork    = $_.IsOpen
    }
} | Sort-Object SSID

# Display
Write-Host ("{0} profile(s) found." -f $final.Count) -ForegroundColor Green
$final | Format-Table -AutoSize

# Export if requested
if ($ExportCsv) {
    try {
        $dir = Split-Path -Path $ExportCsv -Parent
        if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
        $final | Export-Csv -Path $ExportCsv -NoTypeInformation -Encoding UTF8
        Write-Host "Exported CSV to: $ExportCsv" -ForegroundColor Cyan
    } catch {
        Write-Warning "Failed to export CSV: $_"
    }
}

# Clean up temp files unless asked to keep
if (-not $LeaveExports) {
    Remove-Item -LiteralPath $temp -Recurse -Force -ErrorAction SilentlyContinue
} else {
    Write-Host "Exported XML files preserved at: $temp" -ForegroundColor Yellow
}

# Security note
if ($Unmask) {
    Write-Warning "Passwords were displayed in CLEAR TEXT. Handle output and CSV with care."
}