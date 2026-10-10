# build.ps1 - builds AnyPS5 on Windows 10/11 (run in PowerShell)
# Usage:  powershell -ExecutionPolicy Bypass -File .\build.ps1
$ErrorActionPreference = "Stop"

function Need($cmd) { return [bool](Get-Command $cmd -ErrorAction SilentlyContinue) }

Write-Host "== 1/4 Installing tools with winget (skips what is already installed) =="
if (-not (Need "winget")) { throw "winget not found. Update 'App Installer' from the Microsoft Store and retry." }
if (-not (Need "git"))   { winget install -e --id Git.Git --accept-package-agreements --accept-source-agreements }
if (-not (Need "cmake")) { winget install -e --id Kitware.CMake --accept-package-agreements --accept-source-agreements }
if (-not (Need "ninja")) { winget install -e --id Ninja-build.Ninja --accept-package-agreements --accept-source-agreements }
if (-not (Need "gcc"))   { winget install -e --id BrechtSanders.WinLibs.POSIX.UCRT --accept-package-agreements --accept-source-agreements }

Write-Host ""
Write-Host "If any tool was just installed, CLOSE this window, open a NEW PowerShell, and run this script again"
Write-Host "so PATH picks the tools up."
foreach ($t in "git","cmake","ninja","gcc") { if (-not (Need $t)) { throw "'$t' is not on PATH yet. Open a new PowerShell and rerun." } }

$ver = (& gcc --version | Select-Object -First 1)
Write-Host "Compiler: $ver"
if ($ver -notmatch "15\.2") {
    Write-Warning "AnyPS5 documents ONLY MinGW-w64 GCC 15.2.0 (WinLibs x86_64-ucrt-posix-seh) as supported. Yours differs; the build may fail."
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
