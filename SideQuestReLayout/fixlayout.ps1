param(
    # Drag the SideQuest backup folder onto this script to use it
    [Parameter(Position = 0)]
    [string]$DroppedFolder,

    # Optional output folder; defaults to "_Android_Standard_Layout" inside the backup folder
    [string]$OutDir
)

# --- CONFIGURATION ---
$SideQuestBackupDir = Join-Path ([Environment]::GetFolderPath("MyDocuments")) "SideQuest backups"
if ($DroppedFolder) { $SideQuestBackupDir = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($DroppedFolder.Trim('"')).TrimEnd('\') }
# ---------------------

if (-not (Test-Path -LiteralPath $SideQuestBackupDir -PathType Container)) {
    Write-Host "Backup folder not found: $SideQuestBackupDir" -ForegroundColor Red
    exit 1
}

# SideQuest layout: <root>\<package>\<timestamp>\{apk, data, obb, manifest.json}
# Allow dropping the root, a single package folder, or a single timestamp folder.
$SinglePackage = $null
if (Test-Path -LiteralPath (Join-Path $SideQuestBackupDir "manifest.json")) {
    $SinglePackage = Get-Item -LiteralPath (Split-Path $SideQuestBackupDir -Parent)
} elseif (Get-ChildItem -LiteralPath $SideQuestBackupDir -Directory | Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName "manifest.json") }) {
    $SinglePackage = Get-Item -LiteralPath $SideQuestBackupDir
}
if ($SinglePackage) { $SideQuestBackupDir = $SinglePackage.Parent.FullName }

$OutputAndroidDir = Join-Path $SideQuestBackupDir "_Android_Standard_Layout"
if ($OutDir) {
    $OutputAndroidDir = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutDir.Trim('"')).TrimEnd('\')
}
# Get all namespace folders inside the SideQuest backup directory
if ($SinglePackage) { $Namespaces = @($SinglePackage) }
else { $Namespaces = Get-ChildItem -LiteralPath $SideQuestBackupDir -Directory | Where-Object { $_.FullName -ne $OutputAndroidDir } }

function Select-WithArrows {
    param([string[]]$Items, [string]$Title)
    $index = 0
    $top = [Console]::CursorTop
    [Console]::CursorVisible = $false
    try {
        while ($true) {
            [Console]::SetCursorPosition(0, $top)
            Write-Host $Title -ForegroundColor Yellow
            for ($i = 0; $i -lt $Items.Count; $i++) {
                $line = ("  " + $Items[$i]).PadRight([Console]::WindowWidth - 1)
                if ($i -eq $index) { Write-Host ("> " + $Items[$i]).PadRight([Console]::WindowWidth - 1) -ForegroundColor Black -BackgroundColor Cyan }
                else { Write-Host $line }
            }
            $key = [Console]::ReadKey($true)
            switch ($key.Key) {
                'UpArrow'   { if ($index -gt 0) { $index-- } else { $index = $Items.Count - 1 } }
                'DownArrow' { if ($index -lt $Items.Count - 1) { $index++ } else { $index = 0 } }
                'Enter'     { return $index }
                'Escape'    { return -1 }
            }
            # Scroll-safe: recompute top if the list pushed the buffer
            $needed = $Items.Count + 1
            if ($top + $needed -gt [Console]::BufferHeight) { $top = [Console]::BufferHeight - $needed }
        }
    } finally { [Console]::CursorVisible = $true }
}

# No folder dropped: let the user pick one from the backup folder
if (-not $SinglePackage -and -not $DroppedFolder) {
    if (-not $Namespaces) {
        Write-Host "No folders found in $SideQuestBackupDir" -ForegroundColor Red
        exit 1
    }
    $choices = @("[All folders]") + @($Namespaces | ForEach-Object { $_.Name })
    Write-Host ""
    $sel = Select-WithArrows -Items $choices -Title "Select a folder (Up/Down, Enter to confirm, Esc to cancel):"
    if ($sel -lt 0) { exit 0 }
    if ($sel -gt 0) { $Namespaces = @($Namespaces[$sel - 1]) }
}

function Format-Size([long]$Bytes) {
    if ($Bytes -ge 1GB) { return "{0:N2} GB" -f ($Bytes / 1GB) }
    if ($Bytes -ge 1MB) { return "{0:N1} MB" -f ($Bytes / 1MB) }
    if ($Bytes -ge 1KB) { return "{0:N1} KB" -f ($Bytes / 1KB) }
    return "$Bytes B"
}

# --- Pass 1: build the copy plan ---
$Plan = New-Object System.Collections.Generic.List[object]
$invalid = [IO.Path]::GetInvalidFileNameChars()
$UsedGameNames = @{}

foreach ($NamespaceDir in $Namespaces) {
    $Namespace = $NamespaceDir.Name

    # SideQuest stores each backup in a timestamp folder (ISO-style name sorts chronologically); use the most recent
    $LatestBackup = Get-ChildItem -LiteralPath $NamespaceDir.FullName -Directory |
                    Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName "manifest.json") } |
                    Sort-Object Name -Descending |
                    Select-Object -First 1

    if (-not $LatestBackup) {
        Write-Host "$Namespace -> No SideQuest backup found, skipping" -ForegroundColor DarkYellow
        continue
    }

    # Game folder name comes from the manifest label, falling back to the package name
    $GameName = $null
    try { $GameName = (Get-Content -LiteralPath (Join-Path $LatestBackup.FullName "manifest.json") -Raw | ConvertFrom-Json).label } catch {}
    if ([string]::IsNullOrWhiteSpace($GameName)) { $GameName = $Namespace }
    $GameName = (-join ($GameName.ToCharArray() | ForEach-Object { if ($invalid -contains $_) { '_' } else { $_ } })).Trim().TrimEnd('.')

    # Two different packages with the same label must not share a folder (they would overwrite each other's APK/manifest)
    $ExistingPackage = $null
    try { $ExistingPackage = (Get-Content -LiteralPath (Join-Path (Join-Path $OutputAndroidDir $GameName) "manifest.json") -Raw -ErrorAction Stop | ConvertFrom-Json).packageName } catch {}
    if (($UsedGameNames.ContainsKey($GameName) -and $UsedGameNames[$GameName] -ne $Namespace) -or
        ($ExistingPackage -and $ExistingPackage -ne $Namespace)) {
        $GameName = "$GameName ($Namespace)"
    }
    $UsedGameNames[$GameName] = $Namespace
    $GameDir = Join-Path $OutputAndroidDir $GameName

    # APK(s), manifest.json and icon.png go directly in the game folder; data/obb/files -> [GameName]/Android/<kind>/[namespace]
    $Mappings = @(@{ Source = Join-Path $LatestBackup.FullName "apk"; Target = $GameDir; Recurse = $false })
    foreach ($kind in "data", "obb", "files") {
        $Mappings += @{ Source = Join-Path $LatestBackup.FullName $kind; Target = Join-Path $GameDir "Android\$kind\$Namespace"; Recurse = $true }
    }

    $before = $Plan.Count
    foreach ($m in $Mappings) {
        if (-not (Test-Path -LiteralPath $m.Source -PathType Container)) { continue }
        foreach ($f in Get-ChildItem -LiteralPath $m.Source -File -Force -Recurse:$m.Recurse) {
            $Plan.Add([pscustomobject]@{
                Namespace = $Namespace
                Backup    = $LatestBackup.Name
                BackupDir = $LatestBackup.FullName
                GameName  = $GameName
                Source    = $f.FullName
                Dest      = Join-Path $m.Target $f.FullName.Substring($m.Source.Length).TrimStart('\')
                Size      = $f.Length
            })
        }
    }
    if ($Plan.Count -eq $before) {
        Write-Host "$Namespace -> Backup $($LatestBackup.Name) is empty, skipping" -ForegroundColor DarkYellow
        continue
    }

    # manifest.json and icon.png go next to the APK
    foreach ($name in "manifest.json", "icon.png") {
        $f = Get-Item -LiteralPath (Join-Path $LatestBackup.FullName $name) -Force -ErrorAction SilentlyContinue
        if (-not $f) { continue }
        $Plan.Insert($before, [pscustomobject]@{
            Namespace = $Namespace
            Backup    = $LatestBackup.Name
            BackupDir = $LatestBackup.FullName
            GameName  = $GameName
            Source    = $f.FullName
            Dest      = Join-Path $GameDir $name
            Size      = $f.Length
        })
        $before++
    }
}

if ($Plan.Count -eq 0) {
    Write-Host "`nNothing to copy." -ForegroundColor Yellow
    exit 0
}

# Same drive: move the files (fast rename). Different drive: copy, then offer to delete the originals.
$SameDrive = [IO.Path]::GetPathRoot($OutputAndroidDir) -eq [IO.Path]::GetPathRoot($SideQuestBackupDir)
$Verb = if ($SameDrive) { "move" } else { "copy" }
$Past = if ($SameDrive) { "moved" } else { "copied" }
$Activity = if ($SameDrive) { "Moving files" } else { "Copying files" }

# --- Show the plan and ask for confirmation ---
Write-Host "`nThe following files will be $($Past.ToUpper()) to: $OutputAndroidDir" -ForegroundColor Yellow
if ($SameDrive) { Write-Host "(same drive as the backups, so files are moved out of the backup folder)" -ForegroundColor DarkGray }
Write-Host ""
foreach ($group in $Plan | Group-Object Namespace) {
    $first = $group.Group[0]
    Write-Host "$($first.GameName)  ($($first.Namespace), backup $($first.Backup))" -ForegroundColor Cyan
    foreach ($item in $group.Group) {
        $rel = $item.Dest.Substring($OutputAndroidDir.Length).TrimStart('\')
        $note = if (Test-Path -LiteralPath $item.Dest) { "  [overwrite]" } else { "" }
        Write-Host ("  {0,10}  {1}{2}" -f (Format-Size $item.Size), $rel, $note) -ForegroundColor $(if ($note) { 'DarkYellow' } else { 'Gray' })
    }
}
$TotalSize = ($Plan | Measure-Object Size -Sum).Sum
Write-Host ("`nTotal: {0} file(s), {1}" -f $Plan.Count, (Format-Size $TotalSize)) -ForegroundColor Yellow

$answer = Read-Host "Proceed with $Verb? (Y/N)"
if ($answer -notmatch '^(y|yes)$') {
    Write-Host "Cancelled, nothing was $Past." -ForegroundColor DarkYellow
    exit 0
}

# --- Pass 2: move or copy ---
$Failed = @{}   # BackupDir -> $true if any of its files failed
$ErrorCount = 0
$done = 0
foreach ($item in $Plan) {
    $done++
    Write-Progress -Activity $Activity -Status "$done of $($Plan.Count): $(Split-Path $item.Dest -Leaf)" -PercentComplete ($done * 100 / $Plan.Count)
    try {
        New-Item -ItemType Directory -Force -Path (Split-Path $item.Dest -Parent) -ErrorAction Stop | Out-Null
        if ($SameDrive) {
            if (Test-Path -LiteralPath $item.Dest) { Remove-Item -LiteralPath $item.Dest -Force -ErrorAction Stop }
            Move-Item -LiteralPath $item.Source -Destination $item.Dest -ErrorAction Stop
        } else {
            Copy-Item -LiteralPath $item.Source -Destination $item.Dest -Force -ErrorAction Stop
            if ((Get-Item -LiteralPath $item.Dest -Force).Length -ne $item.Size) { throw "Size mismatch after copy" }
        }
    } catch {
        $Failed[$item.BackupDir] = $true
        $ErrorCount++
        Write-Host "  FAILED: $($item.Source) -> $($item.Dest): $($_.Exception.Message)" -ForegroundColor Red
    }
}
Write-Progress -Activity $Activity -Completed

Write-Host "`nFinished! $($Plan.Count - $ErrorCount) of $($Plan.Count) file(s) $Past to: $OutputAndroidDir" -ForegroundColor Yellow
if ($ErrorCount) { Write-Host "$($Failed.Count) backup(s) had errors; their original backup folders were left in place." -ForegroundColor Red }

# Removes a used backup (timestamp) folder, and its package folder if nothing else is left in it
function Remove-Backup([string]$BackupDir) {
    $PackageDir = Split-Path $BackupDir -Parent
    Remove-Item -LiteralPath $BackupDir -Recurse -Force -ErrorAction Stop
    if (-not (Get-ChildItem -LiteralPath $PackageDir -Force)) { Remove-Item -LiteralPath $PackageDir -Force -ErrorAction Stop }
}

$UsedBackups = @($Plan | Select-Object -ExpandProperty BackupDir -Unique | Where-Object { -not $Failed[$_] })

if ($SameDrive) {
    # Clean up backup folders left with only empty directories after the move
    foreach ($dir in $UsedBackups) {
        if (Get-ChildItem -LiteralPath $dir -Recurse -File -Force) { continue }
        try { Remove-Backup $dir } catch { Write-Host "  Could not remove empty folder $dir`: $($_.Exception.Message)" -ForegroundColor Red }
    }
} elseif ($UsedBackups) {
    Write-Host "`nThe following original backup folder(s) were copied successfully:" -ForegroundColor Yellow
    foreach ($dir in $UsedBackups) { Write-Host "  $dir" }
    $answer = Read-Host "Delete these original backup folder(s)? (Y/N)"
    if ($answer -match '^(y|yes)$') {
        foreach ($dir in $UsedBackups) {
            try { Remove-Backup $dir; Write-Host "  Deleted $dir" -ForegroundColor Green }
            catch { Write-Host "  Could not delete $dir`: $($_.Exception.Message)" -ForegroundColor Red }
        }
    } else {
        Write-Host "Original backups kept." -ForegroundColor DarkYellow
    }
}
