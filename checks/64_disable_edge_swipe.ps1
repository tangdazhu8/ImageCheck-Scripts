# === 预期值 ===
# MANUAL - 人工确认边缘滑动手势 + 截图

# === 脚本配置 ===
$checkNo = 64
$checkName = "禁用边缘滑动"
$screenshotPrefix = "64"
$settingsUri = "ms-settings:devices-touch"

# Check #64: 禁用边缘滑动手势 - 展开边缘手势项截图 + 人工确认
. "$PSScriptRoot\..\common.ps1"
$ErrorActionPreference = 'Stop'

$screenshotDir = Join-Path $PSScriptRoot "..\screenshots"
if (-not (Test-Path $screenshotDir)) { 
    New-Item -ItemType Directory -Path $screenshotDir -Force | Out-Null 
}

$win32Sig = @'
[DllImport("user32.dll")]
public static extern bool SetForegroundWindow(IntPtr hWnd);
[DllImport("user32.dll")]
public static extern IntPtr FindWindow(string lpClassName, string lpWindowName);
[DllImport("user32.dll")]
public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
[DllImport("user32.dll")]
public static extern bool SetProcessDPIAware();
'@
try { Add-Type -MemberDefinition $win32Sig -Name "Win32" -Namespace "Native" } catch {}

try {
    try { [Native.Win32]::SetProcessDPIAware() | Out-Null } catch {}

    Get-Process -Name "SystemSettings" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 1

    Start-Process $settingsUri
    Start-Sleep -Seconds 3

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $hwnd = [Native.Win32]::FindWindow("ApplicationFrameWindow", "设置")
    if (-not $hwnd) {
        $hwnd = [Native.Win32]::FindWindow("ApplicationFrameWindow", $null)
    }
    if ($hwnd) {
        [Native.Win32]::ShowWindow($hwnd, 9) | Out-Null
        Start-Sleep -Milliseconds 300
        [Native.Win32]::SetForegroundWindow($hwnd) | Out-Null
        Start-Sleep -Milliseconds 500
    }

    # 先展开「显示更多设置」（若有），再按名称展开「边缘手势」。不用 Tab/Enter（会误拨旁边的开关）
    [void](Expand-SettingsExpander -NameHints @('显示更多设置', 'Show more settings') -TimeoutMs 2500)
    $expanded = Expand-SettingsExpander -NameHints @(
        '边缘手势',
        '触摸边缘手势',
        '边缘滑动',
        'Touch edge gestures',
        'Edge gestures'
    )
    if ($expanded) {
        Start-Sleep -Milliseconds 800
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

    Get-Process -Name "SystemSettings" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

    $status = "MANUAL"
    if ($expanded) {
        $currentStr = "已按名称展开边缘手势 | Saved: $outputPath"
    } else {
        $currentStr = "未找到可展开的边缘手势项（未使用 Tab/Enter） | Saved: $outputPath"
    }
    $expectedStr = "人工确认：左边缘、右边缘、下边缘向内滑动不呼出小组件、通知、开始菜单"
} catch {
    $status = "FAIL"
    $currentStr = "ERROR: $($_.Exception.Message)"
    $expectedStr = "Manual check"
}
Write-CheckResult -No $checkNo -Name $checkName -Status $status -Current $currentStr -Expected $expectedStr