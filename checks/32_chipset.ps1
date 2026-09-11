# === 预期值 ===
$expectedVer = "10.1.47.12"

# === 脚本配置 ===
$checkNo = 32
$checkName = "Chipset驱动"

# Check #32: Chipset 驱动版本
. "$PSScriptRoot\..\common.ps1"
$ErrorActionPreference = 'Stop'
try {
    $drivers = pnputil /enum-drivers 2>&1 | Out-String
    $match = [regex]::Match($drivers, "(?s)(Intel.*Chipset[^`n]*?Driver version:\s+([0-9.]+))")
    if (-not $match.Success) {
        $match = [regex]::Match($drivers, "(?s)(Chipset[^`n]*?Driver version:\s+([0-9.]+))")
    }
    if ($match.Success) {
        $currentVer = $match.Groups[2].Value
        $currentStr = "$checkName version=$currentVer"
    } else {
        $drv = Get-WmiObject Win32_PnPSignedDriver | Where-Object { $_.DeviceName -match "Intel.*SRAM" -or $_.DeviceName -match "Intel.*LPC" -or $_.DeviceName -match "Intel.*SMBus" } | Select-Object -First 1
        if ($drv) {
            $currentVer = $drv.DriverVersion
            $currentStr = "Chipset=$($drv.DeviceName), version=$currentVer"
        } else {
            $currentVer = "NOT_FOUND"
            $currentStr = "Chipset driver not found"
        }
    }
    $expectedStr = "Chipset=$expectedVer"
    if ($currentVer -eq $expectedVer) { $status = "PASS" } else { $status = "FAIL" }
} catch {
    $status = "FAIL"
    $currentStr = "ERROR: $($_.Exception.Message)"
    $expectedStr = "Chipset=$expectedVer"
}
Write-CheckResult -No $checkNo -Name $checkName -Status $status -Current $currentStr -Expected $expectedStr