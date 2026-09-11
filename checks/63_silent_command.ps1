# === 预期值 ===
$expectedLine = 'start /wait /b "" "%systemdrive%\Recovery\OEM\software\update_ops.exe" /S'

# === 脚本配置 ===
$checkNo = 63
$checkName = "静默安装命令"

# Check #63: scanstate.bat第33行静默命令
. "$PSScriptRoot\..\common.ps1"
$ErrorActionPreference = 'Stop'

$batPath = "$env:SystemDrive\recovery\oem\scanstate.bat"

try {
    if (-not (Test-Path $batPath)) {
        $status = "FAIL"
        $currentStr = "File not found: $batPath"
        $expectedStr = "Line 33: $expectedLine"
    } else {
        $lines = Get-Content -Path $batPath -Encoding Default
        if ($lines.Count -lt 33) {
            $status = "FAIL"
            $currentStr = "File has only $($lines.Count) lines"
            $expectedStr = "Line 33: $expectedLine"
        } else {
            $line33 = $lines[32].Trim()
            $currentStr = "Line 33: $line33"
            if ($line33 -eq $expectedLine) { $status = "PASS" } else { $status = "FAIL" }
            $expectedStr = "Line 33: $expectedLine"
        }
    }
} catch {
    $status = "FAIL"
    $currentStr = "ERROR: $($_.Exception.Message)"
    $expectedStr = "Line 33: $expectedLine"
}
Write-CheckResult -No $checkNo -Name $checkName -Status $status -Current $currentStr -Expected $expectedStr