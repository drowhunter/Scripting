param(
    [Parameter(Mandatory=$true)]
    [string]$GameRoot
)

# Epic manifest output directory
$ManifestOut = "C:\ProgramData\Epic\EpicGamesLauncher\Data\Manifests"

if (-not (Test-Path $ManifestOut)) {
    Write-Host "Epic manifest directory not found: $ManifestOut" -ForegroundColor Red
    exit 1
}

Write-Host "Scanning Epic game directory: $GameRoot" -ForegroundColor Cyan

# Enumerate game folders
$games = Get-ChildItem -Path $GameRoot -Directory

foreach ($game in $games) {

    $manifestPath = Join-Path $game.FullName ".egstore\Manifest.sjson"

    if (-not (Test-Path $manifestPath)) {
        Write-Host "Skipping '$($game.Name)' — no Manifest.sjson found." -ForegroundColor DarkYellow
        continue
    }

    Write-Host "Processing '$($game.Name)'..." -ForegroundColor Green

    # Load Manifest.sjson
    $json = Get-Content $manifestPath -Raw | ConvertFrom-Json

    # Build .item manifest object
    $item = [ordered]@{
        FormatVersion          = 0
        AppName                = $json.AppName
        CatalogItemId          = $json.CatalogItemId
        CatalogNamespace       = $json.CatalogNamespace
        DisplayName            = $json.DisplayName
        InstallLocation        = $game.FullName
        InstallSize            = $json.InstallSize
        MainGameAppName        = $json.AppName
        MandatoryPatchSequence = 0
    }

    # Generate random filename
    $fileName = ("{0}.item" -f ([guid]::NewGuid().ToString("N")))
    $outPath = Join-Path $ManifestOut $fileName

    # Write manifest
    $item | ConvertTo-Json -Depth 10 | Out-File -Encoding UTF8 $outPath

    Write-Host " → Created manifest: $fileName" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "Done! Restart Epic Games Launcher to rediscover your library." -ForegroundColor Magenta
