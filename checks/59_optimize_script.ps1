# === 预期值 ===
# MANUAL - 人工确认是否看到重启

# === 脚本配置 ===
$checkNo = 59
$checkName = "优化配置脚本"

# Check #59: 优化配置脚本 - 人工确认重启
. "$PSScriptRoot\..\common.ps1"
$ErrorActionPreference = 'Stop'

try {
    $status = "MANUAL"
    $currentStr = "Manual check"
    $expectedStr = "人工确认：优化配置脚本执行后是否出现重启"
} catch {
    $status = "FAIL"
    $currentStr = "ERROR: $($_.Exception.Message)"
    $expectedStr = "Manual check"
}
Write-CheckResult -No $checkNo -Name $checkName -Status $status -Current $currentStr -Expected $expectedStr