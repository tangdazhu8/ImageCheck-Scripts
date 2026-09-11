# === 预期值 ===
$expectedTcpStatus = "disabled"

# === 脚本配置 ===
$checkNo = 25
$checkName = "TCP Timestamps"

# Check #25: TCP Timestamps disabled
. "$PSScriptRoot\..\common.ps1"
$ErrorActionPreference = 'Stop'
try {
    Restore-OriginalEncoding
    $output = netsh interface tcp show global 2>&1 | Out-String
    Set-Utf8Encoding

    $match = [regex]::Match($output, "(?i)(timestamps|时间戳|时间戳记)\s*[:=：]?\s*(\S+)")
    if ($match.Success) {
        $tsVal = $match.Groups[2].Value
    } else {
        $tsVal = "NOT_FOUND"
    }
    $currentStr = "TCP timestamps=$tsVal"
    $expectedStr = "timestamps=$expectedTcpStatus"
    if ($tsVal -match "^(disabled|disable|禁用|否|no)$") {
        $status = "PASS"
    } else {
        $status = "FAIL"
    }
} catch {
    Set-Utf8Encoding
    $status = "FAIL"
    $currentStr = "ERROR: $($_.Exception.Message)"
    $expectedStr = "timestamps=$expectedTcpStatus"
}
Write-CheckResult -No $checkNo -Name $checkName -Status $status -Current $currentStr -Expected $expectedStr