# === 预期值 ===
$expectedVer = "23.160.0.4"

# === 脚本配置 ===
$checkNo = 39
$checkName = "WLAN驱动"

# Check #39: WLAN 驱动版本
. "$PSScriptRoot\..\common.ps1"
$ErrorActionPreference = 'Stop'
try {
    $drv = Get-WmiObject Win32_PnPSignedDriver | Where-Object { $_.DeviceName -match "Wi-Fi" -and $_.Deviceclass -match "Net" -and $_.DeviceID -match "PCI" } | Select-Object -First 1
    if ($drv) {
        $currentVer = $drv.DriverVersion
        $currentStr = "WLAN=$($drv.DeviceName), version=$currentVer"
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