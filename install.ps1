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

function Rollback {
    Write-Log "Performing rollback..."
    Remove-Item -Path "HKCU:\Software\Classes\Directory\shell\OpenCode" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "HKCU:\Software\Classes\Directory\Background\shell\OpenCode" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Log "Rollback complete"
}

try {
    Write-Log "=== OpenCode Context Menu Installer ==="
    Write-Log "Terminal mode: $Terminal"
    
    # Detect OpenCode path
    $openCodePath = (Get-Command opencode -ErrorAction SilentlyContinue).Source
    
    if (-not $openCodePath) {
        $possiblePaths = @(
            "$env:APPDATA\npm\opencode.cmd",
            "$env:LOCALAPPDATA\npm\opencode.cmd",
            "$env:USERPROFILE\AppData\Roaming\npm\opencode.cmd",
            "$env:USERPROFILE\opencode.bat",
            "$env:USERPROFILE\AppData\Roaming\npm\opencode.ps1"
        )
        foreach ($path in $possiblePaths) {
            if (Test-Path $path) {
                $openCodePath = $path
                break
            }
        }
    }
    
    if (-not $openCodePath) {
        throw "OpenCode not found. Please install OpenCode first."
    }
    
    if (-not ($openCodePath -match '\.(cmd|bat|ps1)$')) {
        if (Test-Path "$openCodePath.cmd") { $openCodePath = "$openCodePath.cmd" }
        elseif (Test-Path "$openCodePath.ps1") { $openCodePath = "$openCodePath.ps1" }
    }
    
    Write-Log "Using OpenCode path: $openCodePath"
    
    # Build command injecting the EXACT path and safely escaping %V
    switch ($Terminal) {
        'wt' {
            if (Get-Command wt -ErrorAction SilentlyContinue) {
                $command = "wt.exe new-tab -d `"%V`" `"$openCodePath`""
            } else {
                $command = "powershell.exe -NoExit -Command `"Set-Location -LiteralPath \`"%V\`"; & \`"$openCodePath\`"`""
            }
        }
        'cmd' {
            $command = "cmd.exe /c start cmd /k `"cd /d \`"%V\`" && \`"$openCodePath\`"`""
        }
        'powershell' {
            $command = "powershell.exe -NoExit -Command `"Set-Location -LiteralPath \`"%V\`"; & \`"$openCodePath\`"`""
        }
    }
    
    Write-Log "Command template: $command"
    
    # Create folder context menu
    $folderKey = "HKCU:\Software\Classes\Directory\shell\OpenCode"
    if (Test-Path $folderKey) { Remove-Item -Path $folderKey -Recurse -Force }
    
    New-Item -Path $folderKey -Force -ErrorAction Stop | Out-Null
    Set-ItemProperty -Path $folderKey -Name "(Default)" -Value "OpenCode Here" -ErrorAction Stop
    Set-ItemProperty -Path $folderKey -Name "Icon" -Value "powershell.exe,0" -ErrorAction Stop
    
    $folderCommand = "$folderKey\command"
    New-Item -Path $folderCommand -Force -ErrorAction Stop | Out-Null
    Set-ItemProperty -Path $folderCommand -Name "(Default)" -Value $command -ErrorAction Stop
    
    # Create background context menu
    $bgKey = "HKCU:\Software\Classes\Directory\Background\shell\OpenCode"
    if (Test-Path $bgKey) { Remove-Item -Path $bgKey -Recurse -Force }
    
    New-Item -Path $bgKey -Force -ErrorAction Stop | Out-Null
    Set-ItemProperty -Path $bgKey -Name "(Default)" -Value "OpenCode Here" -ErrorAction Stop
    Set-ItemProperty -Path $bgKey -Name "Icon" -Value "powershell.exe,0" -ErrorAction Stop
    
    $bgCommand = "$bgKey\command"
    New-Item -Path $bgCommand -Force -ErrorAction Stop | Out-Null
    Set-ItemProperty -Path $bgCommand -Name "(Default)" -Value $command -ErrorAction Stop
    
    Write-Log "[OK] Installation completed successfully!"
    Write-Host "Right-click any folder or folder background to see 'OpenCode Here'"
    Write-Host "To uninstall, run: .\uninstall.ps1"
    exit 0
}
catch {
    Write-Log "ERROR: $_"
    Rollback
    exit 1
}
