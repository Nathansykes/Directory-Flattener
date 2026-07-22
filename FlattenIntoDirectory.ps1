param(
    [Parameter(Mandatory=$false)]
    [string]$TargetPath = $null
)

$ErrorActionPreference = "Continue"

# Logging setup
$logDir = "C:\ProgramData\Flatten\logs"
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$processId = [System.Diagnostics.Process]::GetCurrentProcess().Id
$logFile = Join-Path $logDir "FlattenInto_$timestamp`_PID$processId.log"

function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $logMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [$Level] $Message"
    
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
                Start-Sleep -Milliseconds 100
            }
        }
    }
    
    Write-Host $Message
}

function Show-FolderBrowserDialog {
    param([string]$Description = "Select source folders to flatten")
    
    # Load required assemblies
    [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
    
    # Create folder browser dialog
    $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderBrowser.Description = $Description
    $folderBrowser.ShowNewFolderButton = $false
    
    if ($folderBrowser.ShowDialog() -eq "OK") {
        return $folderBrowser.SelectedPath
    }
    return $null
}

# Main execution
try {
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Flatten Into Directory Tool" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Log "========================================" -Level "OPERATION"
    Write-Log "Flatten Into Directory - Started" -Level "OPERATION"
    Write-Log "========================================" -Level "OPERATION"
    
    # Determine target path
    if ([string]::IsNullOrEmpty($TargetPath)) {
        # Use current directory or allow selection
        $TargetPath = Get-Location
        Write-Log "Using current directory as target: $TargetPath"
    }
    
    if (-not (Test-Path $TargetPath)) {
        Write-Host "ERROR: Target directory not found: $TargetPath" -ForegroundColor Red
        Write-Log "ERROR: Target directory not found: $TargetPath" -Level "ERROR"
        Write-Host ""
        Write-Host "Press any key to exit..." -ForegroundColor Yellow
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        exit 1
    }
    
    Write-Host "Target directory: $TargetPath" -ForegroundColor Green
    Write-Log "Target directory: $TargetPath"
    Write-Host ""
    
    # Let user select source folders
    Write-Host "Click 'OK' to browse for source folders to flatten" -ForegroundColor Yellow
    Write-Host "(Select the first folder, then hold Ctrl and click additional folders)" -ForegroundColor Gray
    Write-Host ""
    
    $sourcePaths = @()
    
    # First folder selection
    $firstFolder = Show-FolderBrowserDialog -Description "Select first source folder"
    if ([string]::IsNullOrEmpty($firstFolder)) {
        Write-Host "No folders selected. Exiting." -ForegroundColor Yellow
        Write-Log "User cancelled folder selection"
        exit 0
    }
    
    $sourcePaths += $firstFolder
    Write-Host "Selected: $firstFolder" -ForegroundColor Green
    
    # Allow multiple selections
    while ($true) {
        $result = [System.Windows.Forms.MessageBox]::Show(
            "Add another source folder?",
            "Flatten Into Directory",
            [System.Windows.Forms.MessageBoxButtons]::YesNo,
            [System.Windows.Forms.MessageBoxIcon]::Question
        )
        
        if ($result -eq "Yes") {
            $nextFolder = Show-FolderBrowserDialog -Description "Select additional source folder"
            if (-not [string]::IsNullOrEmpty($nextFolder)) {
                $sourcePaths += $nextFolder
                Write-Host "Selected: $nextFolder" -ForegroundColor Green
            }
        } else {
            break
        }
    }
    
    Write-Host ""
    Write-Host "Selected $($sourcePaths.Count) source folder(s)" -ForegroundColor Green
    Write-Log "Selected $($sourcePaths.Count) source folders"
    
    foreach ($path in $sourcePaths) {
        Write-Log "Source: $path"
    }
    
    Write-Host ""
    Write-Host "Running flatten operation..." -ForegroundColor Yellow
    Write-Host ""
    
    # Call the main flatten script with target
    $flattenScript = "C:\Program Files\Flatten\Flatten-Directories.ps1"
    
    if (-not (Test-Path $flattenScript)) {
        Write-Host "ERROR: Flatten script not found at $flattenScript" -ForegroundColor Red
        Write-Log "ERROR: Flatten script not found" -Level "ERROR"
        Write-Host ""
        Write-Host "Press any key to exit..." -ForegroundColor Yellow
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        exit 1
    }
    
    # Execute flatten with target path
    & $flattenScript -Paths $sourcePaths -OutputPath $TargetPath 2>&1
    
    Write-Log "Flatten operation completed"
    Write-Host ""
    Write-Host "Press any key to close..." -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    
    exit 0
}
catch {
    Write-Log ("FATAL ERROR: " + $_) -Level "ERROR"
    Write-Host ("FATAL ERROR: " + $_) -ForegroundColor Red
    Write-Host ""
    Write-Host "Check log file: $logFile" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Press any key to exit..." -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}
