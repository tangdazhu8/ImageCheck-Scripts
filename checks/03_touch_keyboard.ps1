# === 预期值 ===
# MANUAL - 截图检查，需人工确认

# === 脚本配置 ===
$checkNo = 3
$checkName = "Touch Keyboard"
$screenshotPrefix = "03"
$settingsUri = "ms-settings:typing"

# Check 3: Touch Keyboard Screenshot
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
[DllImport("user32.dll")]
public static extern IntPtr GetDC(IntPtr hWnd);
[DllImport("user32.dll")]
public static extern int ReleaseDC(IntPtr hWnd, IntPtr hDC);
'@

$gdi32Sig = @'
[DllImport("gdi32.dll")]
public static extern int GetDeviceCaps(IntPtr hdc, int nIndex);
'@
try { Add-Type -MemberDefinition $win32Sig -Name "Win32" -Namespace "Native" } catch {}
try { Add-Type -MemberDefinition $gdi32Sig -Name "Gdi32" -Namespace "Native" } catch {}

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

    $expanded = Expand-SettingsExpander -NameHints @(
        'Show more settings',
        '显示更多设置'
    )
    if (-not $expanded) {
        [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
        Start-Sleep -Milliseconds 1500
    } else {
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
    $currentStr = "Saved: $outputPath"
    $expectedStr = "Manual check"
} catch {
    $status = "FAIL"
    $currentStr = "ERROR: $($_.Exception.Message)"
    $expectedStr = "Screenshot failed"
}

Write-CheckResult -No $checkNo -Name $checkName -Status $status -Current $currentStr -Expected $expectedStr