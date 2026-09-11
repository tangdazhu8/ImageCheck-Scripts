# === 预期值 ===
# MANUAL - 截图检查，需人工确认

# === 脚本配置 ===
$checkNo = 7
$checkName = "Miracast"
$screenshotPrefix = "07"
$settingsUri = "ms-settings:project"

# Check 7: 投影到此电脑 - Screenshot
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

    $hwnd = [Native.Win32]::FindWindow("ApplicationFrameWindow", $null)
    if ($hwnd) {
        [Native.Win32]::ShowWindow($hwnd, 9) | Out-Null
        Start-Sleep -Milliseconds 300
        [Native.Win32]::SetForegroundWindow($hwnd) | Out-Null
        Start-Sleep -Milliseconds 500
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
    $currentStr = "Saved: $outputPath"
    $expectedStr = "Manual check"
} catch {
    $status = "FAIL"
    $currentStr = "ERROR: $($_.Exception.Message)"
    $expectedStr = "Screenshot failed"
}

Write-CheckResult -No $checkNo -Name $checkName -Status $status -Current $currentStr -Expected $expectedStr