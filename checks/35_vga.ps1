# === 预期值 ===
$expectedVer = "32.0.101.8425"

# === 脚本配置 ===
$checkNo = 35
$checkName = "VGA驱动"

# Check #35: VGA 驱动版本
. "$PSScriptRoot\..\common.ps1"
$ErrorActionPreference = 'Stop'
try {
    $drv = Get-WmiObject Win32_PnPSignedDriver | Where-Object { $_.DeviceName -like "Intel*Graphics" -or $_.DeviceName -match "VGA" -or $_.DeviceClass -eq "DISPLAY" } | Select-Object -First 1
    if ($drv) {
        $currentVer = $drv.DriverVersion
        $currentStr = "VGA=$($drv.DeviceName), version=$currentVer"
    } else {
        $currentVer = "NOT_FOUND"
        $currentStr = "VGA driver not found"
    }
    $expectedStr = "VGA=$expectedVer"
    if ($currentVer -eq $expectedVer) { $status = "PASS" } else { $status = "FAIL" }
} catch {
    $status = "FAIL"
    $currentStr = "ERROR: $($_.Exception.Message)"
    $expectedStr = "VGA=$expectedVer"
}
Write-CheckResult -No $checkNo -Name $checkName -Status $status -Current $currentStr -Expected $expectedStr