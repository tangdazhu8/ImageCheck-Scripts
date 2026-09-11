# === 预期值 ===
# MANUAL - 需人工确认

# === 脚本配置 ===
$checkNo = 54
$checkName = "系统初始化提示"

# Check #54: 系统初始化提示（人工确认）
. "$PSScriptRoot\..\common.ps1"
$ErrorActionPreference = 'Stop'
try {
    $status = "MANUAL"
    $currentStr = "Manual check needed"
    $expectedStr = "Manually verify initialization interface appears after system installation"
} catch {
    $status = "FAIL"
    $currentStr = "ERROR: $($_.Exception.Message)"
    $expectedStr = "Manual check"
}
Write-CheckResult -No $checkNo -Name $checkName -Status $status -Current $currentStr -Expected $expectedStr