# Uninstallation script for Flatten Directories context menu
# Removes registry entries and installation files

param(
    [switch]$KeepScripts = $false
)

$ErrorActionPreference = "Stop"

function Test-AdminPrivileges {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Uninstall-FlattenContextMenu {
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Flatten Directories - Uninstallation" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Check admin privileges
    if (-not (Test-AdminPrivileges)) {
        Write-Host "ERROR: This script requires Administrator privileges!" -ForegroundColor Red
        Write-Host "Please run PowerShell as Administrator and try again." -ForegroundColor Red
        exit 1
    }
    
    Write-Host "Administrator privileges confirmed." -ForegroundColor Green
    Write-Host ""
    
    # Remove registry entries
    Write-Host "Removing registry entries..." -ForegroundColor Yellow
    
    $regPaths = @(
        "HKCU:\Software\Classes\Directory\shell\FlattenDirectories",
        "HKCU:\Software\Classes\Directory\shell\FlattenInto"
    )
    
    foreach ($regPath in $regPaths) {
        if (Test-Path $regPath) {
            Remove-Item -Path $regPath -Recurse -Force
            Write-Host "  Removed: $regPath" -ForegroundColor Green
        } else {
            Write-Host "  Not found: $regPath" -ForegroundColor Gray
        }
    }
    
    Write-Host ""
    
    # Remove installation directory
    $installPath = Join-Path $env:ProgramFiles "Flatten"
    
    if (Test-Path $installPath) {
        if ($KeepScripts) {
            Write-Host "Installation scripts retained at: $installPath" -ForegroundColor Yellow
        } else {
            Write-Host "Removing installation directory..." -ForegroundColor Yellow
            Remove-Item -Path $installPath -Recurse -Force
            Write-Host "  Removed: $installPath" -ForegroundColor Green
        }
    }
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Uninstallation completed!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Context menu entries have been removed." -ForegroundColor Green
    Write-Host ""
}

Uninstall-FlattenContextMenu
