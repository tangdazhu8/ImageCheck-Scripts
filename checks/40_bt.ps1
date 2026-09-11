# === 预期值 ===
$expectedVer = "1.1044.0.556"


# === 脚本配置 ===
$checkNo = 40
$checkName = "BT驱动"

# Check #40: BT驱动版本
. "$PSScriptRoot\..\common.ps1"
$ErrorActionPreference = 'Stop'
try {
    $drv = Get-WmiObject Win32_PnPSignedDriver | Where-Object { $_.DeviceName -match "Bluetooth" -and $_.DeviceID -match "USB" } | Select-Object -First 1
    if (-not $drv) {
        $drv = Get-WmiObject Win32_PnPSignedDriver | Where-Object { $_.DeviceClass -eq "Bluetooth" } | Select-Object -First 1
    }
    if ($drv) {
        $currentVer = $drv.DriverVersion
        $currentStr = "BT=$($drv.DeviceName), version=$currentVer"
    } else {
        $currentVer = "NOT_FOUND"
        $currentStr = "$($drv.DeviceName) driver not found"
    }
    $expectedStr = "$($drv.DeviceName)=$expectedVer"
    if ($currentVer -eq $expectedVer) { $status = "PASS" } else { $status = "FAIL" }
} catch {
    $status = "FAIL"
    $currentStr = "ERROR: $($_.Exception.Message)"
    $expectedStr = "$($drv.DeviceName)=$expectedVer"
}
Write-CheckResult -No $checkNo -Name $checkName -Status $status -Current $currentStr -Expected $expectedStr