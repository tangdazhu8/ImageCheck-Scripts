# === 预期值 ===
$expectedRecovery = "No"
$expectedBootPolicy = "IgnoreAllFailures"

# === 脚本配置 ===
$checkNo = 4
$checkName = "BCD fix mode"

# Check #4: 关闭非法关机重启进入修复模式
. "$PSScriptRoot\..\common.ps1"
$ErrorActionPreference = 'Stop'

$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-CheckResult -No $checkNo -Name $checkName -Status "MANUAL" -Current "bcdedit requires admin privileges" -Expected "recoveryenabled=$expectedRecovery, bootstatuspolicy=$expectedBootPolicy"
    exit 0
}

try {
    Restore-OriginalEncoding
    $bcdOutput = bcdedit /enum "{current}" 2>&1 | Out-String
    Set-Utf8Encoding

    $recoveryMatch = [regex]::Match($bcdOutput, "recoveryenabled\s+(\S+)", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    $bootPolicyMatch = [regex]::Match($bcdOutput, "bootstatuspolicy\s+(\S+)", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)

    $recoveryVal = if ($recoveryMatch.Success) { $recoveryMatch.Groups[1].Value } else { "NOT_FOUND" }
    $bootPolicyVal = if ($bootPolicyMatch.Success) { $bootPolicyMatch.Groups[1].Value } else { "NOT_FOUND" }

    $currentStr = "recoveryenabled=$recoveryVal, bootstatuspolicy=$bootPolicyVal"
    $expectedStr = "recoveryenabled=$expectedRecovery, bootstatuspolicy=$expectedBootPolicy"

    if ($recoveryVal -eq $expectedRecovery -and $bootPolicyVal -eq $expectedBootPolicy) {
        $status = "PASS"
    } else {
        $status = "FAIL"
    }
} catch {
    Set-Utf8Encoding
    $status = "FAIL"
    $currentStr = "ERROR: $($_.Exception.Message)"
    $expectedStr = "recoveryenabled=$expectedRecovery, bootstatuspolicy=$expectedBootPolicy"
}

Write-CheckResult -No $checkNo -Name $checkName -Status $status -Current $currentStr -Expected $expectedStr