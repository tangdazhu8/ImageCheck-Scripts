# === 预期值 ===
$expectedWifiMode = 0

# === 脚本配置 ===
$checkNo = 24
$checkName = "无线设备节能"

# Check #24: 无线设备节能模式 - 仅确认AC为最高性能
. "$PSScriptRoot\..\common.ps1"
$ErrorActionPreference = 'Stop'
try {
    $wifiSubGroup = "19cbb8fa-5279-450e-9fac-8a3d5fedd0c1"
    $wifiSetting  = "12bbebe6-58d6-4636-95bb-3217ef867c1a"

    $acVal = Get-PowerSettingValue -SubGroupGuid $wifiSubGroup -SettingGuid $wifiSetting -AcDc "AC"

    $modeNames = @{0="Maximum Performance"; 1="Low Power Saving"; 2="Medium Power Saving"}
    $acName = if ($modeNames.ContainsKey([int]$acVal)) { $modeNames[[int]$acVal] } else { "Unknown($acVal)" }

    $currentStr = "AC=$acName($acVal)"
    $expectedStr = "AC = Maximum Performance ($expectedWifiMode)"

    if ($acVal -eq $expectedWifiMode) { $status = "PASS" } else { $status = "FAIL" }
} catch {
    $status = "FAIL"
    $currentStr = "ERROR: $($_.Exception.Message)"
    $expectedStr = "AC = Maximum Performance ($expectedWifiMode)"
}
Write-CheckResult -No $checkNo -Name $checkName -Status $status -Current $currentStr -Expected $expectedStr