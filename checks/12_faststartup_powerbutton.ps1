# === 预期值 ===
# MANUAL - 截图检查，需人工确认

# === 脚本配置 ===
$checkNo = 12
$checkName = "快速启动功能"
$screenshotPrefix = "12"
$controlPanelArgs = "/name Microsoft.PowerOptions /page pageGlobalSettings"
$shellNamePattern = '系统设置|System Settings|电源选项|Power Options'

# Check 12: 快速启动功能 - Screenshot
. "$PSScriptRoot\..\common.ps1"
$ErrorActionPreference = 'Stop'

# 该页由 explorer 托管，Shell.Application 能拿到 HWND 并 Quit()，无需额外 P/Invoke。
# 不要用 if ($hwnd) 判断 Native.Win32.FindWindow 的返回值：[IntPtr]::Zero 在 PowerShell 里仍为 true。
function Get-PowerCplWindows {
    try {
        $shell = New-Object -ComObject Shell.Application
        foreach ($window in @($shell.Windows())) {
            try {
                if ($window.LocationName -match $script:shellNamePattern) { $window }
            } catch {}
        }
    } catch {}
}

function Wait-PowerCplWindow {
    param([int]$TimeoutMs = 8000)
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    do {
        $window = @(Get-PowerCplWindows) | Select-Object -First 1
        if ($window) { return $window }
        Start-Sleep -Milliseconds 250
    } while ($sw.ElapsedMilliseconds -lt $TimeoutMs)
    return $null
}

$screenshotDir = Join-Path $PSScriptRoot "..\screenshots"
if (-not (Test-Path $screenshotDir)) {
    New-Item -ItemType Directory -Path $screenshotDir -Force | Out-Null
}

try {
    try { $null = [Native.Win32]::SetProcessDPIAware() } catch {}

    Start-Process "control" -ArgumentList $controlPanelArgs

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $window = Wait-PowerCplWindow
    if ($window) {
        $hwnd = [IntPtr]$window.HWND
        if ($hwnd.ToInt64() -ne 0) {
            [void][Native.Win32]::ShowWindow($hwnd, 9)
            Start-Sleep -Milliseconds 500
            [void][Native.Win32]::SetForegroundWindow($hwnd)
            Start-Sleep -Milliseconds 500
        }
    }

    $screen = [System.Windows.Forms.Screen]::PrimaryScreen
    $bitmap = New-Object System.Drawing.Bitmap($screen.Bounds.Width, $screen.Bounds.Height)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.CopyFromScreen($screen.Bounds.Left, $screen.Bounds.Top, 0, 0, $bitmap.Size)

    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $outputPath = Join-Path $screenshotDir "${screenshotPrefix}_$timestamp.png"
    $bitmap.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)

    $graphics.Dispose()
    $bitmap.Dispose()

    $status = "MANUAL"
    $currentStr = "Saved: $outputPath"
    $expectedStr = "Manual check"
} catch {
    $status = "FAIL"
    $currentStr = "ERROR: $($_.Exception.Message)"
    $expectedStr = "Screenshot failed"
} finally {
    foreach ($window in @(Get-PowerCplWindows)) {
        try { $window.Quit() } catch {}
    }
}

Write-CheckResult -No $checkNo -Name $checkName -Status $status -Current $currentStr -Expected $expectedStr
