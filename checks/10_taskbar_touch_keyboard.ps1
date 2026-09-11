# === 预期值 ===
$expectedRegValue = 1

# === 脚本配置 ===
$checkNo = 10
$checkName = "任务栏Touch keyboard"

# Check #10: 任务栏显示Touch keyboard按钮
. "$PSScriptRoot\..\common.ps1"
$ErrorActionPreference = 'Stop'
try {
    $path = "HKCU:\Software\Microsoft\TabletTip\1.7"
    $val = Get-RegistryValue -Path $path -Name "TipbandDesiredVisibility"

    $currentStr = "TipbandDesiredVisibility=$val"
    $expectedStr = "TipbandDesiredVisibility=$expectedRegValue"

    if ($val -eq $expectedRegValue) { $status = "PASS" } else { $status = "FAIL" }
} catch {
    $status = "FAIL"
    $currentStr = "ERROR: $($_.Exception.Message)"
    $expectedStr = "TipbandDesiredVisibility=$expectedRegValue"
}
Write-CheckResult -No $checkNo -Name $checkName -Status $status -Current $currentStr -Expected $expectedStr