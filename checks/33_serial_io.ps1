# === 预期值 ===
$expectedVer = "30.100.2527.40"

# === 脚本配置 ===
$checkNo = 33
$checkName = "Serial IO驱动"

# Check #33: Serial IO 驱动版本
. "$PSScriptRoot\..\common.ps1"
$ErrorActionPreference = 'Stop'
try {
    $drv = Get-WmiObject Win32_PnPSignedDriver | Where-Object { $_.DeviceName -match "Serial IO" -or $_.DeviceName -match "SerialIO" } | Select-Object -First 1
    if ($drv) {
        $currentVer = $drv.DriverVersion
        $currentStr = "SerialIO=$($drv.DeviceName), version=$currentVer"
    } else {
        $currentVer = "NOT_FOUND"
        $currentStr = "Serial IO driver not found"
    }
    $expectedStr = "Serial IO=$expectedVer"
    if ($currentVer -eq $expectedVer) { $status = "PASS" } else { $status = "FAIL" }
} catch {
    $status = "FAIL"
    $currentStr = "ERROR: $($_.Exception.Message)"
    $expectedStr = "Serial IO=$expectedVer"
}
Write-CheckResult -No $checkNo -Name $checkName -Status $status -Current $currentStr -Expected $expectedStr