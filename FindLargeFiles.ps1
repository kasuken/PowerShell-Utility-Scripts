<#
.SYNOPSIS
    Scans a folder (recursively) to find large files and outputs a sortable report.

.DESCRIPTION
    Finds files larger than a specified size threshold (default: 500 MB).
    You can filter by age, limit the number of results, exclude folders or extensions,
    and optionally export the results to CSV.

.PARAMETER Path
    Root directory to scan. Defaults to the current directory.

.PARAMETER MinSizeMB
    Minimum file size (in MB) to include. Default: 500.

.PARAMETER OlderThanDays
    Only include files last modified more than this many days ago. Optional.

.PARAMETER Top
    Return only the top N largest files. Optional.

.PARAMETER ExcludeDirs
    One or more directory name patterns to exclude (supports wildcards). Optional.

.PARAMETER ExcludeExtensions
    One or more file extensions to exclude (e.g., ".zip", ".iso"). Optional.

.PARAMETER ExportCsv
    Path to export results as CSV. Optional.

.EXAMPLE
    ./Find-LargeFiles.ps1 -Path "C:\Users" -MinSizeMB 2000

.EXAMPLE
    ./Find-LargeFiles.ps1 -Path "D:\" -MinSizeMB 500 -Top 100 -ExportCsv "D:\reports\large-files.csv"

.EXAMPLE
    ./Find-LargeFiles.ps1 -Path "C:\Data" -MinSizeMB 100 -OlderThanDays 30 -ExcludeExtensions ".bak",".tmp" -ExcludeDirs "node_modules","bin","obj"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [ValidateScript({ Test-Path $_ -PathType 'Container' })]
    [string]$Path = (Get-Location).Path,

    [Parameter(Mandatory=$false)]
    [ValidateRange(1,[int]::MaxValue)]
    [int]$MinSizeMB = 500,

    [Parameter(Mandatory=$false)]
    [ValidateRange(1,[int]::MaxValue)]
    [int]$OlderThanDays,

    [Parameter(Mandatory=$false)]
    [ValidateRange(1,[int]::MaxValue)]
    [int]$Top,

    [Parameter(Mandatory=$false)]
    [string[]]$ExcludeDirs,

    [Parameter(Mandatory=$false)]
    [string[]]$ExcludeExtensions,

    [Parameter(Mandatory=$false)]
    [string]$ExportCsv
)

Begin {
    Write-Verbose "Starting scan in: $Path"
    Write-Verbose "MinSizeMB: $MinSizeMB"
    if ($PSBoundParameters.ContainsKey('OlderThanDays')) { Write-Verbose "OlderThanDays: $OlderThanDays" }
    if ($ExcludeDirs)        { Write-Verbose "ExcludeDirs: $($ExcludeDirs -join ', ')" }
    if ($ExcludeExtensions)  { Write-Verbose "ExcludeExtensions: $($ExcludeExtensions -join ', ')" }

    # Normalize exclude extensions to include leading dot and lowercase
    if ($ExcludeExtensions) {
        $ExcludeExtensions = $ExcludeExtensions | ForEach-Object {
            $ext = $_.Trim()
            if (-not $ext.StartsWith('.')) { $ext = ".$ext" }
            $ext.ToLowerInvariant()
        }
    }

    # Build a hashtable for fast directory exclusion checks
    $excludeDirSet = @{}
    if ($ExcludeDirs) {
        foreach ($d in $ExcludeDirs) {
            $excludeDirSet[$d.ToLowerInvariant()] = $true
        }
    }

    # Build predicate for date
    $minDate = $null
    if ($PSBoundParameters.ContainsKey('OlderThanDays')) {
        $minDate = (Get-Date).AddDays(-1 * $OlderThanDays)
    }

    $minBytes = [int64]$MinSizeMB * 1MB
    $results = New-Object System.Collections.Generic.List[object]
}

Process {
    # Enumerate with streaming to keep memory lower; filter directories on the fly
    $enum = Get-ChildItem -LiteralPath $Path -File -Recurse -Force -ErrorAction SilentlyContinue

    foreach ($file in $enum) {
        # Directory exclusion (fast path): skip if any parent folder matches an excluded name/pattern
        if ($excludeDirSet.Count -gt 0) {
            $skip = $false
            $dirInfo = $file.Directory
            while ($dirInfo -ne $null -and -not $skip) {
                $name = $dirInfo.Name.ToLowerInvariant()
                # exact name exclusion
                if ($excludeDirSet.ContainsKey($name)) { $skip = $true; break }
                # wildcard pattern support (basic)
                foreach ($pat in $ExcludeDirs) {
                    if ($name -like $pat.ToLowerInvariant()) { $skip = $true; break }
                }
                $dirInfo = $dirInfo.Parent
            }
            if ($skip) { continue }
        }

        # Extension exclusion
        if ($ExcludeExtensions -and $ExcludeExtensions -contains $file.Extension.ToLowerInvariant()) {
            continue
        }

        # Size & date filters
        if ($file.Length -lt $minBytes) { continue }
        if ($minDate -ne $null -and $file.LastWriteTime -gt $minDate) { continue }

        # Build record
        $sizeMB = [math]::Round($file.Length / 1MB, 2)
        $sizeGB = [math]::Round($file.Length / 1GB, 3)

        $results.Add([PSCustomObject]@{
            FullName       = $file.FullName
            Directory      = $file.DirectoryName
            FileName       = $file.Name
            Extension      = $file.Extension
            SizeMB         = $sizeMB
            SizeGB         = $sizeGB
            LastWriteTime  = $file.LastWriteTime
            Created        = $file.CreationTime
        })
    }
}

End {
    # Sort by largest first
    $sorted = $results | Sort-Object -Property SizeMB -Descending

    if ($PSBoundParameters.ContainsKey('Top')) {
        $sorted = $sorted | Select-Object -First $Top
    }

    if (-not $sorted -or $sorted.Count -eq 0) {
        Write-Host "No files found ≥ $MinSizeMB MB that match the given filters." -ForegroundColor Yellow
        return
    }

    # Output to console
    Write-Host "Found $($sorted.Count) file(s). Showing largest first:" -ForegroundColor Green
    $sorted | Select-Object SizeGB, SizeMB, LastWriteTime, FullName | Format-Table -AutoSize

    # Optional CSV export
    if ($PSBoundParameters.ContainsKey('ExportCsv')) {
        try {
            $exportDir = Split-Path -Path $ExportCsv -Parent
            if ($exportDir -and -not (Test-Path $exportDir)) {
                New-Item -Path $exportDir -ItemType Directory -Force | Out-Null
            }
            $sorted | Export-Csv -Path $ExportCsv -NoTypeInformation -Encoding UTF8
            Write-Host "Exported results to: $ExportCsv" -ForegroundColor Cyan
        } catch {
            Write-Warning "Failed to export CSV: $_"
        }
    }
}
