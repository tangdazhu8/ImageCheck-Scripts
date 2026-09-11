# === 预期值 ===
$expectedVer = "3.1.2.6"

# === 脚本配置 ===
$checkNo = 42
$checkName = "PMT驱动"

# Check #42: PMT 驱动版本
. "$PSScriptRoot\..\common.ps1"
$ErrorActionPreference = 'Stop'
try {
    $drv = Get-WmiObject Win32_PnPSignedDriver | Where-Object { $_.DeviceName -match "PMT" -or $_.DeviceName -match "Platform Management" } | Select-Object -First 1
    if ($drv) {
        $currentVer = $drv.DriverVersion
        $currentStr = "PMT=$($drv.DeviceName), version=$currentVer"
    } else {
        $currentVer = "NOT_FOUND"
        $currentStr = "PMT driver not found"
    }
    $expectedStr = "PMT=$expectedVer"
    if ($currentVer -eq $expectedVer) { $status = "PASS" } else { $status = "FAIL" }
} catch {
    $status = "FAIL"
    $currentStr = "ERROR: $($_.Exception.Message)"
    $expectedStr = "PMT=$expectedVer"
}
Write-CheckResult -No $checkNo -Name $checkName -Status $status -Current $currentStr -Expected $expectedStr