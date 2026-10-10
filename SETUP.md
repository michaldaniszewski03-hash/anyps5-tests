# AnyPS5 setup for an HP EliteBook 830 G5 (Core i7, 16 GB RAM, Intel UHD 620)

Everything here runs on **your Windows laptop**. Nothing in this repo contains game files.

## What you need
- Windows 10/11 64-bit.
- Your **own, legally obtained, already-decrypted** copy of the game as an ELF with its `sce_module`
  (or `sce_modules`) folder next to it. AnyPS5 does not decrypt games and does not include any.
- Up-to-date Intel graphics driver (Windows Update or Intel Driver & Support Assistant).

## Steps
1. Check graphics support first: install *GPU Caps Viewer* (or run `vulkaninfo`) and note the Vulkan version.
   The AnyPS5 docs state no GPU requirement; the UHD 620 is far weaker than the GTX 1050 Ti used in the
   project's Dreaming Sarah result, so expect it may be slow or not work. This is untested.
2. In PowerShell, in this folder: `powershell -ExecutionPolicy Bypass -File .\build.ps1`
   - Installs Git, CMake, Ninja and MinGW-w64 GCC via winget, clones AnyPS5, builds it.
   - AnyPS5 supports only MinGW-w64 GCC 15.2.0 (WinLibs `x86_64-ucrt-posix-seh`). The script warns if yours differs.
   - If tools were just installed, open a NEW PowerShell and run it again.
3. Convert your game:
   `powershell -ExecutionPolicy Bypass -File .\convert.ps1 -Elf "D:\game\eboot.elf" -Out "D:\game_win"`
   - Uses `--windows --to-intel`. `--to-intel` rewrites AMD-only CPU instructions so the code runs on your Intel i7.
4. Run: `cd D:\game_win ; .\app.exe`

## Controls
SDL-mapped controllers work. Keyboard/mouse is configured with an `anyps5-input.ini`
(see AnyPS5 `docs/user/INPUT_MAPPING.md`).

## Troubleshooting
- Build errors: send me the last ~30 lines of output.
- `relinker` errors on unsupported instructions: send me the message; AnyPS5 deliberately stops on unsupported states.
- Do not use the deprecated flags (`--skip-sce-module`, `--lazy-binding`, etc.); the docs say they make apps very unstable.
- Alternative project: PortPS5 (ymatrix1/PortPS5) needs Vulkan 1.3 and is not yet proven on integrated graphics.
