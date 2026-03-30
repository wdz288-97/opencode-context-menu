#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Installs "OpenCode Here" context menu for Windows Explorer

.DESCRIPTION
    Adds a right-click context menu entry to:
    - Folders (right-click on folder)
    - Directory background (right-click on empty space in folder)
    
    Allows launching OpenCode directly in the selected directory.

.PARAMETER Terminal
    Specifies which terminal to use. Options: 'cmd', 'powershell', 'wt' (Windows Terminal)
    Default: 'powershell'

.EXAMPLE
    .\install.ps1
    Installs with default PowerShell terminal

.EXAMPLE
    .\install.ps1 -Terminal wt
    Installs with Windows Terminal (recommended if installed)
#>

[CmdletBinding()]
param(
    [ValidateSet('cmd', 'powershell', 'wt')]
    [string]$Terminal = 'powershell'
)

# Setup logging
$LogFile = "$env:TEMP\OpenCodeInstaller_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    "$timestamp - $Message" | Add-Content -Path $LogFile -Encoding UTF8
    Write-Host $Message
}

function Rollback {
    Write-Log "Performing rollback..."
    Remove-Item -Path "HKCU:\Software\Classes\Directory\shell\OpenCode" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "HKCU:\Software\Classes\Directory\Background\shell\OpenCode" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Log "Rollback complete"
}

try {
    Write-Log "=== OpenCode Context Menu Installer ==="
    Write-Log "Terminal mode: $Terminal"
    Write-Log "Log file: $LogFile"
    Write-Log ""
    
    # Detect OpenCode path
    Write-Log "Detecting OpenCode installation..."
    $openCodePath = (Get-Command opencode -ErrorAction SilentlyContinue).Source
    
    if (-not $openCodePath) {
        # Try common locations
        $possiblePaths = @(
            "$env:APPDATA\npm\opencode.cmd",
            "$env:LOCALAPPDATA\npm\opencode.cmd",
            "$env:USERPROFILE\AppData\Roaming\npm\opencode.cmd",
            "$env:USERPROFILE\opencode.bat"
        )
        
        foreach ($path in $possiblePaths) {
            if (Test-Path $path) {
                $openCodePath = $path
                Write-Log "Found OpenCode at: $openCodePath"
                break
            }
        }
    } else {
        Write-Log "Found OpenCode at: $openCodePath"
    }
    
    if (-not $openCodePath) {
        throw "OpenCode not found in PATH. Please install OpenCode first: https://github.com/opencode-ai/opencode"
    }
    
    # Ensure we have the .cmd or .bat extension for proper execution
    if (-not ($openCodePath -match '\.(cmd|bat|ps1)$')) {
        # If it's the shim without extension, look for .cmd version
        $cmdPath = "$openCodePath.cmd"
        if (Test-Path $cmdPath) {
            $openCodePath = $cmdPath
        }
    }
    
    Write-Log "Using OpenCode path: $openCodePath"
    Write-Log ""
    
    # Build command based on terminal choice
    switch ($Terminal) {
        'wt' {
            # Windows Terminal - best experience
            if (Get-Command wt -ErrorAction SilentlyContinue) {
                $command = "wt.exe new-tab -d `"`"%V`"`" opencode"
            } else {
                Write-Log "WARNING: Windows Terminal not found, falling back to PowerShell"
                $command = "powershell.exe -NoExit -Command `"Set-Location '\"%V\"'; opencode`""
            }
        }
        'cmd' {
            # Classic Command Prompt
            $command = "cmd.exe /c start cmd /k `""cd /d `"%V`" && opencode`"""
        }
        'powershell' {
            # PowerShell
            $command = "powershell.exe -NoExit -Command `"Set-Location '\"%V\"'; opencode`""
        }
    }
    
    Write-Log "Command template: $command"
    Write-Log ""
    
    # Create registry entries for folder context menu
    Write-Log "Creating folder context menu entry..."
    $folderKey = "HKCU:\Software\Classes\Directory\shell\OpenCode"
    
    if (Test-Path $folderKey) {
        Write-Log "  Folder key already exists, updating..."
        Remove-Item -Path $folderKey -Recurse -Force
    }
    
    New-Item -Path $folderKey -Force -ErrorAction Stop | Out-Null
    Set-ItemProperty -Path $folderKey -Name "(Default)" -Value "OpenCode Here" -ErrorAction Stop
    Set-ItemProperty -Path $folderKey -Name "Icon" -Value "`"$openCodePath`",0" -ErrorAction Stop
    
    $folderCommand = "$folderKey\command"
    New-Item -Path $folderCommand -Force -ErrorAction Stop | Out-Null
    Set-ItemProperty -Path $folderCommand -Name "(Default)" -Value $command -ErrorAction Stop
    
    Write-Log "  Folder context menu created successfully"
    
    # Create registry entries for background context menu
    Write-Log "Creating background context menu entry..."
    $bgKey = "HKCU:\Software\Classes\Directory\Background\shell\OpenCode"
    
    if (Test-Path $bgKey) {
        Write-Log "  Background key already exists, updating..."
        Remove-Item -Path $bgKey -Recurse -Force
    }
    
    New-Item -Path $bgKey -Force -ErrorAction Stop | Out-Null
    Set-ItemProperty -Path $bgKey -Name "(Default)" -Value "OpenCode Here" -ErrorAction Stop
    Set-ItemProperty -Path $bgKey -Name "Icon" -Value "`"$openCodePath`",0" -ErrorAction Stop
    
    $bgCommand = "$bgKey\command"
    New-Item -Path $bgCommand -Force -ErrorAction Stop | Out-Null
    Set-ItemProperty -Path $bgCommand -Name "(Default)" -Value $command -ErrorAction Stop
    
    Write-Log "  Background context menu created successfully"
    Write-Log ""
    
    # Verify installation
    Write-Log "Verifying installation..."
    $folderExists = Test-Path $folderKey
    $bgExists = Test-Path $bgKey
    
    if ($folderExists -and $bgExists) {
        Write-Log "✓ Installation completed successfully!"
        Write-Log ""
        Write-Log "Right-click any folder or folder background to see 'OpenCode Here'"
        Write-Log "Note: You may need to restart Windows Explorer or reboot for changes to take effect"
        Write-Log ""
        Write-Log "To uninstall, run: .\uninstall.ps1"
        exit 0
    } else {
        throw "Installation verification failed"
    }
}
catch {
    Write-Log "ERROR: $_"
    Write-Log ""
    Write-Log "Installation failed. See log: $LogFile"
    Rollback
    exit 1
}
