# === 预期值 ===
# MANUAL - 截图检查，需人工确认设备管理器中有无黄色感叹号

# === 脚本配置 ===
$checkNo = 65
$checkName = "设备管理器黄标"
$screenshotPrefix = "65"

# Check 65: 设备管理器 - 打开、展开、截图、关闭
. "$PSScriptRoot\..\common.ps1"
$ErrorActionPreference = 'Stop'

$screenshotDir = Join-Path $PSScriptRoot "..\screenshots"
if (-not (Test-Path $screenshotDir)) {
    New-Item -ItemType Directory -Path $screenshotDir -Force | Out-Null
}

$proc = $null
try {
    try { $null = [Native.Win32]::SetProcessDPIAware() } catch {}

    $proc = Start-Process "mmc.exe" -ArgumentList "$env:SystemRoot\system32\devmgmt.msc" -PassThru

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $hwnd = [IntPtr]::Zero
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    do {
        Start-Sleep -Milliseconds 250
        if ($proc.HasExited) { break }
        $proc.Refresh()
        $hwnd = [IntPtr]$proc.MainWindowHandle
    } while ($sw.ElapsedMilliseconds -lt 8000 -and $hwnd.ToInt64() -eq 0)

    if ($hwnd.ToInt64() -ne 0) {
        [void][Native.Win32]::ShowWindow($hwnd, 3)  # SW_SHOWMAXIMIZED
        Start-Sleep -Milliseconds 300
        [void][Native.Win32]::SetForegroundWindow($hwnd)
        Start-Sleep -Milliseconds 400
        # 选中计算机节点并展开全部，便于查看 yellow mark
        [System.Windows.Forms.SendKeys]::SendWait("{HOME}")
        Start-Sleep -Milliseconds 200
        [System.Windows.Forms.SendKeys]::SendWait("{MULTIPLY}")
        Start-Sleep -Milliseconds 600
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
    $expectedStr = "人工确认：设备管理器中无黄色感叹号（yellow mark）"
} catch {
    $status = "FAIL"
    $currentStr = "ERROR: $($_.Exception.Message)"
    $expectedStr = "Screenshot failed"
} finally {
    if ($proc -and -not $proc.HasExited) {
        [void]$proc.CloseMainWindow()
        if (-not $proc.WaitForExit(3000)) {
            Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
        }
    }
}

Write-CheckResult -No $checkNo -Name $checkName -Status $status -Current $currentStr -Expected $expectedStr