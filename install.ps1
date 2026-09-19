# Ensure admin elevation
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

$sourceDll = "$PSScriptRoot\build\vcamdroid-obs.dll"
if (!(Test-Path $sourceDll)) {
    $sourceDll = "$PSScriptRoot\build\droidcam-obs.dll"
}

$targetPluginsDir = "C:\Program Files\obs-studio\obs-plugins\64bit"
$targetDllPrimary = "$targetPluginsDir\vcamdroid-obs.dll"
$legacyDll        = "$targetPluginsDir\droidcam-obs.dll"
$backupDll        = "$targetPluginsDir\droidcam-obs.dll.original.bak"

$dataSrcDir       = "$PSScriptRoot\data"
$dataTargetDir    = "C:\Program Files\obs-studio\data\obs-plugins\vcamdroid-obs"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  Installing VCamdroid OBS Plugin (Windows) " -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# 1. Check if OBS is running
$obsProc = Get-Process -Name "obs64" -ErrorAction SilentlyContinue
if ($obsProc) {
    Write-Host "[!] OBS Studio is currently running." -ForegroundColor Yellow
    Write-Host "    Closing OBS Studio to allow replacing the plugin DLL..." -ForegroundColor Yellow
    $obsProc.CloseMainWindow() | Out-Null
    Start-Sleep -Seconds 3
    if (Get-Process -Name "obs64" -ErrorAction SilentlyContinue) {
        Stop-Process -Name "obs64" -Force
    }
    Write-Host "[OK] OBS Studio closed." -ForegroundColor Green
}

# 2. Verify source DLL exists or download
if (!(Test-Path $sourceDll)) {
    Write-Host "[*] Downloading latest plugin from GitHub Release..." -ForegroundColor Cyan
    if (!(Test-Path "$PSScriptRoot\build")) { New-Item -ItemType Directory -Path "$PSScriptRoot\build" | Out-Null }
    try {
        Invoke-WebRequest -Uri "https://github.com/ShadowPlague21/VCamdroid-obs-plugin/releases/download/latest/vcamdroid-obs.dll" -OutFile "$PSScriptRoot\build\vcamdroid-obs.dll"
        $sourceDll = "$PSScriptRoot\build\vcamdroid-obs.dll"
    } catch {
        Invoke-WebRequest -Uri "https://github.com/ShadowPlague21/VCamdroid-obs-plugin/releases/download/latest/droidcam-obs.dll" -OutFile "$PSScriptRoot\build\droidcam-obs.dll"
        $sourceDll = "$PSScriptRoot\build\droidcam-obs.dll"
    }
}

# 3. Clean up legacy droidcam-obs.dll to prevent duplicate plugin loading
if (Test-Path $legacyDll) {
    if (!(Test-Path $backupDll)) {
        # Check if legacy DLL is different from the new one before backing up
        $newHash = (Get-FileHash $sourceDll -Algorithm SHA256).Hash
        $oldHash = (Get-FileHash $legacyDll -Algorithm SHA256).Hash
        if ($newHash -ne $oldHash) {
            Copy-Item -Path $legacyDll -Destination $backupDll -Force
            Write-Host "[OK] Backed up original droidcam-obs.dll to: $backupDll" -ForegroundColor Green
        }
    }
    Remove-Item -Path $legacyDll -Force
    Write-Host "[OK] Removed legacy droidcam-obs.dll to eliminate duplicate entries in OBS." -ForegroundColor Green
}

# 4. Copy new DLL to vcamdroid-obs.dll (Single plugin instance)
Copy-Item -Path $sourceDll -Destination $targetDllPrimary -Force
Write-Host "[OK] Successfully installed single primary plugin:" -ForegroundColor Green
Write-Host "     -> $targetDllPrimary" -ForegroundColor Green

# 5. Copy locale and assets to data\obs-plugins\vcamdroid-obs
if (Test-Path $dataSrcDir) {
    if (!(Test-Path $dataTargetDir)) {
        New-Item -ItemType Directory -Path $dataTargetDir -Force | Out-Null
    }
    Copy-Item -Path "$dataSrcDir\*" -Destination $dataTargetDir -Recurse -Force
    Write-Host "[OK] Installed plugin assets & locales to:" -ForegroundColor Green
    Write-Host "     -> $dataTargetDir" -ForegroundColor Green
}

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Installation Complete! You can now start OBS Studio." -ForegroundColor Cyan
Write-Host "Only one clean 'VCamdroid' source will appear in OBS." -ForegroundColor Green
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
