# common.ps1 - Shared functions for image checklist audit
# Save original encodings before changing (to avoid breaking external commands like dism)
$global:OriginalOutputEncoding = [Console]::OutputEncoding
$global:OriginalInputEncoding = [Console]::InputEncoding
$global:OriginalOutputVar = $OutputEncoding

# Set UTF-8 for JSON output with Chinese characters
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

function Restore-OriginalEncoding {
    [Console]::OutputEncoding = $global:OriginalOutputEncoding
    [Console]::InputEncoding = $global:OriginalInputEncoding
    $OutputEncoding = $global:OriginalOutputVar
}

function Set-Utf8Encoding {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    [Console]::InputEncoding = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.Encoding]::UTF8
}

function Write-CheckResult {
    param(
        [int]$No,
        [string]$Name,
        [string]$Status,
        [string]$Current,
        [string]$Expected
    )
    $result = [ordered]@{
        no       = $No
        name     = $Name
        status   = $Status
        current  = $Current
        expected = $Expected
    }
    Write-Output ($result | ConvertTo-Json -Compress)
}

function Get-RegistryValue {
    param(
        [string]$Path,
        [string]$Name
    )
    try {
        $val = Get-ItemProperty -Path $Path -Name $Name -ErrorAction Stop
        return $val.$Name
    } catch {
        return $null
    }
}

function Get-PowerSettingValue {
    param(
        [string]$SubGroupGuid,
        [string]$SettingGuid,
        [string]$AcDc = "AC"
    )
    # Temporarily restore system encoding for powercfg output
    Restore-OriginalEncoding
    $output = powercfg /query SCHEME_CURRENT $SubGroupGuid $SettingGuid 2>&1 | Out-String
    Set-Utf8Encoding
    # Handle both half-width colon(:) and full-width colon(：) for Chinese systems
    $pattern = if ($AcDc -eq "AC") {
        "(?i)(Current AC Power Setting Index|当前交流电源设置索引)\s*[:=：]\s*0x([0-9a-fA-F]+)"
    } else {
        "(?i)(Current DC Power Setting Index|当前直流电源设置索引)\s*[:=：]\s*0x([0-9a-fA-F]+)"
    }
    if ($output -match $pattern) {
        return [Convert]::ToInt32($Matches[2], 16)
    }
    return $null
}
# Unified Win32 API definitions for all check scripts
if (-not ([System.Management.Automation.PSTypeName]'Native.Win32').Type) {
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
public static extern IntPtr SendMessage(IntPtr hWnd, uint Msg, IntPtr wParam, IntPtr lParam);
[DllImport("user32.dll")]
public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);
[DllImport("user32.dll")]
public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);
[DllImport("user32.dll")]
public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, uint uFlags);
[DllImport("user32.dll")]
public static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, UIntPtr dwExtraInfo);
[DllImport("user32.dll")]
public static extern bool EndTask(IntPtr hWnd, bool fShutDown, bool fForce);
[DllImport("user32.dll", CharSet = CharSet.Auto)]
public static extern int GetWindowText(IntPtr hWnd, System.Text.StringBuilder lpString, int nMaxCount);
public struct RECT { public int Left, Top, Right, Bottom; }
'@
    Add-Type -MemberDefinition $win32Sig -Name "Win32" -Namespace "Native"
}

# 展开设置页中的 expander（ExpandCollapse.Expand 或对非开关 Invoke），不会拨动 Toggle。
# 按名称匹配，避免 Tab/Enter 改到旁边的设置项。
function Expand-SettingsExpander {
    param(
        [string[]]$NameHints,
        [int]$TimeoutMs = 5000
    )
    try {
        Add-Type -AssemblyName UIAutomationClient -ErrorAction Stop
        Add-Type -AssemblyName UIAutomationTypes -ErrorAction Stop
    } catch {
        return $false
    }

    $types = @(
        [System.Windows.Automation.ControlType]::Button,
        [System.Windows.Automation.ControlType]::Group,
        [System.Windows.Automation.ControlType]::Hyperlink,
        [System.Windows.Automation.ControlType]::Custom,
        [System.Windows.Automation.ControlType]::SplitButton,
        [System.Windows.Automation.ControlType]::ListItem,
        [System.Windows.Automation.ControlType]::Text
    )

    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    do {
        try {
            $root = [System.Windows.Automation.AutomationElement]::RootElement
            $settings = $null
            foreach ($winName in @('Settings', '设置')) {
                $cond = New-Object System.Windows.Automation.PropertyCondition(
                    [System.Windows.Automation.AutomationElement]::NameProperty, $winName)
                $settings = $root.FindFirst([System.Windows.Automation.TreeScope]::Children, $cond)
                if ($settings) { break }
            }
            if (-not $settings) {
                Start-Sleep -Milliseconds 250
                continue
            }

            $any = $false
            $seen = New-Object 'System.Collections.Generic.HashSet[int]'
            foreach ($ctype in $types) {
                $condType = New-Object System.Windows.Automation.PropertyCondition(
                    [System.Windows.Automation.AutomationElement]::ControlTypeProperty, $ctype)
                $els = $settings.FindAll([System.Windows.Automation.TreeScope]::Descendants, $condType)
                foreach ($el in $els) {
                    $id = 0
                    try { $id = $el.Current.NativeWindowHandle } catch {}
                    $name = $el.Current.Name
                    if (-not $name) { continue }
                    $hit = $false
                    foreach ($hint in $NameHints) {
                        if ($name -eq $hint -or $name -like "*$hint*") { $hit = $true; break }
                    }
                    if (-not $hit) { continue }
                    $hash = $name.GetHashCode() -bxor $id
                    if (-not $seen.Add($hash)) { continue }

                    $isToggle = $false
                    try {
                        $null = $el.GetCurrentPattern([System.Windows.Automation.TogglePattern]::Pattern)
                        $isToggle = $true
                    } catch {}
                    if ($isToggle) { continue }

                    $did = $false
                    try {
                        $exp = [System.Windows.Automation.ExpandCollapsePattern]$el.GetCurrentPattern(
                            [System.Windows.Automation.ExpandCollapsePattern]::Pattern)
                        $state = $exp.Current.ExpandCollapseState
                        if ($state -eq [System.Windows.Automation.ExpandCollapseState]::Collapsed) {
                            $exp.Expand()
                        }
                        $did = $true
                    } catch {}
                    if (-not $did) {
                        try {
                            $inv = [System.Windows.Automation.InvokePattern]$el.GetCurrentPattern(
                                [System.Windows.Automation.InvokePattern]::Pattern)
                            $inv.Invoke()
                            $did = $true
                        } catch {}
                    }
                    if ($did) { $any = $true }
                }
            }
            if ($any) { return $true }
        } catch {}
        Start-Sleep -Milliseconds 250
    } while ($sw.ElapsedMilliseconds -lt $TimeoutMs)
    return $false
}