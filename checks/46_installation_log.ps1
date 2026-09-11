# === 预期值 ===
$expectedLogPath = "C:\installation.log"
$expectedOSVersion = "V2.0.1.5"
$expectedDate = "20260814"

# === 脚本配置 ===
$checkNo = 46
$checkName = "安装日志"

# Check #46: 安装日志内容校验
. "$PSScriptRoot\..\common.ps1"
$ErrorActionPreference = 'Stop'
try {
    if (-not (Test-Path $expectedLogPath)) {
        $status = "FAIL"
        $currentStr = "Log file not found: $expectedLogPath"
    } else {
        $logContent = Get-Content $expectedLogPath -ErrorAction SilentlyContinue
        $issues = @()

        $osVersion = ($logContent | Select-String -Pattern 'OSVersion\s*[=:]\s*(.+)' | Select-Object -First 1).Matches.Groups[1].Value.Trim()
        if (-not $osVersion) {
            $issues += "OSVersion not found"
        } elseif ($osVersion -ne $expectedOSVersion) {
            $issues += "OSVersion mismatch: expected $expectedOSVersion, got $osVersion"
        }

        $date = ($logContent | Select-String -Pattern 'Date\s*[=:]\s*(.+)' | Select-Object -First 1).Matches.Groups[1].Value.Trim()
        if (-not $date) {
            $issues += "Date not found"
        } elseif ($date -ne $expectedDate) {
            $issues += "Date mismatch: expected $expectedDate, got $date"
        }

        if ($issues.Count -eq 0) {
            $status = "PASS"
            $currentStr = "OSVersion=$osVersion, Date=$date"
        } else {
            $status = "FAIL"
            $currentStr = "OSVersion=$osVersion, Date=$date | $($issues -join '; ')"
        }
    }
    $expectedStr = "OSVersion=$expectedOSVersion, Date=$expectedDate"
} catch {
    $status = "FAIL"
    $currentStr = "ERROR: $($_.Exception.Message)"
    $expectedStr = "OSVersion=$expectedOSVersion, Date=$expectedDate"
}
Write-CheckResult -No $checkNo -Name $checkName -Status $status -Current $currentStr -Expected $expectedStr