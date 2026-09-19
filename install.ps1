# Ensure admin elevation
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

$sourceDll = "$PSScriptRoot\build\droidcam-obs.dll"
$targetDir = "C:\Program Files\obs-studio\obs-plugins\64bit"
$targetDll = "$targetDir\droidcam-obs.dll"
$backupDll = "$targetDir\droidcam-obs.dll.original.bak"

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

# 2. Verify source DLL exists
if (!(Test-Path $sourceDll)) {
    Write-Host "[*] Downloading latest droidcam-obs.dll from GitHub Release..." -ForegroundColor Cyan
    if (!(Test-Path "$PSScriptRoot\build")) { New-Item -ItemType Directory -Path "$PSScriptRoot\build" | Out-Null }
    Invoke-WebRequest -Uri "https://github.com/ShadowPlague21/VCamdroid-obs-plugin/releases/download/latest/droidcam-obs.dll" -OutFile $sourceDll
}

# 3. Create backup of original DLL
if ((Test-Path $targetDll) -and !(Test-Path $backupDll)) {
    Copy-Item -Path $targetDll -Destination $backupDll -Force
    Write-Host "[OK] Backed up original DLL to: $backupDll" -ForegroundColor Green
}

# 4. Copy new DLL
Copy-Item -Path $sourceDll -Destination $targetDll -Force
Write-Host "[OK] Successfully installed droidcam-obs.dll into:" -ForegroundColor Green
Write-Host "     $targetDll" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Installation Complete! You can now start OBS Studio." -ForegroundColor Cyan
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
