# === 预期值 ===
# 所有USB设备电源节能应关闭（SelectiveSuspendOn=0或不存在，MSPower_DeviceEnable.Enable=false）

# === 脚本配置 ===
$checkNo = 9
$checkName = "USB设备电源节能"

# Check #9: 关闭USB设备的电源节能
. "$PSScriptRoot\..\common.ps1"
$ErrorActionPreference = 'Stop'
try {
    $usbDevices = Get-PnpDevice -Class USB -Status OK -ErrorAction SilentlyContinue
    $failDevices = @()
    $checkedCount = 0

    foreach ($dev in $usbDevices) {
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
    foreach ($dev in $usbDevices) {
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
        $currentStr = "All USB devices power saving disabled (checked $checkedCount devices)"
        $status = "PASS"
    }
    $expectedStr = "All USB devices: power saving disabled"
} catch {
    $status = "FAIL"
    $currentStr = "ERROR: $($_.Exception.Message)"
    $expectedStr = "All USB devices: power saving disabled"
}
Write-CheckResult -No $checkNo -Name $checkName -Status $status -Current $currentStr -Expected $expectedStr