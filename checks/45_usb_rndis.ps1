# === 预期值 ===
$expectedVer = "10.0.26100.1"

# === 脚本配置 ===
$checkNo = 45
$checkName = "USB RNDIS驱动"

# Check #45: USB RNDIS 驱动版本
. "$PSScriptRoot\..\common.ps1"
$ErrorActionPreference = 'Stop'
try {
    $drv = Get-WmiObject Win32_PnPSignedDriver | Where-Object { $_.DeviceName -match "RNDIS" -or $_.DeviceName -match "Remote NDIS" } | Select-Object -First 1
    if ($drv) {
        $currentVer = $drv.DriverVersion
        $currentStr = "USB RNDIS=$($drv.DeviceName), version=$currentVer"
    } else {
        $currentVer = "NOT_FOUND"
        $currentStr = "USB RNDIS driver not found"
    }
    $expectedStr = "USB RNDIS=$expectedVer"
    if ($currentVer -eq $expectedVer) { $status = "PASS" } else { $status = "FAIL" }
} catch {
    $status = "FAIL"
    $currentStr = "ERROR: $($_.Exception.Message)"
    $expectedStr = "USB RNDIS=$expectedVer"
}
Write-CheckResult -No $checkNo -Name $checkName -Status $status -Current $currentStr -Expected $expectedStr