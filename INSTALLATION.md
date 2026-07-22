# Flatten Directories - Installation & Setup Guide

## Overview

The Flatten Directories tool provides two methods to flatten nested directory structures:

1. **Method 1**: Right-click context menu on selected folders
2. **Method 2**: Right-click drag folders to a target location

## Prerequisites

- Windows 10 or later
- PowerShell 5.0 or later
- Administrator privileges (for installation only)

## Installation

### Step 1: Prepare PowerShell Execution Policy

If you encounter execution policy restrictions, you may need to adjust your PowerShell execution policy:

```powershell
# Check current policy
Get-ExecutionPolicy

# If needed, set to RemoteSigned (allows local scripts to run)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Step 2: Run Installation Script

1. Open PowerShell as Administrator
2. Navigate to the Flatten repository directory
3. Run the installation script:

```powershell
.\Install-FlattenContextMenu.ps1
```

This will:
- Create `C:\Program Files\Flatten\` directory
- Copy the flattening script to the installation directory
- Register both context menu methods in the Windows Registry
- Create shortcuts that appear in File Explorer's context menu

### Verification

After installation, you should see these options when right-clicking on folders in File Explorer:

- **"Flatten Directories"** - Method 1 (flatten to parent directory)
- **"Flatten Into This Folder"** - Method 2 (flatten into a specific target directory)

## Usage

### Method 1: Flatten to Parent Directory

1. Open File Explorer
2. Select one or more folders you want to flatten
3. Right-click and select **"Flatten Directories"**
4. A PowerShell window opens showing the flattening progress
5. A new folder called "flattened" is created in the parent directory
6. All files from selected folders are moved into "flattened" folder
7. Empty source folders are deleted automatically

**Example:**
```
Before:
  MyData/
    ├── Project1/
    │   ├── src/
    │   │   └── main.py
    │   └── test/
    │       └── test.py
    └── Project2/
        ├── docs/
        │   └── README.md
        └── config/
            └── settings.json

After:
  MyData/
    └── flattened/
        ├── main.py
        ├── test.py
        ├── README.md
        └── settings.json
```

### Method 2: Flatten Into Target Directory

1. Open File Explorer
2. Select one or more folders you want to flatten
3. Right-click and drag them to your target directory
4. Release the right-click button
5. Select **"Flatten Into This Folder"** from the context menu
6. Files are extracted and moved into the target directory
7. Source folders are deleted

**Example:**
```
Before:
  Source/
    ├── Folder1/
    │   └── file1.txt
    └── Folder2/
        └── file2.txt
  Target/

After:
  Source/
    (empty - folders deleted)
  Target/
    ├── file1.txt
    └── file2.txt
```

## Duplicate File Handling

If files with the same name exist in different subdirectories, they are automatically renamed with a numeric suffix:

```
Original files:
  Folder1/document.pdf
  Folder2/document.pdf
  Folder3/document.pdf

Result:
  flattened/
    ├── document.pdf       (from Folder1)
    ├── document (1).pdf   (from Folder2)
    └── document (2).pdf   (from Folder3)
```

## Output & Feedback

Both methods display console output showing:
- Files being moved and their new names
- Empty directories being removed
- Final status (Success/Failed)
- Output directory location

The PowerShell window remains open so you can review the output. Close it manually when finished.

## Uninstallation

To remove the context menu entries:

```powershell
.\Uninstall-FlattenContextMenu.ps1
```

This will:
- Remove context menu entries from Windows Registry
- Remove installation files from `C:\Program Files\Flatten\`

To keep the scripts while removing the context menu entries:

```powershell
.\Uninstall-FlattenContextMenu.ps1 -KeepScripts
```

## Troubleshooting

### Context menu options don't appear

- **Solution**: Restart File Explorer
  1. Press `Ctrl+Shift+Esc` to open Task Manager
  2. Find "Windows Explorer"
  3. Click "Restart" button
  4. Or close and reopen File Explorer

### "Access Denied" errors during flattening

- **Possible causes**:
  - Files are in use by another program
  - Insufficient permissions for the directory
- **Solution**:
  - Close any programs using files in the selected folders
  - Ensure you have read/write permissions for the directories
  - Try running PowerShell as Administrator

### PowerShell execution policy error

- **Solution**: Adjust execution policy (see Prerequisites section)

### Files aren't being moved

- **Check**:
  - Are the directories actually selected?
  - Do the directories contain files?
  - Check the PowerShell output for specific error messages

## Advanced Usage

### Manual execution from PowerShell

If you need to run the script manually:

```powershell
# Method 1: Flatten to parent directory
& "C:\Program Files\Flatten\Flatten-Directories.ps1" -Paths "C:\Path\To\Folder1", "C:\Path\To\Folder2"

# Method 2: Flatten to specific target
& "C:\Program Files\Flatten\Flatten-Directories.ps1" -Paths "C:\Path\To\Folder1" -OutputPath "C:\Target\Directory"
```

## Safety Notes

- **Backup Important Data**: While the tool is designed to be safe, always backup important data before using
- **Test First**: Try the tool on test directories first to understand its behavior
- **Review Output**: The PowerShell window shows exactly what files are being moved and where
- **Source Folders Deleted**: Original source folders are deleted once emptied - they cannot be recovered from the tool

## Performance Notes

- Large directories with thousands of files may take several seconds
- The progress output helps you monitor the operation
- The longer the paths, the slightly longer the operation takes

## Support & Issues

For issues or feature requests, please refer to the README.md file in the repository.
