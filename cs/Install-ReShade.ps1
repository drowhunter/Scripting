param(
    [Parameter(Mandatory = $true)]
    [string]$TargetExe,

    [Parameter(Mandatory = $true)]
    [ValidateSet("Normal", "Addon", "Uninstall")]
    [string]$Edition
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Windows.Forms

if (-not (Test-Path -LiteralPath $TargetExe)) {
    [System.Windows.Forms.MessageBox]::Show("Selected file does not exist.`n$TargetExe", "ReShade")
    exit 1
}

if ([System.IO.Path]::GetExtension($TargetExe).ToLowerInvariant() -ne ".exe") {
    [System.Windows.Forms.MessageBox]::Show("Selected file is not an .exe.`n$TargetExe", "ReShade")
    exit 1
}

if ($Edition -eq "Uninstall") {
    $targetDir = Split-Path -Parent $TargetExe
    $itemsToRemove = @(
        "ReShade.ini",
        "ReShadePreset.ini",
        "dxgi.dll",
        "d3d11.dll",
        "d3d10.dll",
        "d3d9.dll",
        "opengl32.dll",
        "ReShade.log"
    )

    $folderToRemove = Join-Path $targetDir "reshade-shaders"

    $confirm = [System.Windows.Forms.MessageBox]::Show(
        "This will remove common ReShade files from:`n$targetDir`n`nContinue?",
        "ReShade Uninstall",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Question
    )

    if ($confirm -ne [System.Windows.Forms.DialogResult]::Yes) {
        exit 0
    }

    $removed = @()
    $failed = @()

    foreach ($item in $itemsToRemove) {
        $fullPath = Join-Path $targetDir $item
        if (Test-Path -LiteralPath $fullPath) {
            try {
                Remove-Item -LiteralPath $fullPath -Force
                $removed += $fullPath
            }
            catch {
                $failed += $fullPath
            }
        }
    }

    if (Test-Path -LiteralPath $folderToRemove) {
        try {
            Remove-Item -LiteralPath $folderToRemove -Recurse -Force
            $removed += $folderToRemove
        }
        catch {
            $failed += $folderToRemove
        }
    }

    $message = "Uninstall complete.`n`nRemoved: $($removed.Count)`nFailed: $($failed.Count)"
    if ($failed.Count -gt 0) {
        $message += "`n`nSome files could not be removed. Close the game and try again."
    }

    [System.Windows.Forms.MessageBox]::Show($message, "ReShade Uninstall")
    exit 0
}

function Get-ReShadeVersionFromUrl {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Url
    )

    if ($Url -match "ReShade_Setup_(\d+(?:\.\d+)+)(?:_Addon)?\.exe") {
        try {
            return [System.Version]::Parse($matches[1])
        }
        catch {
            return [System.Version]::Parse("0.0")
        }
    }

    return [System.Version]::Parse("0.0")
}

function Get-ReShadeInstallerUrl {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("Normal", "Addon")]
        [string]$EditionName
    )

    $pagesToScan = @(
        "https://reshade.me/#download",
        "https://reshade.me/",
        "https://reshade.me/downloads/"
    )

    $candidateUrls = @()
    $urlRegex = "(?:https://reshade\.me)?/downloads/ReShade_Setup(?:_\d+(?:\.\d+)+)?(?:_Addon)?\.exe|https://reshade\.me/downloads/ReShade_Setup\.exe"

    foreach ($pageUrl in $pagesToScan) {
        try {
            $response = Invoke-WebRequest -Uri $pageUrl -UseBasicParsing

            if ($response.Links) {
                foreach ($link in $response.Links) {
                    if (-not [string]::IsNullOrWhiteSpace($link.href) -and $link.href -match "ReShade_Setup") {
                        if ($link.href.StartsWith("/")) {
                            $candidateUrls += ("https://reshade.me{0}" -f $link.href)
                        }
                        elseif ($link.href.StartsWith("https://reshade.me/")) {
                            $candidateUrls += $link.href
                        }
                    }
                }
            }

            foreach ($m in [regex]::Matches($response.Content, $urlRegex)) {
                $value = $m.Value
                if ($value.StartsWith("/")) {
                    $candidateUrls += ("https://reshade.me{0}" -f $value)
                }
                elseif ($value.StartsWith("https://reshade.me/")) {
                    $candidateUrls += $value
                }
            }
        }
        catch {
            continue
        }
    }

    $uniqueCandidates = $candidateUrls |
        Where-Object { $_ -match "https://reshade\.me/downloads/ReShade_Setup.*\.exe" } |
        Select-Object -Unique

    if ($EditionName -eq "Addon") {
        $filtered = $uniqueCandidates | Where-Object { $_ -match "_Addon\.exe$" }
    }
    else {
        $filtered = $uniqueCandidates | Where-Object { $_ -notmatch "_Addon\.exe$" }
    }

    if (-not $filtered -or $filtered.Count -eq 0) {
        if ($EditionName -eq "Addon") {
            $normalCandidates = $uniqueCandidates | Where-Object { $_ -notmatch "_Addon\.exe$" }
            $normalVersioned = $normalCandidates | Where-Object { $_ -match "ReShade_Setup_\d+(?:\.\d+)+" }
            if ($normalVersioned -and $normalVersioned.Count -gt 0) {
                $latestNormal = ($normalVersioned |
                    Sort-Object -Property @{ Expression = { Get-ReShadeVersionFromUrl -Url $_ } } -Descending |
                    Select-Object -First 1)

                if ($latestNormal -match "ReShade_Setup_(\d+(?:\.\d+)+)\.exe$") {
                    $derivedAddon = "https://reshade.me/downloads/ReShade_Setup_{0}_Addon.exe" -f $matches[1]
                    try {
                        Invoke-WebRequest -Uri $derivedAddon -Method Head -UseBasicParsing | Out-Null
                        return $derivedAddon
                    }
                    catch {
                        return $null
                    }
                }
            }

            return $null
        }

        return "https://reshade.me/downloads/ReShade_Setup.exe"
    }

    $versioned = $filtered | Where-Object { $_ -match "ReShade_Setup_\d+(?:\.\d+)+" }
    if ($versioned -and $versioned.Count -gt 0) {
        return ($versioned |
            Sort-Object -Property @{ Expression = { Get-ReShadeVersionFromUrl -Url $_ } } -Descending |
            Select-Object -First 1)
    }

    if ($EditionName -eq "Normal") {
        $plain = $filtered | Where-Object { $_ -match "ReShade_Setup\.exe$" } | Select-Object -First 1
        if ($plain) {
            return $plain
        }
    }

    return ($filtered | Select-Object -First 1)
}

$downloadMap = @{
    Normal = (Get-ReShadeInstallerUrl -EditionName "Normal")
    Addon  = (Get-ReShadeInstallerUrl -EditionName "Addon")
}

$pageMap = @{
    Normal = "https://reshade.me/#download"
    Addon  = "https://reshade.me/addons"
}

$downloadUrl = $downloadMap[$Edition]
$installerPath = Join-Path $env:TEMP ("ReShade_Setup_{0}.exe" -f $Edition)

if ([string]::IsNullOrWhiteSpace($downloadUrl)) {
    Start-Process $pageMap[$Edition]
    [System.Windows.Forms.MessageBox]::Show(
        "Could not find the latest ReShade ($Edition) installer link on the official site. Opened official page instead.",
        "ReShade"
    )
    exit 1
}

try {
    Invoke-WebRequest -Uri $downloadUrl -OutFile $installerPath -UseBasicParsing
}
catch {
    Start-Process $pageMap[$Edition]
    [System.Windows.Forms.MessageBox]::Show(
        "Could not download ReShade ($Edition) automatically. Opened official page instead.",
        "ReShade"
    )
    exit 1
}

Start-Process -FilePath $installerPath -ArgumentList "`"$TargetExe`""
