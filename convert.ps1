# convert.ps1 - converts YOUR OWN decrypted PS5 game ELF to a Windows app.exe using AnyPS5
# Usage:
#   powershell -ExecutionPolicy Bypass -File .\convert.ps1 -Elf "D:\game\eboot.elf" -Out "D:\game_win"
# Requirements: build.ps1 already ran successfully; the game's sce_module (or sce_modules) folder
# must sit next to the ELF (exactly one of those folders).
param(
    [Parameter(Mandatory=$true)][string]$Elf,
    [Parameter(Mandatory=$true)][string]$Out,
    [string]$Resources = ""   # optional: folder with the game's resources, copied to app0\
)
$ErrorActionPreference = "Stop"

$root = Join-Path $PSScriptRoot "AnyPS5"
$relinker = Get-ChildItem -Path (Join-Path $root "build") -Recurse -Filter "relinker.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $relinker) { throw "relinker.exe not found under $root\build. Run build.ps1 first." }
if (-not (Test-Path $Elf)) { throw "ELF not found: $Elf" }

New-Item -ItemType Directory -Force -Path $Out | Out-Null
$app = Join-Path $Out "app.exe"

Write-Host "Converting (Intel host: --to-intel)..."
& $relinker.FullName --windows --to-intel $Elf $app
if ($LASTEXITCODE -ne 0) { throw "relinker failed (exit $LASTEXITCODE). Save the output above and ask for help." }

Write-Host "Copying runtime libraries..."
$libsSrc = Join-Path $root "build\core\libs\libs"
$libsDst = Join-Path $Out "libs"
New-Item -ItemType Directory -Force -Path $libsDst | Out-Null
Copy-Item -Path (Join-Path $libsSrc "*.prx") -Destination $libsDst -Force

if ($Resources -ne "") {
    Write-Host "Copying resources to app0..."
    Copy-Item -Path $Resources -Destination (Join-Path $Out "app0") -Recurse -Force
}

Write-Host ""
Write-Host "Done. Run it from PowerShell:  cd `"$Out`" ; .\app.exe"
Write-Host "Note: the relinker also writes converted modules under app0\ - keep that folder next to app.exe."
