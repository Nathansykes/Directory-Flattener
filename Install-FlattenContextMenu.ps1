# Installation script for Flatten Directories context menu
# Requires Administrator privileges

param(
    [switch]$Force = $false
)

$ErrorActionPreference = "Stop"

function Test-AdminPrivileges {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Install-FlattenContextMenu {
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Flatten Directories - Installation" -ForegroundColor Cyan
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
    
    # Determine installation path
    $installPath = Join-Path $env:ProgramFiles "Flatten"
    
    Write-Host "Installation path: $installPath"
    
    # Create installation directory
    if (-not (Test-Path $installPath)) {
        Write-Host "Creating installation directory..." -ForegroundColor Yellow
        New-Item -ItemType Directory -Path $installPath -Force | Out-Null
    } else {
        if ($Force) {
            Write-Host "Installation directory already exists. Using -Force to overwrite." -ForegroundColor Yellow
        } else {
            Write-Host "Installation directory already exists." -ForegroundColor Yellow
        }
    }
    
    # Copy scripts to installation directory
    Write-Host ""
    Write-Host "Copying scripts to installation directory..." -ForegroundColor Yellow
    
    # Use $PSScriptRoot for reliable script directory detection
    if ([string]::IsNullOrEmpty($PSScriptRoot)) {
        $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    } else {
        $scriptDir = $PSScriptRoot
    }
    
    if ([string]::IsNullOrEmpty($scriptDir)) {
        Write-Host "ERROR: Could not determine script directory" -ForegroundColor Red
        exit 1
    }
    
    $scriptsToCopy = @(
        "Flatten-Directories.ps1"
    )
    
    foreach ($script in $scriptsToCopy) {
        $sourcePath = Join-Path $scriptDir $script
        if (Test-Path $sourcePath) {
            Copy-Item -Path $sourcePath -Destination $installPath -Force
            Write-Host "  Copied: $script" -ForegroundColor Green
        } else {
            Write-Host "  ERROR: Could not find $script" -ForegroundColor Red
            exit 1
        }
    }
    
    Write-Host ""
    Write-Host "Registering context menu entries..." -ForegroundColor Yellow
    
    $regPath = "HKCU:\Software\Classes\Directory\shell\FlattenDirectories"
    $regPathMulti = "HKCU:\Software\Classes\Directory\shell\FlattenDirectories"
    
    # Create registry path for Method 1 (right-click menu)
    if (-not (Test-Path $regPath)) {
        New-Item -Path $regPath -Force | Out-Null
    }
    
    Set-ItemProperty -Path $regPath -Name "(Default)" -Value "Flatten Directories" -Force
    Set-ItemProperty -Path $regPath -Name "Icon" -Value "C:\Windows\System32\imageres.dll,46" -Force
    
    $commandPath = Join-Path $regPath "command"
    if (-not (Test-Path $commandPath)) {
        New-Item -Path $commandPath -Force | Out-Null
    }
    
    $flattenScript = Join-Path $installPath "Flatten-Directories.ps1"
    $psExe = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
    
    # Command for Method 1: launches PowerShell with flattened folder in parent
    $command = "$psExe -NoProfile -ExecutionPolicy Bypass -Command `"& '$flattenScript' -Paths '%L'`" & pause"
    
    Set-ItemProperty -Path $commandPath -Name "(Default)" -Value $command -Force
    Write-Host "  Registered: Flatten Directories (Method 1)" -ForegroundColor Green
    
    # Create registry path for Method 2 (drag and drop)
    # This uses a different registry structure for right-click drag operations
    $regPathDrag = "HKCU:\Software\Classes\Directory\shell\FlattenInto"
    
    if (-not (Test-Path $regPathDrag)) {
        New-Item -Path $regPathDrag -Force | Out-Null
    }
    
    Set-ItemProperty -Path $regPathDrag -Name "(Default)" -Value "Flatten Into This Folder" -Force
    Set-ItemProperty -Path $regPathDrag -Name "Icon" -Value "C:\Windows\System32\imageres.dll,46" -Force
    Set-ItemProperty -Path $regPathDrag -Name "MultiSelectModel" -Value "Single" -Force
    
    $commandPathDrag = Join-Path $regPathDrag "command"
    if (-not (Test-Path $commandPathDrag)) {
        New-Item -Path $commandPathDrag -Force | Out-Null
    }
    
    # Command for Method 2: uses %V (target folder) and %L (source items)
    $commandDrag = "$psExe -NoProfile -ExecutionPolicy Bypass -Command `"& '$flattenScript' -Paths '%L' -OutputPath '%V'`" & pause"
    
    Set-ItemProperty -Path $commandPathDrag -Name "(Default)" -Value $commandDrag -Force
    Write-Host "  Registered: Flatten Into This Folder (Method 2)" -ForegroundColor Green
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Installation completed successfully!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "You can now:" -ForegroundColor Cyan
    Write-Host "  • Right-click on folders and select 'Flatten Directories'" -ForegroundColor White
    Write-Host "  • Right-click drag folders to a target folder and select 'Flatten Into This Folder'" -ForegroundColor White
    Write-Host ""
    Write-Host "Scripts installed to: $installPath" -ForegroundColor Gray
    Write-Host ""
    Write-Host "To uninstall, run: .\Uninstall-FlattenContextMenu.ps1" -ForegroundColor Gray
    Write-Host ""
}

Install-FlattenContextMenu
