# build.ps1 - builds AnyPS5 on Windows 10/11 (run in PowerShell)
# Usage:  powershell -ExecutionPolicy Bypass -File .\build.ps1
$ErrorActionPreference = "Stop"

function Need($cmd) { return [bool](Get-Command $cmd -ErrorAction SilentlyContinue) }

# Reload PATH from the registry so tools installed a moment ago (or in an older window) are found
# without needing to open a new PowerShell.
function Refresh-Path {
    $m = [Environment]::GetEnvironmentVariable("Path", "Machine")
    $u = [Environment]::GetEnvironmentVariable("Path", "User")
    $env:Path = (@($m, $u) | Where-Object { $_ }) -join ";"
}
Refresh-Path

$gccId = "BrechtSanders.WinLibs.POSIX.UCRT"
function Gcc-Version { if (Need "gcc") { return (& gcc --version | Select-Object -First 1) } else { return "" } }

Write-Host "== 1/4 Installing tools with winget (skips what is already installed) =="
if (-not (Need "winget")) { throw "winget not found. Update 'App Installer' from the Microsoft Store and retry." }
if (-not (Need "git"))   { winget install -e --id Git.Git --accept-package-agreements --accept-source-agreements }
if (-not (Need "cmake")) { winget install -e --id Kitware.CMake --accept-package-agreements --accept-source-agreements }
if (-not (Need "ninja")) { winget install -e --id Ninja-build.Ninja --accept-package-agreements --accept-source-agreements }
Refresh-Path

# AnyPS5 supports ONLY GCC 15.2.0. winget's default WinLibs is newer (16.x), so pin a 15.2.0 build.
$ver = Gcc-Version
if ($ver -notmatch "15\.2") {
    if ($ver -ne "") {
        Write-Host "Found '$ver' - replacing it with GCC 15.2.0 (AnyPS5 supports only 15.2.0)."
        winget uninstall -e --id $gccId
    }
    $versions = winget show -e --id $gccId --versions | Where-Object { $_ -match "^15\.2\.0" }
    if (-not $versions) { throw "winget has no WinLibs 15.2.0 version listed. Download 'winlibs-x86_64-posix-seh-gcc-15.2.0-mingw-w64ucrt-14.0.0-r7' from https://github.com/brechtsanders/winlibs_mingw/releases , unzip it, add its mingw64\bin to PATH, then rerun." }
    $pick = ($versions | Select-Object -First 1).Trim()
    Write-Host "Installing WinLibs $pick"
    winget install -e --id $gccId --version $pick --accept-package-agreements --accept-source-agreements
    Refresh-Path
}

foreach ($t in "git","cmake","ninja","gcc") { if (-not (Need $t)) { throw "'$t' still not found on PATH. Open a NEW PowerShell window and rerun this script." } }

$ver = Gcc-Version
Write-Host "Compiler: $ver"
if ($ver -notmatch "15\.2") {
    Write-Warning "Compiler is not GCC 15.2.0; AnyPS5 documents only 15.2.0 as supported, so the build may fail."
}

Write-Host "== 2/4 Cloning AnyPS5 =="
if (-not (Test-Path ".\AnyPS5")) { git clone https://github.com/boykopovar/AnyPS5 }
Set-Location .\AnyPS5
git submodule update --init --recursive

Write-Host "== 3/4 Configuring =="
cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_C_COMPILER=gcc -DCMAKE_CXX_COMPILER=g++

Write-Host "== 4/4 Building (this takes a while) =="
cmake --build build --parallel
cmake --build build --target libs --parallel

Write-Host ""
Write-Host "Done. Next: .\convert.ps1 -Elf <path to your decrypted eboot.elf> -Out <output folder>"
