<#
.SYNOPSIS
    Installs "OpenCode Here" context menu for Windows Explorer
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

# Check if running as Admin to prevent the HKCU trap
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
$registryRoot = "HKCU:"

if ($isAdmin) {
    Write-Log "WARNING: Running as Administrator. Installing for ALL users (HKLM) instead of current user to prevent registry mismatch."
    $registryRoot = "HKLM:"
}

function Rollback {
    Write-Log "Performing rollback..."
    Remove-Item -Path "$registryRoot\Software\Classes\Directory\shell\OpenCode" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "$registryRoot\Software\Classes\Directory\Background\shell\OpenCode" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Log "Rollback complete"
}

try {
    Write-Log "=== OpenCode Context Menu Installer ==="
    Write-Log "Terminal mode: $Terminal"
    Write-Log "Registry root: $registryRoot"
    
    # Base detection of OpenCode
    $basePath = (Get-Command opencode -ErrorAction SilentlyContinue).Source
    
    if (-not $basePath) {
        $possiblePaths = @(
            "$env:APPDATA\npm\opencode.cmd",
            "$env:LOCALAPPDATA\npm\opencode.cmd",
            "$env:USERPROFILE\AppData\Roaming\npm\opencode.cmd",
            "$env:USERPROFILE\opencode.bat"
        )
        foreach ($path in $possiblePaths) {
            if (Test-Path $path) {
                $basePath = $path
                break
            }
        }
    }
    
    if (-not $basePath) {
        throw "OpenCode not found. Please install OpenCode first."
    }

    # Strip extension to get the raw path
    $openCodeRawPath = $basePath -replace '\.(cmd|bat|ps1)$', ''
    
    # Resolve the EXACT extension needed for the chosen terminal
    $openCodePath = ""
    if ($Terminal -eq 'cmd') {
        if (Test-Path "$openCodeRawPath.cmd") { $openCodePath = "$openCodeRawPath.cmd" }
        elseif (Test-Path "$openCodeRawPath.bat") { $openCodePath = "$openCodeRawPath.bat" }
        else { throw "Could not find .cmd or .bat version of OpenCode required for Command Prompt." }
    } else {
        # PowerShell and Windows Terminal (which defaults to PS) prefer .ps1, fallback to .cmd
        if (Test-Path "$openCodeRawPath.ps1") { $openCodePath = "$openCodeRawPath.ps1" }
        elseif (Test-Path "$openCodeRawPath.cmd") { $openCodePath = "$openCodeRawPath.cmd" }
        else { throw "Could not find executable version of OpenCode." }
    }
    
    Write-Log "Using OpenCode executable: $openCodePath"
    
    # Build command injecting the EXACT path and safely escaping %V
    # We use arguments for PowerShell to avoid the trailing backslash bug (e.g. C:\")
    switch ($Terminal) {
        'wt' {
            if (Get-Command wt -ErrorAction SilentlyContinue) {
                $command = 'wt.exe new-tab -d "%V" "' + $openCodePath + '"'
            } else {
                Write-Log "WARNING: Windows Terminal not found, falling back to PowerShell"
                $command = 'powershell.exe -NoExit -WindowStyle Hidden -Command "& { Set-Location -LiteralPath $args[0]; & $args[1] }" "%V" "' + $openCodePath + '"'
            }
        }
        'cmd' {
            # CMD requires standard quotes, no backslash escaping
            $command = 'cmd.exe /k "cd /d "%V" && "' + $openCodePath + '""'
        }
        'powershell' {
            # PowerShell with argument passing to handle C:\ trailing slash cleanly
            $command = 'powershell.exe -NoExit -WindowStyle Hidden -Command "& { Set-Location -LiteralPath $args[0]; & $args[1] }" "%V" "' + $openCodePath + '"'
        }
    }
    
    Write-Log "Command template: $command"
    
    # Create folder context menu
    $folderKey = "$registryRoot\Software\Classes\Directory\shell\OpenCode"
    if (Test-Path $folderKey) { Remove-Item -Path $folderKey -Recurse -Force }
    
    New-Item -Path $folderKey -Force -ErrorAction Stop | Out-Null
    Set-ItemProperty -Path $folderKey -Name "(Default)" -Value "OpenCode Here" -ErrorAction Stop
    Set-ItemProperty -Path $folderKey -Name "Icon" -Value "powershell.exe,0" -ErrorAction Stop
    
    $folderCommand = "$folderKey\command"
    New-Item -Path $folderCommand -Force -ErrorAction Stop | Out-Null
    Set-ItemProperty -Path $folderCommand -Name "(Default)" -Value $command -ErrorAction Stop
    
    # Create background context menu
    $bgKey = "$registryRoot\Software\Classes\Directory\Background\shell\OpenCode"
    if (Test-Path $bgKey) { Remove-Item -Path $bgKey -Recurse -Force }
    
    New-Item -Path $bgKey -Force -ErrorAction Stop | Out-Null
    Set-ItemProperty -Path $bgKey -Name "(Default)" -Value "OpenCode Here" -ErrorAction Stop
    Set-ItemProperty -Path $bgKey -Name "Icon" -Value "powershell.exe,0" -ErrorAction Stop
    
    $bgCommand = "$bgKey\command"
    New-Item -Path $bgCommand -Force -ErrorAction Stop | Out-Null
    Set-ItemProperty -Path $bgCommand -Name "(Default)" -Value $command -ErrorAction Stop
    
    Write-Log "[OK] Installation completed successfully!"
    Write-Host "`nInstallation successful!" -ForegroundColor Green
    Write-Host "Right-click any folder or folder background to see 'OpenCode Here'"
    Write-Host "To uninstall, run: .\uninstall.ps1"
    exit 0
}
catch {
    Write-Log "ERROR: $_"
    Write-Host "`nInstallation failed: $_" -ForegroundColor Red
    Rollback
    exit 1
}
