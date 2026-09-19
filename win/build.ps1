# Copyright (C) 2026 ShadowPlague21 / VCamdroid
$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path "$PSScriptRoot\..").Path
$depsDir = Join-Path $repoRoot "deps"
if (!(Test-Path $depsDir)) { New-Item -ItemType Directory -Path $depsDir | Out-Null }

Write-Host "=== Setting up Windows build environment ==="

# 1. Clone obs-studio for headers (libobs, UI/obs-frontend-api, deps/w32-pthreads)
$obsDir = Join-Path $depsDir "obs-studio"
if (!(Test-Path $obsDir)) {
    Write-Host "Cloning obs-studio headers (tag 32.2.1)..."
    git clone --depth 1 --branch 32.2.1 https://github.com/obsproject/obs-studio.git $obsDir
}

# Ensure libobs/obsconfig.h exists
Set-Content -Path "$obsDir\libobs\obsconfig.h" -Value @"
#pragma once
#define OBS_VERSION "32.2.1"
#define OBS_DATA_PATH "data"
#define OBS_INSTALL_PREFIX ""
#define OBS_PLUGIN_DESTINATION "obs-plugins/64bit"
#define OBS_RELEASE_CANDIDATE 0
#define OBS_BETA 0
"@

# 2. Download and extract obs-deps (contains FFmpeg headers & libs: avcodec.lib, avutil.lib)
$obsDepsExtract = Join-Path $depsDir "obs-deps"
if (!(Test-Path $obsDepsExtract)) {
    Write-Host "Downloading obs-deps (FFmpeg, etc.)..."
    $obsDepsZip = Join-Path $depsDir "windows-deps.zip"
    curl.exe -L -o $obsDepsZip "https://github.com/obsproject/obs-deps/releases/download/2026-08-26/windows-deps-2026-08-26-x64.zip"
    New-Item -ItemType Directory -Path $obsDepsExtract | Out-Null
    tar.exe -xf $obsDepsZip -C $obsDepsExtract
    Remove-Item $obsDepsZip -Force
}

# 3. Download and extract libjpeg-turbo (for turbojpeg.h and turbojpeg-static.lib)
$turboDir = Join-Path $depsDir "libjpeg-turbo"
if (!(Test-Path $turboDir)) {
    Write-Host "Downloading libjpeg-turbo..."
    $turboExe = Join-Path $depsDir "turbojpeg.exe"
    curl.exe -L -o $turboExe "https://github.com/libjpeg-turbo/libjpeg-turbo/releases/download/3.2.0/libjpeg-turbo-3.2.0-vc-x64.exe"
    7z.exe x $turboExe "-o$turboDir" -y
    Remove-Item $turboExe -Force
}

# 4. Clone libusbmuxd, libplist & libimobiledevice for headers
$usbmuxDir = Join-Path $depsDir "libusbmuxd"
if (!(Test-Path $usbmuxDir)) {
    Write-Host "Cloning libusbmuxd headers..."
    git clone --depth 1 https://github.com/libimobiledevice/libusbmuxd.git $usbmuxDir
}
$plistDir = Join-Path $depsDir "libplist"
if (!(Test-Path $plistDir)) {
    Write-Host "Cloning libplist headers..."
    git clone --depth 1 https://github.com/libimobiledevice/libplist.git $plistDir
}
$ideviceDir = Join-Path $depsDir "libimobiledevice"
if (!(Test-Path $ideviceDir)) {
    Write-Host "Cloning libimobiledevice headers..."
    git clone --depth 1 https://github.com/libimobiledevice/libimobiledevice.git $ideviceDir
}

# 5. Generate import libraries from .def files
Write-Host "Generating import libraries from .def files..."
lib.exe /nologo /def:"$PSScriptRoot\obs.def" /machine:x64 /out:"$depsDir\obs.lib"
lib.exe /nologo /def:"$PSScriptRoot\obs-frontend-api.def" /machine:x64 /out:"$depsDir\obs-frontend-api.lib"
lib.exe /nologo /def:"$PSScriptRoot\w32-pthreads.def" /machine:x64 /out:"$depsDir\w32-pthreads.lib"

# 6. Create build output folder
$buildDir = Join-Path $repoRoot "build"
if (!(Test-Path $buildDir)) { New-Item -ItemType Directory -Path $buildDir | Out-Null }

# 7. Compile DroidCam OBS plugin DLL
Write-Host "Compiling droidcam-obs.dll with MSVC..."

$srcFiles = @(
    "$repoRoot\src\sys\win\util.cc",
    "$repoRoot\src\sys\win\cmd.cc",
    "$repoRoot\src\proxy.cc",
    "$repoRoot\src\net.cc",
    "$repoRoot\src\mdns_discovery.cc",
    "$repoRoot\src\source.cc",
    "$repoRoot\src\device_discovery.cc",
    "$repoRoot\src\plugin.cc",
    "$repoRoot\src\mjpeg_decode.cc",
    "$repoRoot\src\ffmpeg_decode.cc"
)

$includes = @(
    "/I$repoRoot\src",
    "/I$obsDir\libobs",
    "/I$obsDir\UI\obs-frontend-api",
    "/I$obsDir\deps\w32-pthreads",
    "/I$obsDepsExtract\include",
    "/I$turboDir\include",
    "/I$usbmuxDir\include",
    "/I$plistDir\include",
    "/I$ideviceDir\include"
)

$libs = @(
    "$depsDir\obs.lib",
    "$depsDir\obs-frontend-api.lib",
    "$depsDir\w32-pthreads.lib",
    "$obsDepsExtract\lib\avcodec.lib",
    "$obsDepsExtract\lib\avutil.lib",
    "$turboDir\lib\turbojpeg-static.lib",
    "ws2_32.lib",
    "user32.lib",
    "shell32.lib",
    "advapi32.lib"
)

$compileArgs = @(
    "/nologo",
    "/LD",
    "/O2",
    "/std:c++17",
    "/EHsc",
    "/MD",
    "/DWIN32",
    "/D_WINDOWS",
    "/D_USRDLL",
    "/D_WINDLL",
    "/D_CRT_SECURE_NO_WARNINGS"
) + $includes + $srcFiles + @("/link", "/nologo", "/OUT:$buildDir\droidcam-obs.dll") + $libs

Write-Host "Executing cl.exe with arguments:"
$compileArgs | ForEach-Object { Write-Host "  $_" }

& cl.exe @compileArgs

if ($LASTEXITCODE -ne 0) {
    throw "cl.exe failed with exit code $LASTEXITCODE"
}

if (!(Test-Path "$buildDir\droidcam-obs.dll")) {
    throw "Build failed: $buildDir\droidcam-obs.dll does not exist"
}

$dllSize = (Get-Item "$buildDir\droidcam-obs.dll").Length
Write-Host "=== Build Succeeded! ==="
Write-Host "Output: $buildDir\droidcam-obs.dll ($([Math]::Round($dllSize / 1MB, 2)) MB, $dllSize bytes)"
