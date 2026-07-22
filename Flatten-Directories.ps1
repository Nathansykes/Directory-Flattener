param(
    [Parameter(Mandatory=$true)]
    [string[]]$Paths,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = $null,
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipFolderDeletion = $false
)

$ErrorActionPreference = "Continue"

# Logging setup
$logDir = "C:\ProgramData\Flatten\logs"
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logFile = Join-Path $logDir "Flatten_$timestamp.log"

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

function Get-UniqueFileName {
    param(
        [string]$FilePath,
        [string]$TargetDirectory
    )
    
    $fileName = [System.IO.Path]::GetFileNameWithoutExtension($FilePath)
    $extension = [System.IO.Path]::GetExtension($FilePath)
    $targetFile = Join-Path $TargetDirectory "$fileName$extension"
    
    if (-not (Test-Path $targetFile)) {
        return $targetFile
    }
    
    $counter = 1
    while (Test-Path $targetFile) {
        $targetFile = Join-Path $TargetDirectory "$fileName ($counter)$extension"
        $counter++
    }
    
    return $targetFile
}

function Flatten-Directory {
    param(
        [string]$SourcePath,
        [string]$TargetPath
    )
    
    Write-Log "Processing: $SourcePath"
    Write-LogDebug "Source: $SourcePath | Target: $TargetPath"
    
    $files = Get-ChildItem -Path $SourcePath -File -Recurse -ErrorAction Continue
    
    if ($files.Count -eq 0) {
        Write-Log "  No files found in $SourcePath"
        Write-LogDebug "Completed processing $SourcePath with 0 files"
        return $true
    }
    
    $movedCount = 0
    foreach ($file in $files) {
        try {
            $uniquePath = Get-UniqueFileName -FilePath $file.FullName -TargetDirectory $TargetPath
            Move-Item -Path $file.FullName -Destination $uniquePath -Force -ErrorAction Stop
            $newName = Split-Path -Leaf $uniquePath
            Write-Log "  Moved: $($file.Name) -> $newName"
            Write-LogDebug "File moved from '$($file.FullName)' to '$uniquePath'"
            $movedCount++
        }
        catch {
            Write-LogError "  ERROR moving $($file.FullName): $_"
            return $false
        }
    }
    
    Write-Log "  Total files moved: $movedCount"
    Write-LogDebug "Completed processing $SourcePath with $movedCount files moved"
    return $true
}

function Remove-EmptyDirectories {
    param(
        [string]$RootPath
    )
    
    Write-Log "Cleaning up empty directories in: $RootPath"
    Write-LogDebug "Starting recursive empty directory cleanup for: $RootPath"
    
    $removed = $true
    $totalRemoved = 0
    
    while ($removed) {
        $removed = $false
        $dirs = @(Get-ChildItem -Path $RootPath -Directory -Recurse -ErrorAction Continue | Sort-Object -Property FullName -Descending)
        
        foreach ($dir in $dirs) {
            $items = @(Get-ChildItem -Path $dir.FullName -ErrorAction Continue)
            if ($items.Count -eq 0) {
                try {
                    Remove-Item -Path $dir.FullName -Force -ErrorAction Stop
                    Write-Log "  Removed: $($dir.FullName)"
                    Write-LogDebug "Removed empty directory: $($dir.FullName)"
                    $removed = $true
                    $totalRemoved++
                }
                catch {
                    Write-LogError ("  ERROR removing " + $dir.FullName + ": " + $_)
                }
            }
        }
    }
    
    Write-LogDebug "Completed empty directory cleanup: $totalRemoved directories removed"
}

# Main execution
try {
    $startTime = Get-Date
    
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Flatten Directories Tool" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Log "========================================" -Level "OPERATION"
    Write-Log "Flatten Directories Tool - Started" -Level "OPERATION"
    Write-Log "========================================" -Level "OPERATION"
    Write-LogDebug "Script started at: $startTime"
    Write-LogDebug "Input paths: $($Paths -join '; ')"
    Write-LogDebug "Output path specified: $(-not [string]::IsNullOrEmpty($OutputPath))"
    
    # Determine output path
    if ([string]::IsNullOrEmpty($OutputPath)) {
        # Use Method 1: Create "flattened" folder in parent directory
        $firstPath = $Paths[0]
        Write-LogDebug "Method 1 detected: Creating 'flattened' folder"
        
        if ((Get-Item $firstPath).PSIsContainer) {
            $parentPath = (Get-Item $firstPath).Parent.FullName
        } else {
            $parentPath = (Get-Item $firstPath).Directory.FullName
        }
        
        $OutputPath = Join-Path $parentPath "flattened"
    } else {
        Write-LogDebug "Method 2 detected: Using target directory: $OutputPath"
    }
    
    # Create output directory if it doesn't exist
    if (-not (Test-Path $OutputPath)) {
        New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
        Write-Host "Created output directory: $OutputPath" -ForegroundColor Green
        Write-Log "Created output directory: $OutputPath"
        Write-LogDebug "Output directory created: $OutputPath"
    } else {
        Write-Host "Using existing output directory: $OutputPath" -ForegroundColor Green
    }
    
    Write-Host ""
    Write-Host "Processing $($Paths.Count) item(s)..." -ForegroundColor Yellow
    Write-Host ""
    
    Write-Log ""
    Write-Log "Processing $($Paths.Count) item(s)..."
    
    $allSuccess = $true
    $totalFiles = 0
    
    # Process each path
    foreach ($path in $Paths) {
        if (-not (Test-Path $path)) {
            Write-Host "ERROR: Path not found: $path" -ForegroundColor Red
            Write-LogError "Path not found: $path"
            $allSuccess = $false
            continue
        }
        
        $item = Get-Item $path
        Write-LogDebug "Processing item: $path (IsContainer: $($item.PSIsContainer))"
        
        if ($item.PSIsContainer) {
            # It's a directory
            if (-not (Flatten-Directory -SourcePath $path -TargetPath $OutputPath)) {
                $allSuccess = $false
            }
        } else {
            # It's a file - move it directly
            try {
                $uniquePath = Get-UniqueFileName -FilePath $path -TargetDirectory $OutputPath
                Move-Item -Path $path -Destination $uniquePath -Force
                Write-Host "Moved file: $($item.Name) -> $(Split-Path -Leaf $uniquePath)"
                Write-Log "Moved file: $($item.Name) -> $(Split-Path -Leaf $uniquePath)"
                $totalFiles++
            }
            catch {
                Write-LogError ("ERROR moving " + $path + ": " + $_)
                $allSuccess = $false
            }
        }
    }
    
    Write-Host ""
    Write-Host "Cleanup phase..." -ForegroundColor Yellow
    Write-Log ""
    Write-Log "Cleanup phase started..."
    
    # Remove empty directories from each source path
    foreach ($path in $Paths) {
        if ((Test-Path $path) -and (Get-Item $path).PSIsContainer) {
            Remove-EmptyDirectories -RootPath $path
            
            # Delete the source directory if it's empty
            $items = @(Get-ChildItem -Path $path -ErrorAction Continue)
            if ($items.Count -eq 0) {
                try {
                    Remove-Item -Path $path -Force -ErrorAction Stop
                    Write-Host "Removed empty source directory: $path" -ForegroundColor Green
                    Write-Log "Removed empty source directory: $path"
                    Write-LogDebug "Source directory deleted: $path"
                }
                catch {
                    Write-Host ("Could not remove source directory " + $path + ": " + $_) -ForegroundColor Yellow
                    Write-LogError ("Could not remove source directory " + $path + ": " + $_)
                }
            }
        }
    }
    
    $endTime = Get-Date
    $duration = ($endTime - $startTime).TotalSeconds
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    if ($allSuccess) {
        Write-Host "SUCCESS: Flattening completed!" -ForegroundColor Green
        Write-Host "Output directory: $OutputPath" -ForegroundColor Green
        Write-LogSuccess "Flattening completed successfully!"
        Write-LogDebug "Duration: $duration seconds"
        Write-LogDebug "Log file: $logFile"
    } else {
        Write-Host "COMPLETED with errors. Check output above." -ForegroundColor Yellow
        Write-Log "COMPLETED with errors. Check log for details." -Level "WARNING"
        Write-LogDebug "Duration: $duration seconds"
        Write-LogDebug "Log file: $logFile"
    }
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Log file: $logFile" -ForegroundColor Gray
    
    Write-Log ""
    Write-Log "========================================" -Level "OPERATION"
    Write-Log "Operation completed at: $endTime" -Level "OPERATION"
    Write-Log "Total duration: $duration seconds" -Level "OPERATION"
    Write-Log "========================================" -Level "OPERATION"
    
    exit 0
}
catch {
    Write-LogError ("FATAL ERROR: " + $_)
    Write-Host ("FATAL ERROR: " + $_) -ForegroundColor Red
    Write-Log "Script terminated with fatal error" -Level "ERROR"
    exit 1
}
