# === 预期值 ===
$expectedEnableLUA = 0

# === 脚本配置 ===
$checkNo = 6
$checkName = "UAC"

# Check 6: UAC — EnableLUA=0 为 MANUAL，非 0 为 FAIL；随后截图
. "$PSScriptRoot\..\common.ps1"
$ErrorActionPreference = 'Stop'

$screenshotDir = Join-Path $PSScriptRoot "..\screenshots"
if (-not (Test-Path $screenshotDir)) { 
    New-Item -ItemType Directory -Path $screenshotDir -Force | Out-Null 
}

function Get-UacSettingsProcess {
    Get-Process -Name dllhost -ErrorAction SilentlyContinue |
        Where-Object { $_.MainWindowTitle -match 'User Account Control Settings|用户账户控制设置' } |
        Select-Object -First 1
}

$uacHost = $null
try {
    $path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
    $enableLUA = Get-RegistryValue -Path $path -Name "EnableLUA"
    $consentPrompt = Get-RegistryValue -Path $path -Name "ConsentPromptBehaviorAdmin"
    $promptSecure = Get-RegistryValue -Path $path -Name "PromptOnSecureDesktop"

    $currentStr = "EnableLUA=$enableLUA, ConsentPromptBehaviorAdmin=$consentPrompt, PromptOnSecureDesktop=$promptSecure"
    $expectedStr = "EnableLUA=0 时人工看截图确认；EnableLUA 非 0 为 FAIL"

    $luaOff = $false
    try { $luaOff = ([int]$enableLUA -eq $expectedEnableLUA) } catch { $luaOff = $false }
    if ($luaOff) { $status = "MANUAL" } else { $status = "FAIL" }

    try { $null = [Native.Win32]::SetProcessDPIAware() } catch {}
    Start-Process "$env:SystemRoot\System32\UserAccountControlSettings.exe"

    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    do {
        Start-Sleep -Milliseconds 250
        $uacHost = Get-UacSettingsProcess
    } while (-not $uacHost -and $sw.ElapsedMilliseconds -lt 8000)

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $hwnd = [IntPtr]::Zero
    if ($uacHost) { $hwnd = [IntPtr]$uacHost.MainWindowHandle }
    if ($hwnd.ToInt64() -ne 0) {
        $null = [Native.Win32]::ShowWindow($hwnd, 9)
        Start-Sleep -Milliseconds 300
        $null = [Native.Win32]::SetForegroundWindow($hwnd)
        Start-Sleep -Milliseconds 500
    }

    $monitorSize = [System.Windows.Forms.SystemInformation]::PrimaryMonitorSize
    $w = $monitorSize.Width
    $h = $monitorSize.Height
    $bitmap = New-Object System.Drawing.Bitmap($w, $h)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.CopyFromScreen(0, 0, 0, 0, $bitmap.Size)

    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $outputPath = Join-Path $screenshotDir "06_$timestamp.png"
    $bitmap.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)

    $graphics.Dispose()
    $bitmap.Dispose()

    $currentStr += " | Screenshot: $outputPath"
} catch {
    $status = "FAIL"
    $currentStr = "ERROR: $($_.Exception.Message)"
    $expectedStr = "UAC disabled: EnableLUA=$expectedEnableLUA"
} finally {
    # 窗口宿主是带标题的那一个 dllhost，只关该窗口，不按进程名杀全部 dllhost
    if ($uacHost) {
        $uacHost.Refresh()
        if (-not $uacHost.HasExited -and $uacHost.MainWindowTitle -match 'User Account Control Settings|用户账户控制设置') {
            [void]$uacHost.CloseMainWindow()
            Start-Sleep -Milliseconds 400
            $uacHost.Refresh()
            $hwndClose = [IntPtr]$uacHost.MainWindowHandle
            if ($hwndClose.ToInt64() -ne 0 -and $uacHost.MainWindowTitle -match 'User Account Control Settings|用户账户控制设置') {
                [void][Native.Win32]::SendMessage($hwndClose, [uint32]0x0010, [IntPtr]::Zero, [IntPtr]::Zero)
                [void][Native.Win32]::EndTask($hwndClose, $false, $true)
            }
        }
    }
}

Write-CheckResult -No $checkNo -Name $checkName -Status $status -Current $currentStr -Expected $expectedStr
