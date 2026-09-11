# === 预期值 ===
$expectedLogPath = "$env:SystemRoot\System32\log.log"
$expectedSuccessCount = 4

# === 脚本配置 ===
$checkNo = 52
$checkName = "初始化日志"

# Check #52: 初始化日志文件完整性
. "$PSScriptRoot\..\common.ps1"
$ErrorActionPreference = 'Stop'
try {
    if (-not (Test-Path $expectedLogPath)) {
        $status = "FAIL"
        $currentStr = "Log file not found: $expectedLogPath"
    } else {
        $logContent = Get-Content $expectedLogPath -ErrorAction SilentlyContinue
        $statusLines = $logContent | Where-Object { $_ -match 'status:' }
        $successLines = $statusLines | Where-Object { $_ -match 'status:\s*Success' }
        $failedLines = $statusLines | Where-Object { $_ -notmatch 'status:\s*Success' } | ForEach-Object { $_.Trim() }
        $successCount = @($successLines).Count
        $failCount = @($failedLines).Count
        $totalStatus = @($statusLines).Count
        if ($failCount -eq 0 -and $successCount -eq $expectedSuccessCount) {
            $status = "PASS"
            $currentStr = "Log file found, $successCount/$expectedSuccessCount status: Success"
        } elseif ($totalStatus -eq 0) {
            $status = "FAIL"
            $currentStr = "Log file found, no status lines detected"
        } elseif ($successCount -ne $expectedSuccessCount) {
            $status = "FAIL"
            $currentStr = "Log file found, expected $expectedSuccessCount Success, got $successCount (total status lines: $totalStatus)"
        } else {
            $status = "FAIL"
            $currentStr = "Log file found, $failCount non-Success status: $($failedLines -join '; ')"
        }
    }
    $expectedStr = "Log file at $expectedLogPath, all $expectedSuccessCount status: Success"
} catch {
    $status = "FAIL"
    $currentStr = "ERROR: $($_.Exception.Message)"
    $expectedStr = "Log file at $expectedLogPath, all $expectedSuccessCount status: Success"
}
Write-CheckResult -No $checkNo -Name $checkName -Status $status -Current $currentStr -Expected $expectedStr