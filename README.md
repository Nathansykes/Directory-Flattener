# Flatten - Windows Directory Flattening Tool

A Windows context menu utility to flatten nested directory structures into a single directory.

## Features

- **Method 1**: Right-click context menu to flatten selected folders
- **Method 2**: Right-click drag to flatten folders into a target location
- Recursive file extraction from all subdirectories
- Automatic duplicate filename handling (appends counter: file (1).txt, file (2).txt, etc)
- Removes empty directories after flattening
- Output directory created in parent folder of selected items

## Installation

Run the installation script with administrator privileges:

```powershell
.\Install-FlattenContextMenu.ps1
```

This will:
- Copy scripts to `%ProgramFiles%\Flatten\`
- Register context menu entries in Windows Registry
- Create shell extensions for both right-click and drag-drop methods

## Uninstallation

To remove the context menu entries:

```powershell
.\Uninstall-FlattenContextMenu.ps1
```

## Usage

### Method 1: Right-Click Context Menu
1. Select one or more folders in Windows File Explorer
2. Right-click and select "Flatten Directories"
3. A "flattened" folder is created in the parent directory containing all extracted files
4. Original folders are deleted once emptied

### Method 2: Right-Click Drag
1. Select one or more folders in Windows File Explorer
2. Right-click and drag to your target folder
3. Select "Flatten Here" from the context menu
4. Files are flattened into the target folder
5. Original folders are deleted once emptied

## File Naming

When duplicate filenames are encountered, they are automatically renamed:
- `file.txt` (original)
- `file (1).txt` (first duplicate)
- `file (2).txt` (second duplicate)
- etc.

## Requirements

- Windows 10 or later
- PowerShell 5.0 or later
- Administrator privileges for installation only

## Technical Details

- Scripts are stored in: `%ProgramFiles%\Flatten\`
- Registry keys: `HKEY_CLASSES_ROOT\Directory\shell\FlattenDirectories`
- Method 2 uses drag-drop registry entries for context menu extension
