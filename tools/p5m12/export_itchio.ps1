param(
    [string]$GodotExe = "F:\Applications\Godot\Godot_v4.7-stable_win64_console.exe",
    [string]$ProjectPath = "project",
    [string]$PresetName = "FacelessVoid Web Itch",
    [string]$ExportDir = "project\export\web\itch",
    [string]$PackageDir = "release\itchio",
    [string]$PackageName = "facelessvoid-phase6-itch.zip"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $GodotExe)) {
    throw "Godot executable not found: $GodotExe"
}

New-Item -ItemType Directory -Force -Path $ExportDir | Out-Null
New-Item -ItemType Directory -Force -Path $PackageDir | Out-Null

$resolvedExportDir = (Resolve-Path -LiteralPath $ExportDir).Path
$resolvedPackageDir = (Resolve-Path -LiteralPath $PackageDir).Path

Get-ChildItem -LiteralPath $resolvedExportDir -Force | Remove-Item -Recurse -Force

$exportPath = Join-Path $resolvedExportDir "index.html"
Write-Host "Exporting $PresetName to $exportPath"
& $GodotExe --headless --path $ProjectPath --export-release $PresetName $exportPath
if ($LASTEXITCODE -ne 0) {
    throw "Godot web export failed with exit code $LASTEXITCODE"
}

$required = @("index.html")
foreach ($file in $required) {
    $path = Join-Path $resolvedExportDir $file
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Required itch.io export file missing: $path"
    }
}

$files = Get-ChildItem -LiteralPath $resolvedExportDir -Recurse -File
if ($files.Count -gt 1000) {
    throw "itch.io HTML5 file-count limit exceeded: $($files.Count) files"
}

$exportRoot = $resolvedExportDir
$totalBytes = 0L
foreach ($file in $files) {
    $relative = $file.FullName.Substring($exportRoot.Length).TrimStart("\", "/")
    if ($relative.Length -gt 240) {
        throw "itch.io path-length limit exceeded: $relative"
    }
    if ($file.Length -gt 200MB) {
        throw "itch.io single-file size limit exceeded: $relative"
    }
    $totalBytes += $file.Length
}

if ($totalBytes -gt 500MB) {
    throw "itch.io extracted-size limit exceeded: $([Math]::Round($totalBytes / 1MB, 2)) MB"
}

$packagePath = Join-Path $resolvedPackageDir $PackageName
if (Test-Path -LiteralPath $packagePath) {
    Remove-Item -LiteralPath $packagePath -Force
}

Compress-Archive -Path (Join-Path $resolvedExportDir "*") -DestinationPath $packagePath -Force

Write-Host "Created itch.io package: $packagePath"
Write-Host "Exported files: $($files.Count)"
Write-Host "Extracted size MB: $([Math]::Round($totalBytes / 1MB, 2))"
