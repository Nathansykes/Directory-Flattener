param(
    [Parameter(Mandatory=$true)]
    [string[]]$Paths,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = $null,
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipFolderDeletion = $false
)

$ErrorActionPreference = "Continue"

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
    
    Write-Host "Processing: $SourcePath"
    
    $files = Get-ChildItem -Path $SourcePath -File -Recurse -ErrorAction Continue
    
    if ($files.Count -eq 0) {
        Write-Host "  No files found in $SourcePath"
        return $true
    }
    
    $movedCount = 0
    foreach ($file in $files) {
        try {
            $uniquePath = Get-UniqueFileName -FilePath $file.FullName -TargetDirectory $TargetPath
            Move-Item -Path $file.FullName -Destination $uniquePath -Force -ErrorAction Stop
            Write-Host "  Moved: $($file.Name) -> $(Split-Path -Leaf $uniquePath)"
            $movedCount++
        }
        catch {
            Write-Host ("  ERROR moving " + $file.FullName + ": " + $_) -ForegroundColor Red
            return $false
        }
    }
    
    Write-Host "  Total files moved: $movedCount"
    return $true
}

function Remove-EmptyDirectories {
    param(
        [string]$RootPath
    )
    
    Write-Host "Cleaning up empty directories in: $RootPath"
    
    $removed = $true
    while ($removed) {
        $removed = $false
        $dirs = @(Get-ChildItem -Path $RootPath -Directory -Recurse -ErrorAction Continue | Sort-Object -Property FullName -Descending)
        
        foreach ($dir in $dirs) {
            $items = @(Get-ChildItem -Path $dir.FullName -ErrorAction Continue)
            if ($items.Count -eq 0) {
                try {
                    Remove-Item -Path $dir.FullName -Force -ErrorAction Stop
                    Write-Host "  Removed: $($dir.FullName)"
                    $removed = $true
                }
                catch {
                    Write-Host ("  ERROR removing " + $dir.FullName + ": " + $_) -ForegroundColor Red
                }
            }
        }
    }
}

# Main execution
try {
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Flatten Directories Tool" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Determine output path
    if ([string]::IsNullOrEmpty($OutputPath)) {
        # Use Method 1: Create "flattened" folder in parent directory
        $firstPath = $Paths[0]
        
        if ((Get-Item $firstPath).PSIsContainer) {
            $parentPath = (Get-Item $firstPath).Parent.FullName
        } else {
            $parentPath = (Get-Item $firstPath).Directory.FullName
        }
        
        $OutputPath = Join-Path $parentPath "flattened"
    }
    
    # Create output directory if it doesn't exist
    if (-not (Test-Path $OutputPath)) {
        New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
        Write-Host "Created output directory: $OutputPath" -ForegroundColor Green
    } else {
        Write-Host "Using existing output directory: $OutputPath" -ForegroundColor Green
    }
    
    Write-Host ""
    Write-Host "Processing $($Paths.Count) item(s)..." -ForegroundColor Yellow
    Write-Host ""
    
    $allSuccess = $true
    $totalFiles = 0
    
    # Process each path
    foreach ($path in $Paths) {
        if (-not (Test-Path $path)) {
            Write-Host "ERROR: Path not found: $path" -ForegroundColor Red
            $allSuccess = $false
            continue
        }
        
        $item = Get-Item $path
        
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
                $totalFiles++
            }
            catch {
                Write-Host ("ERROR moving " + $path + ": " + $_) -ForegroundColor Red
                $allSuccess = $false
            }
        }
    }
    
    Write-Host ""
    Write-Host "Cleanup phase..." -ForegroundColor Yellow
    
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
                }
                catch {
                    Write-Host ("Could not remove source directory " + $path + ": " + $_) -ForegroundColor Yellow
                }
            }
        }
    }
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    if ($allSuccess) {
        Write-Host "SUCCESS: Flattening completed!" -ForegroundColor Green
        Write-Host "Output directory: $OutputPath" -ForegroundColor Green
    } else {
        Write-Host "COMPLETED with errors. Check output above." -ForegroundColor Yellow
    }
    Write-Host "========================================" -ForegroundColor Cyan
    
    exit 0
}
catch {
    Write-Host ("FATAL ERROR: " + $_) -ForegroundColor Red
    exit 1
}
