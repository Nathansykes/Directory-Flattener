# Troubleshooting Guide

## Common Issues and Solutions

### 1. Console Window Closes Too Quickly

**Problem:** When running scripts from the context menu, the PowerShell window closes before you can see error messages.

**Solution:** 
- All error messages now include a "Press any key to exit..." prompt
- The window will stay open until you press a key
- This gives you time to read any error messages

### 2. "This script requires Administrator privileges!"

**Problem:** Installation or uninstallation fails with admin error.

**Solution:**
1. Close PowerShell
2. **Right-click** on PowerShell and select "Run as administrator"
3. Navigate to the script location: `cd C:\Users\Nathan\source\repos\Flatten`
4. Run: `.\Install-FlattenContextMenu.ps1`

**For context menu operations:** The flattening script is called from the context menu with admin rights automatically (through Windows Registry), but the initial installation script must be run manually as admin.

### 3. No Logs Being Generated

**Problem:** No log files appear in `C:\ProgramData\Flatten\logs\`

**Causes & Solutions:**

1. **Log directory doesn't exist:**
   ```powershell
   New-Item -ItemType Directory -Path "C:\ProgramData\Flatten\logs" -Force
   ```

2. **Permission issue with C:\ProgramData:**
   - Ensure you have read/write permissions
   - Run scripts as Administrator

3. **Log directory permissions:**
   - Right-click `C:\ProgramData\Flatten`
   - Properties → Security → Edit
   - Select your user and ensure "Modify" is checked

### 4. Context Menu Options Don't Appear

**Problem:** "Flatten Directories" options don't show in File Explorer context menu.

**Solutions:**

1. **Restart File Explorer:**
   - Press `Ctrl+Shift+Esc` (Task Manager)
   - Find "Windows Explorer"
   - Click "Restart"

2. **Re-run the install script:**
   ```powershell
   # As Administrator
   cd C:\Users\Nathan\source\repos\Flatten
   .\Install-FlattenContextMenu.ps1
   ```

3. **Check registry entries:**
   ```powershell
   # Open Registry Editor (regedit.exe)
   # Navigate to: HKEY_CURRENT_USER\Software\Classes\Directory\shell
   # Should see: FlattenDirectories and FlattenInto folders
   ```

### 5. "Access Denied" During Flattening

**Problem:** Files can't be moved or directories can't be deleted.

**Causes & Solutions:**

1. **Files are in use:**
   - Close any programs using files in those folders
   - Including File Explorer previews
   - Wait a moment and try again

2. **Insufficient permissions:**
   - Ensure you own or have write access to directories
   - Right-click folder → Properties → Security → Edit
   - Grant yourself Full Control if needed

3. **System or hidden files:**
   - The script skips system files
   - Exclude protected directories from flattening

### 6. Duplicate File Naming Issue

**Problem:** Files not renamed correctly when duplicates are found.

**Expected Behavior:**
- First file: `document.txt`
- Second duplicate: `document (1).txt`
- Third duplicate: `document (2).txt`

If this isn't happening:
- Check the log file for error messages
- Ensure target directory is writable
- Try with fewer files first to test

### 7. Empty Directories Not Being Deleted

**Problem:** Some empty subdirectories remain after flattening.

**Possible Causes:**
- Hidden or system files in the directory (scripts skip these)
- Very deep nesting (scripts use recursive cleanup)

**Solution:**
- The "flattened" folder itself is kept and not deleted
- Only empty source directories are removed
- Manually delete any remaining empty folders with File Manager

## Log Files

### Location
```
C:\ProgramData\Flatten\logs\
```

### File Names
- `Flatten_<yyyyMMdd_HHmmss>.log` - Flattening operations
- `Install_<yyyyMMdd_HHmmss>.log` - Installation
- `Uninstall_<yyyyMMdd_HHmmss>.log` - Uninstallation

### Viewing Logs
```powershell
# View recent install log
Get-ChildItem "C:\ProgramData\Flatten\logs\Install_*.log" | 
  Sort-Object -Property LastWriteTime -Descending | 
  Select-Object -First 1 | 
  Get-Content

# View recent flatten log
Get-ChildItem "C:\ProgramData\Flatten\logs\Flatten_*.log" | 
  Sort-Object -Property LastWriteTime -Descending | 
  Select-Object -First 1 | 
  Get-Content
```

### Log Levels
| Level | Meaning |
|-------|---------|
| `OPERATION` | Major operation start/end markers |
| `SUCCESS` | Successful operations |
| `INFO` | Informational messages |
| `WARNING` | Warning conditions |
| `ERROR` | Error conditions |
| `DEBUG` | Detailed diagnostic information |

## Running Scripts Manually

### Flatten directories (Method 1)
```powershell
# From repository directory
& "C:\Program Files\Flatten\Flatten-Directories.ps1" -Paths "C:\Path\To\Folder1", "C:\Path\To\Folder2"
```

### Flatten to target (Method 2)
```powershell
& "C:\Program Files\Flatten\Flatten-Directories.ps1" -Paths "C:\Path\To\Folder1" -OutputPath "C:\Target\Directory"
```

## Uninstalling

### Full uninstall (removes scripts)
```powershell
# Run as Administrator
cd C:\Users\Nathan\source\repos\Flatten
.\Uninstall-FlattenContextMenu.ps1
```

### Keep scripts, remove only context menu
```powershell
# Run as Administrator
cd C:\Users\Nathan\source\repos\Flatten
.\Uninstall-FlattenContextMenu.ps1 -KeepScripts
```

## Getting Help

1. **Check the log file** - Most issues are logged with details
2. **Review this guide** - Common solutions are listed above
3. **Verify permissions** - Ensure you're running as admin when needed
4. **Check log directory** - Confirm `C:\ProgramData\Flatten\logs\` exists and is writable

## Still Having Issues?

1. Note the exact error message
2. Check the log file at `C:\ProgramData\Flatten\logs\`
3. Note the timestamp of when you ran the operation
4. Include the relevant log entries when reporting issues
