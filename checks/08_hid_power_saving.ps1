# === 预期值 ===
# 所有HID设备电源节能应关闭（SelectiveSuspendOn=0或不存在，MSPower_DeviceEnable.Enable=false）

# === 脚本配置 ===
$checkNo = 8
$checkName = "HID设备电源节能"

# Check #8: 关闭人体学输入设备的电源节能
. "$PSScriptRoot\..\common.ps1"
$ErrorActionPreference = 'Stop'
try {
    $hidDevices = Get-PnpDevice -Class HIDClass -Status OK -ErrorAction SilentlyContinue
    $failDevices = @()
    $checkedCount = 0

    foreach ($dev in $hidDevices) {
        $devRegPath = "HKLM:\SYSTEM\CurrentControlSet\Enum\$($dev.InstanceId)\Device Parameters"
        if (Test-Path $devRegPath) {
            $suspendOn = Get-RegistryValue -Path $devRegPath -Name "SelectiveSuspendOn"
            if ($null -ne $suspendOn -and $suspendOn -ne 0) {
                $failDevices += "$($dev.FriendlyName): SelectiveSuspendOn=$suspendOn"
            }
            $checkedCount++
        }
    }

    $allPowerMgmt = Get-WmiObject -Query "SELECT * FROM MSPower_DeviceEnable" -Namespace "root\wmi" -ErrorAction SilentlyContinue
    $enabledDevices = @()
    foreach ($dev in $hidDevices) {
        $pnpId = $dev.PNPDeviceID
        if ($pnpId -and $allPowerMgmt) {
            $matched = $allPowerMgmt | Where-Object { $_.InstanceName -like "$pnpId*" }
            foreach ($item in $matched) {
                if ($item.Enable -eq $true) {
                    $enabledDevices += "$($dev.FriendlyName): $($item.InstanceName)"
                }
            }
        }
    }

    if ($failDevices.Count -gt 0) {
        $currentStr = "Registry FAIL: $($failDevices -join '; ')"
        $status = "FAIL"
    } elseif ($enabledDevices.Count -gt 0) {
        $currentStr = "WMI power saving enabled: $($enabledDevices -join '; ')"
        $status = "FAIL"
    } else {
        $currentStr = "All HID devices power saving disabled (checked $checkedCount devices)"
        $status = "PASS"
    }
    $expectedStr = "All HID devices: power saving disabled"
} catch {
    $status = "FAIL"
    $currentStr = "ERROR: $($_.Exception.Message)"
    $expectedStr = "All HID devices: power saving disabled"
}
Write-CheckResult -No $checkNo -Name $checkName -Status $status -Current $currentStr -Expected $expectedStr