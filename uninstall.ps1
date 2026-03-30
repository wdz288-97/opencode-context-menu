#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Uninstalls "OpenCode Here" context menu from Windows Explorer

.DESCRIPTION
    Removes the right-click context menu entries created by install.ps1

.EXAMPLE
    .\uninstall.ps1
    Removes all OpenCode context menu entries
#>

[CmdletBinding()]
param()

# Setup logging
$LogFile = "$env:TEMP\OpenCodeUninstaller_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    "$timestamp - $Message" | Add-Content -Path $LogFile -Encoding UTF8
    Write-Host $Message
}

try {
    Write-Log "=== OpenCode Context Menu Uninstaller ==="
    Write-Log "Log file: $LogFile"
    Write-Log ""
    
    $found = $false
    
    # Remove folder context menu
    Write-Log "Removing folder context menu entry..."
    $folderKey = "HKCU:\Software\Classes\Directory\shell\OpenCode"
    
    if (Test-Path $folderKey) {
        Remove-Item -Path $folderKey -Recurse -Force -ErrorAction Stop
        Write-Log "  [OK] Folder context menu removed"
        $found = $true
    } else {
        Write-Log "  (Folder context menu not found - already clean)"
    }
    
    # Remove background context menu
    Write-Log "Removing background context menu entry..."
    $bgKey = "HKCU:\Software\Classes\Directory\Background\shell\OpenCode"
    
    if (Test-Path $bgKey) {
        Remove-Item -Path $bgKey -Recurse -Force -ErrorAction Stop
        Write-Log "  [OK] Background context menu removed"
        $found = $true
    } else {
        Write-Log "  (Background context menu not found - already clean)"
    }
    
    Write-Log ""
    
    if ($found) {
        Write-Log "[OK] Uninstall completed successfully!"
        Write-Log ""
        Write-Log "Note: You may need to restart Windows Explorer or reboot for changes to take effect"
    } else {
        Write-Log "No OpenCode context menu entries found."
        Write-Log "It may have already been uninstalled, or was never installed."
    }
    
    Write-Log ""
    Write-Log "Log saved to: $LogFile"
    exit 0
}
catch {
    Write-Log "ERROR: $_"
    Write-Log ""
    Write-Log "Uninstall failed. See log: $LogFile"
    exit 1
}
