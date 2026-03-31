# OpenCode Context Menu

Add "OpenCode Here" to your Windows Explorer right-click context menu. Launch OpenCode instantly in any folder with a single click.

## Features

- Right-click any folder → "OpenCode Here"
- Right-click folder background → "OpenCode Here"
- No admin rights needed (per-user install)
- Clean uninstaller included

## Prerequisites

- Windows 10 or Windows 11
- [OpenCode](https://github.com/opencode-ai/opencode) installed and in PATH
- PowerShell (built into Windows)

## Installation

### Quick Install (Recommended)

1. Download or clone this repository
2. Double-click `install.bat`
3. Done! Right-click any folder to see "OpenCode Here"

### Manual Install

```powershell
# Run PowerShell
powershell -ExecutionPolicy Bypass -File install.ps1
```

### Terminal Options

The installer supports different terminal options:

```powershell
# Use Windows Terminal (if installed)
powershell -ExecutionPolicy Bypass -File install.ps1 -Terminal wt

# Use Command Prompt
powershell -ExecutionPolicy Bypass -File install.ps1 -Terminal cmd

# Use PowerShell (default)
powershell -ExecutionPolicy Bypass -File install.ps1 -Terminal powershell
```

## Usage

After installation:

1. Right-click any folder in Windows Explorer
2. Select **"OpenCode Here"**
3. OpenCode launches in that directory

### Windows 11 Note

On Windows 11, the context menu entry appears in **"Show more options"** (the classic menu). This is expected behavior for registry-based context menus in Windows 11.

To show "OpenCode Here" directly in the main context menu without clicking "Show more options":

```powershell
# Run as Administrator in PowerShell
reg add "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /f /ve

# Then restart Explorer
taskkill /f /im explorer.exe && start explorer
```

To revert to the default Windows 11 menu:

```powershell
# Run as Administrator in PowerShell
reg delete "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}" /f

# Then restart Explorer
taskkill /f /im explorer.exe && start explorer
```

## Uninstallation

```powershell
# Run PowerShell
powershell -ExecutionPolicy Bypass -File uninstall.ps1
```

## Troubleshooting

### "OpenCode Here" doesn't appear

1. Restart Windows Explorer (or reboot)
2. Verify OpenCode is installed: `opencode --version`
3. Check registry entries exist:
   ```powershell
   Test-Path "HKCU:\Software\Classes\Directory\shell\OpenCode"
   ```

## How It Works

The installer creates three registry entries:

- `HKCU\Software\Classes\Directory\shell\OpenCode` - For folder right-clicks
- `HKCU\Software\Classes\Directory\Background\shell\OpenCode` - For folder background right-clicks
- `HKCU\Software\Classes\Drive\shell\OpenCode` - For drive right-clicks (e.g., This PC)

Both point to the OpenCode executable with the selected directory as the working folder.

## License

MIT License - see [LICENSE](LICENSE) file
