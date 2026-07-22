# Installation script for Flatten Directories context menu
# Requires Administrator privileges

param(
    [switch]$Force = $false
)

$ErrorActionPreference = "Stop"

# Logging setup
$logDir = "C:\ProgramData\Flatten\logs"
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$processId = [System.Diagnostics.Process]::GetCurrentProcess().Id
$logFile = Join-Path $logDir "Install_$timestamp`_PID$processId.log"

function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $logMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [$Level] $Message"
    
    # Retry mechanism for file locking issues
    $maxRetries = 3
    $retryCount = 0
    $success = $false
    
    while (-not $success -and $retryCount -lt $maxRetries) {
        try {
            Add-Content -Path $logFile -Value $logMessage -ErrorAction Stop
            $success = $true
        }
        catch {
            $retryCount++
            if ($retryCount -lt $maxRetries) {
                Start-Sleep -Milliseconds 100  # Wait 100ms before retrying
            }
        }
    }
    
    # Always output to console, regardless of log success
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

function Install-FlattenContextMenu {
    $startTime = Get-Date
    
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Flatten Directories - Installation" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Log "========================================" -Level "OPERATION"
    Write-Log "Installation started" -Level "OPERATION"
    Write-Log "========================================" -Level "OPERATION"
    Write-LogDebug "Script started at: $startTime"
    
    # Check admin privileges
    if (-not (Test-AdminPrivileges)) {
        Write-Host "ERROR: This script requires Administrator privileges!" -ForegroundColor Red
        Write-Host "Please run PowerShell as Administrator and try again." -ForegroundColor Red
        Write-LogError "Installation failed: Administrator privileges required"
        Write-Host ""
        Write-Host "Press any key to exit..." -ForegroundColor Yellow
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        exit 1
    }
    
    Write-Host "Administrator privileges confirmed." -ForegroundColor Green
    Write-Log "Administrator privileges confirmed"
    Write-Host ""
    
    # Determine installation path
    $installPath = Join-Path $env:ProgramFiles "Flatten"
    
    Write-Host "Installation path: $installPath"
    Write-LogDebug "Installation path: $installPath"
    
    # Create installation directory
    if (-not (Test-Path $installPath)) {
        Write-Host "Creating installation directory..." -ForegroundColor Yellow
        New-Item -ItemType Directory -Path $installPath -Force | Out-Null
        Write-Log "Created installation directory: $installPath"
        Write-LogDebug "Installation directory created"
    } else {
        if ($Force) {
            Write-Host "Installation directory already exists. Using -Force to overwrite." -ForegroundColor Yellow
            Write-Log "Installation directory already exists, using -Force flag"
        } else {
            Write-Host "Installation directory already exists." -ForegroundColor Yellow
            Write-LogDebug "Installation directory already exists"
        }
    }
    
    # Copy scripts to installation directory
    Write-Host ""
    Write-Host "Copying scripts to installation directory..." -ForegroundColor Yellow
    Write-Log ""
    Write-Log "Copying scripts to installation directory..."
    
    # Use $PSScriptRoot for reliable script directory detection
    if ([string]::IsNullOrEmpty($PSScriptRoot)) {
        $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    } else {
        $scriptDir = $PSScriptRoot
    }
    
    if ([string]::IsNullOrEmpty($scriptDir)) {
        Write-Host "ERROR: Could not determine script directory" -ForegroundColor Red
        Write-LogError "Could not determine script directory"
        Write-Host ""
        Write-Host "Press any key to exit..." -ForegroundColor Yellow
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        exit 1
    }
    
    Write-LogDebug "Script directory: $scriptDir"
    
    $scriptsToCopy = @(
        "Flatten-Directories.ps1",
        "FlattenIntoDirectory.ps1"
    )
    
    foreach ($script in $scriptsToCopy) {
        $sourcePath = Join-Path $scriptDir $script
        if (Test-Path $sourcePath) {
            Copy-Item -Path $sourcePath -Destination $installPath -Force
            Write-Host "  Copied: $script" -ForegroundColor Green
            Write-Log "Copied script: $script"
            Write-LogDebug "Copied from '$sourcePath' to '$installPath'"
        } else {
            Write-Host "  ERROR: Could not find $script" -ForegroundColor Red
            Write-LogError "Could not find script: $script at $sourcePath"
            Write-Host ""
            Write-Host "Press any key to exit..." -ForegroundColor Yellow
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            exit 1
        }
    }
    
    Write-Host ""
    Write-Host "Registering context menu entries..." -ForegroundColor Yellow
    Write-Log ""
    Write-Log "Registering context menu entries..."
    
    $regPath = "HKCU:\Software\Classes\Directory\shell\FlattenDirectories"
    $regPathMulti = "HKCU:\Software\Classes\Directory\shell\FlattenDirectories"
    
    # Create registry path for Method 1 (right-click menu)
    if (-not (Test-Path $regPath)) {
        New-Item -Path $regPath -Force | Out-Null
        Write-LogDebug "Created registry path: $regPath"
    }
    
    Set-ItemProperty -Path $regPath -Name "(Default)" -Value "Flatten Directories" -Force
    Set-ItemProperty -Path $regPath -Name "Icon" -Value "C:\Windows\System32\imageres.dll,46" -Force
    
    $commandPath = Join-Path $regPath "command"
    if (-not (Test-Path $commandPath)) {
        New-Item -Path $commandPath -Force | Out-Null
    }
    
    $flattenScript = Join-Path $installPath "Flatten-Directories.ps1"
    $psExe = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
    Write-LogDebug "PowerShell executable: $psExe"
    Write-LogDebug "Flatten script path: $flattenScript"
    
    # Command for Method 1: launches PowerShell with flattened folder in parent
    # IMPORTANT: pause must be INSIDE the PowerShell command so it runs even on errors
    $command = "$psExe -NoProfile -ExecutionPolicy Bypass -Command `"try { & '$flattenScript' -Paths '%L' } catch { Write-Host ('ERROR: ' + `$_) -ForegroundColor Red } ; Write-Host 'Press any key to close...' -ForegroundColor Yellow ; `$null = `$Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')`""
    
    Set-ItemProperty -Path $commandPath -Name "(Default)" -Value $command -Force
    Write-Host "  Registered: Flatten Directories" -ForegroundColor Green
    Write-Log "Registered: Flatten Directories"
    Write-LogDebug "Registry key: $commandPath"
    Write-LogDebug "Registry command: $command"
    
    # Create registry path for Method 2 (right-click drag onto target folder)
    # This uses Directory\Background so it appears when right-clicking on a folder (target)
    $regPathBackground = "HKCU:\Software\Classes\Directory\Background\shell\FlattenIntoDirectory"
    
    if (-not (Test-Path $regPathBackground)) {
        New-Item -Path $regPathBackground -Force | Out-Null
        Write-LogDebug "Created registry path: $regPathBackground"
    }
    
    Set-ItemProperty -Path $regPathBackground -Name "(Default)" -Value "Flatten Directories Into This Folder" -Force
    Set-ItemProperty -Path $regPathBackground -Name "Icon" -Value "C:\Windows\System32\imageres.dll,46" -Force
    
    $commandPathBackground = Join-Path $regPathBackground "command"
    if (-not (Test-Path $commandPathBackground)) {
        New-Item -Path $commandPathBackground -Force | Out-Null
    }
    
    $flattenIntoScript = Join-Path $installPath "FlattenIntoDirectory.ps1"
    
    # Command for Method 2: uses current directory as target
    # User will select source folders via dialog
    $commandMethod2 = "$psExe -NoProfile -ExecutionPolicy Bypass -Command `"try { & '$flattenIntoScript' -TargetPath '%V' } catch { Write-Host ('ERROR: ' + `$_) -ForegroundColor Red } ; Write-Host 'Press any key to close...' -ForegroundColor Yellow ; `$null = `$Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')`""
    
    Set-ItemProperty -Path $commandPathBackground -Name "(Default)" -Value $commandMethod2 -Force
    Write-Host "  Registered: Flatten Into This Folder (right-click drag target)" -ForegroundColor Green
    Write-Log "Registered: Flatten Into This Folder (Background context menu)"
    Write-LogDebug "Registry key: $commandPathBackground"
    Write-LogDebug "Registry command: $commandMethod2"
    
    $commandPathDrag = Join-Path $regPathDrag "command"
    if (-not (Test-Path $commandPathDrag)) {
        New-Item -Path $commandPathDrag -Force | Out-Null
    }
    
    
    # Command for Method 2: uses %V (target folder) and %L (source items)
    # IMPORTANT: pause must be INSIDE the PowerShell command so it runs even on errors
    $commandDrag = "$psExe -NoProfile -ExecutionPolicy Bypass -Command `"try { & '$flattenScript' -Paths '%L' -OutputPath '%V' } catch { Write-Host ('ERROR: ' + `$_) -ForegroundColor Red } ; Write-Host 'Press any key to close...' -ForegroundColor Yellow ; `$null = `$Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')`""
    
    Set-ItemProperty -Path $commandPathDrag -Name "(Default)" -Value $commandDrag -Force
    Write-Host "  Registered: Flatten Into This Folder (Method 2)" -ForegroundColor Green
    Write-Log "Registered: Flatten Into This Folder (Method 2)"
    Write-LogDebug "Registry key: $commandPathDrag"
    Write-LogDebug "Registry command: $commandDrag"
    
    $endTime = Get-Date
    $duration = ($endTime - $startTime).TotalSeconds
    
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
    Write-Host "Log file: $logFile" -ForegroundColor Gray
    Write-Host ""
    Write-Host "To uninstall, run: .\Uninstall-FlattenContextMenu.ps1" -ForegroundColor Gray
    Write-Host ""
    
    Write-Log ""
    Write-LogSuccess "Installation completed successfully!"
    Write-Log "Scripts installed to: $installPath" -Level "INFO"
    Write-LogDebug "Total duration: $duration seconds"
    Write-Log "========================================" -Level "OPERATION"
    Write-Log "Installation finished at: $endTime" -Level "OPERATION"
    Write-Log "========================================" -Level "OPERATION"
}

Install-FlattenContextMenu
