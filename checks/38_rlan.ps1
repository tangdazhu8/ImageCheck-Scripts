# === 预期值 ===
$expectedVer = "10.79.50.1003"

# === 脚本配置 ===
$checkNo = 38
$checkName = "RLAN驱动"

# Check #38: RLAN (Realtek LAN) 驱动版本
. "$PSScriptRoot\..\common.ps1"
$ErrorActionPreference = 'Stop'
try {
    $drv = Get-WmiObject Win32_PnPSignedDriver | Where-Object { $_.DeviceName -match "Realtek.*PCIe" -and $_.DeviceName -match "GbE" -or $_.DeviceName -match "Realtek.*Ethernet" -and $_.DeviceName -notmatch "USB" } | Select-Object -First 1
    if (-not $drv) {
        $drv = Get-WmiObject Win32_PnPSignedDriver | Where-Object { $_.DeviceName -match "Realtek" -and $_.DeviceName -match "LAN" -and $_.DeviceName -notmatch "USB" } | Select-Object -First 1
    }
    if ($drv) {
        $currentVer = $drv.DriverVersion
        $currentStr = "RLAN=$($drv.DeviceName), version=$currentVer"
    } else {
        $currentVer = "NOT_FOUND"
        $currentStr = "RLAN driver not found"
    }
    $expectedStr = "RLAN=$expectedVer"
    if ($currentVer -eq $expectedVer) { $status = "PASS" } else { $status = "FAIL" }
} catch {
    $status = "FAIL"
    $currentStr = "ERROR: $($_.Exception.Message)"
    $expectedStr = "RLAN=$expectedVer"
}
Write-CheckResult -No $checkNo -Name $checkName -Status $status -Current $currentStr -Expected $expectedStr