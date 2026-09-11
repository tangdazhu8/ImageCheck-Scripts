# === 预期值 ===
$expectedMinLen = 6

# === 脚本配置 ===
$checkNo = 16
$checkName = "密码最小长度"

# Check #16: 密码长度最小值 >= 6
. "$PSScriptRoot\..\common.ps1"
$ErrorActionPreference = 'Stop'
try {
    Restore-OriginalEncoding
    $output = net accounts 2>&1 | Out-String
    Set-Utf8Encoding

    $match = [regex]::Match($output, "(?i)(minimum password length|密码长度最小值|密码的最小长度)\s*[:=：]?\s*(\d+)")
    if ($match.Success) {
        $minLen = [int]$match.Groups[2].Value
    } else {
        $minLen = -1
    }
    $currentStr = "Minimum password length=$minLen"
    $expectedStr = "Minimum password length >= $expectedMinLen"
    if ($minLen -ge $expectedMinLen) { $status = "PASS" } else { $status = "FAIL" }
} catch {
    Set-Utf8Encoding
    $status = "FAIL"
    $currentStr = "ERROR: $($_.Exception.Message)"
    $expectedStr = "Minimum password length >= $expectedMinLen"
}
Write-CheckResult -No $checkNo -Name $checkName -Status $status -Current $currentStr -Expected $expectedStr