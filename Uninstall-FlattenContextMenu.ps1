# Uninstallation script for Flatten Directories context menu
# Removes registry entries and installation files

param(
    [switch]$KeepScripts = $false
)

$ErrorActionPreference = "Stop"

# Logging setup
$logDir = "C:\ProgramData\Flatten\logs"
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logFile = Join-Path $logDir "Uninstall_$timestamp.log"

function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $logMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [$Level] $Message"
    Add-Content -Path $logFile -Value $logMessage -ErrorAction Continue
    Write-Host $Message
}

function Write-LogError {
    param([string]$Message)
    Write-Log -Message $Message -Level "ERROR"
}

function Write-LogSuccess {
    param([string]$Message)
    Write-Log -Message $Message -Level "SUCCESS"
}

function Write-LogDebug {
    param([string]$Message)
    Write-Log -Message $Message -Level "DEBUG"
}

function Test-AdminPrivileges {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Uninstall-FlattenContextMenu {
    $startTime = Get-Date
    
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Flatten Directories - Uninstallation" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Log "========================================" -Level "OPERATION"
    Write-Log "Uninstallation started" -Level "OPERATION"
    Write-Log "========================================" -Level "OPERATION"
    Write-LogDebug "Script started at: $startTime"
    Write-LogDebug "KeepScripts flag: $KeepScripts"
    
    # Check admin privileges
    if (-not (Test-AdminPrivileges)) {
        Write-Host "ERROR: This script requires Administrator privileges!" -ForegroundColor Red
        Write-Host "Please run PowerShell as Administrator and try again." -ForegroundColor Red
        Write-LogError "Uninstallation failed: Administrator privileges required"
        Write-Host ""
        Write-Host "Press any key to exit..." -ForegroundColor Yellow
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        exit 1
    }
    
    Write-Host "Administrator privileges confirmed." -ForegroundColor Green
    Write-Log "Administrator privileges confirmed"
    Write-Host ""
    
    # Remove registry entries
    Write-Host "Removing registry entries..." -ForegroundColor Yellow
    Write-Log "Removing registry entries..."
    
    $regPaths = @(
        "HKCU:\Software\Classes\Directory\shell\FlattenDirectories",
        "HKCU:\Software\Classes\Directory\shell\FlattenInto"
    )
    
    foreach ($regPath in $regPaths) {
        if (Test-Path $regPath) {
            Remove-Item -Path $regPath -Recurse -Force
            Write-Host "  Removed: $regPath" -ForegroundColor Green
            Write-Log "Removed registry key: $regPath"
            Write-LogDebug "Registry entry removed: $regPath"
        } else {
            Write-Host "  Not found: $regPath" -ForegroundColor Gray
            Write-LogDebug "Registry key not found: $regPath"
        }
    }
    
    Write-Host ""
    
    # Remove installation directory
    $installPath = Join-Path $env:ProgramFiles "Flatten"
    
    if (Test-Path $installPath) {
        if ($KeepScripts) {
            Write-Host "Installation scripts retained at: $installPath" -ForegroundColor Yellow
            Write-Log "Installation scripts retained at: $installPath"
            Write-LogDebug "KeepScripts flag set: Scripts not removed"
        } else {
            Write-Host "Removing installation directory..." -ForegroundColor Yellow
            Write-Log "Removing installation directory..."
            Remove-Item -Path $installPath -Recurse -Force
            Write-Host "  Removed: $installPath" -ForegroundColor Green
            Write-Log "Removed installation directory: $installPath"
            Write-LogDebug "Installation directory removed: $installPath"
        }
    }
    
    $endTime = Get-Date
    $duration = ($endTime - $startTime).TotalSeconds
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Uninstallation completed!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Context menu entries have been removed." -ForegroundColor Green
    Write-Host "Log file: $logFile" -ForegroundColor Gray
    Write-Host ""
    
    Write-Log ""
    Write-LogSuccess "Uninstallation completed successfully!"
    Write-LogDebug "Total duration: $duration seconds"
    Write-Log "========================================" -Level "OPERATION"
    Write-Log "Uninstallation finished at: $endTime" -Level "OPERATION"
    Write-Log "========================================" -Level "OPERATION"
}

Uninstall-FlattenContextMenu
