# === 预期值 ===
$expectedUsbSuspend = 0

# === 脚本配置 ===
$checkNo = 23
$checkName = "USB选择性暂停"

# Check #23: USB选择性暂停
. "$PSScriptRoot\..\common.ps1"
$ErrorActionPreference = 'Stop'
try {
    $usbSubGroup = "2a737441-1930-4402-8d77-b2bebba308a3"
    $usbSetting  = "48e6b7a6-50f5-4782-a5d4-53bb8f07e226"

    $acVal = Get-PowerSettingValue -SubGroupGuid $usbSubGroup -SettingGuid $usbSetting -AcDc "AC"

    $currentStr = "USB Selective Suspend AC=$acVal (0=disabled, 1=enabled)"
    $expectedStr = "USB Selective Suspend AC = $expectedUsbSuspend (disabled)"

    if ($acVal -eq $expectedUsbSuspend) { $status = "PASS" } else { $status = "FAIL" }
} catch {
    $status = "FAIL"
    $currentStr = "ERROR: $($_.Exception.Message)"
    $expectedStr = "USB Selective Suspend AC = $expectedUsbSuspend (disabled)"
}
Write-CheckResult -No $checkNo -Name $checkName -Status $status -Current $currentStr -Expected $expectedStr