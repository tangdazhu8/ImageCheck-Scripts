# === 预期值 ===
# MANUAL - 人工确认重启时间

# === 脚本配置 ===
$checkNo = 60
$checkName = "ideaUI启动"

# Check #60: ideaUI正常启动 - 记录重启耗时
. "$PSScriptRoot\..\common.ps1"
$ErrorActionPreference = 'Stop'

try {
    $status = "MANUAL"
    $currentStr = "Manual check"
    $expectedStr = "人工确认：若看到重启，记录从个人数据跨境传输界面到出现重启界面的时间"
} catch {
    $status = "FAIL"
    $currentStr = "ERROR: $($_.Exception.Message)"
    $expectedStr = "Manual check"
}
Write-CheckResult -No $checkNo -Name $checkName -Status $status -Current $currentStr -Expected $expectedStr