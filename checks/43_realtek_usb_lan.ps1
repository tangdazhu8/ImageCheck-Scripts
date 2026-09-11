# === 预期值 ===
$expectedVer = "11.15.327.2024"

# === 脚本配置 ===
$checkNo = 43
$checkName = "Realtek USB LAN驱动"

# Check #43: Realtek USB LAN 驱动版本
. "$PSScriptRoot\..\common.ps1"
$ErrorActionPreference = 'Stop'
try {
    $currentVer = $null
    $currentStr = $null
    $drv = Get-WmiObject Win32_PnPSignedDriver | Where-Object { $_.DeviceName -match "Realtek" -and $_.DeviceName -match "USB" -and ($_.DeviceName -match "LAN" -or $_.DeviceName -match "Ethernet") } | Select-Object -First 1
    if ($drv) {
        $currentVer = $drv.DriverVersion
        $currentStr = "Realtek USB LAN=$($drv.DeviceName), version=$currentVer"
    } else {
        $infPath = Get-ChildItem "$env:SystemRoot\System32\DriverStore\FileRepository\rtucx22*\rtucx22x64.INF" -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($infPath) {
            $infContent = Get-Content $infPath.FullName -ErrorAction SilentlyContinue
            $match = $infContent | Select-String -Pattern 'DriverVer\s*=\s*\d{2}/\d{2}/\d{4},(.+)' | Select-Object -First 1
            if ($match) {
                $currentVer = $match.Matches[0].Groups[1].Value.Trim()
                $currentStr = "Realtek USB LAN=$currentVer (from INF)"
            }
        }
        if (-not $currentVer) {
            $currentVer = "NOT_FOUND"
            $currentStr = "Realtek USB LAN driver not found"
        }
    }
    $expectedStr = "Realtek USB LAN=$expectedVer"
    $normCurrent = if ($currentVer -match '^\d+(\.\d+)+$') { (($currentVer -split '\.' | ForEach-Object { [int]$_ }) -join '.') } else { $currentVer }
    $normExpected = (($expectedVer -split '\.' | ForEach-Object { [int]$_ }) -join '.')
    if ($normCurrent -eq $normExpected) { $status = "PASS" } else { $status = "FAIL" }
} catch {
    $status = "FAIL"
    $currentStr = "ERROR: $($_.Exception.Message)"
    $expectedStr = "Realtek USB LAN=$expectedVer"
}
Write-CheckResult -No $checkNo -Name $checkName -Status $status -Current $currentStr -Expected $expectedStr