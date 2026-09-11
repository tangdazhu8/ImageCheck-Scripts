# === 预期值 ===
$expectedThreshold = 5
$expectedDuration = 10
$expectedReset = 10

# === 脚本配置 ===
$checkNo = 17
$checkName = "账户锁定策略"

# Check #17: 账户锁定策略
. "$PSScriptRoot\..\common.ps1"
$ErrorActionPreference = 'Stop'
try {
    $tempFile = Join-Path $env:TEMP "secpolicy_$PID.inf"

    Restore-OriginalEncoding
    secedit /export /cfg $tempFile /areas SECURITYPOLICY 2>&1 | Out-Null
    Set-Utf8Encoding

    if (Test-Path $tempFile) {
        $content = Get-Content $tempFile -Raw -ErrorAction SilentlyContinue

        $threshMatch = [regex]::Match($content, "LockoutBadCount\s*=\s*(\d+)")
        $durMatch = [regex]::Match($content, "LockoutDuration\s*=\s*(\d+)")
        $resetMatch = [regex]::Match($content, "ResetLockoutCount\s*=\s*(\d+)")

        $threshold = if ($threshMatch.Success) { [int]$threshMatch.Groups[1].Value } else { -1 }
        $duration = if ($durMatch.Success) { [int]$durMatch.Groups[1].Value } else { -1 }
        $reset = if ($resetMatch.Success) { [int]$resetMatch.Groups[1].Value } else { -1 }

        Remove-Item $tempFile -Force -ErrorAction SilentlyContinue

        $currentStr = "Threshold=$threshold, Duration=${duration}min, Reset=${reset}min"
        $expectedStr = "Threshold=$expectedThreshold, Duration=${expectedDuration}min, Reset=${expectedReset}min"

        if ($threshold -eq $expectedThreshold -and $duration -eq $expectedDuration -and $reset -eq $expectedReset) {
            $status = "PASS"
        } else {
            $status = "FAIL"
        }
    } else {
        Restore-OriginalEncoding
        $output = net accounts 2>&1 | Out-String
        Set-Utf8Encoding

        $threshMatch = [regex]::Match($output, "(?i)(lockout threshold|锁定阈值)[^:：\d]*[:=：]?\s*(\d+)")
        $threshold = if ($threshMatch.Success) { [int]$threshMatch.Groups[2].Value } else { -1 }
        $durMatch = [regex]::Match($output, "(?i)(lockout duration|锁定持续时间)[^:：\d]*[:=：]?\s*(\d+)")
        $duration = if ($durMatch.Success) { [int]$durMatch.Groups[2].Value } else { -1 }
        $resetMatch = [regex]::Match($output, "(?i)(reset.*lockout|重置.*计数器)[^:：\d]*[:=：]?\s*(\d+)")
        $reset = if ($resetMatch.Success) { [int]$resetMatch.Groups[2].Value } else { -1 }

        $currentStr = "Threshold=$threshold, Duration=${duration}min, Reset=${reset}min (from net accounts)"
        $expectedStr = "Threshold=$expectedThreshold, Duration=${expectedDuration}min, Reset=${expectedReset}min"
        if ($threshold -eq $expectedThreshold -and $duration -eq $expectedDuration -and $reset -eq $expectedReset) {
            $status = "PASS"
        } else {
            $status = "FAIL"
        }
    }
} catch {
    Set-Utf8Encoding
    $status = "FAIL"
    $currentStr = "ERROR: $($_.Exception.Message)"
    $expectedStr = "Threshold=$expectedThreshold, Duration=${expectedDuration}min, Reset=${expectedReset}min"
}
Write-CheckResult -No $checkNo -Name $checkName -Status $status -Current $currentStr -Expected $expectedStr