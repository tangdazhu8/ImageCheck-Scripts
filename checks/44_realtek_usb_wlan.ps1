# === 预期值 ===
$expectedVer = "1030.52.731.2025"

# === 脚本配置 ===
$checkNo = 44
$checkName = "Realtek USB WLAN驱动"

# Check #44: Realtek USB WLAN 驱动版本
. "$PSScriptRoot\..\common.ps1"
$ErrorActionPreference = 'Stop'
try {
    $currentVer = $null
    $currentStr = $null
    $drv = Get-WmiObject Win32_PnPSignedDriver | Where-Object { $_.DeviceName -match "Realtek" -and $_.DeviceName -match "USB" -and ($_.DeviceName -match "WLAN" -or $_.DeviceName -match "Wireless" -or $_.DeviceName -match "Wi-Fi") } | Select-Object -First 1
    if ($drv) {
        $currentVer = $drv.DriverVersion
        $currentStr = "Realtek USB WLAN=$($drv.DeviceName), version=$currentVer"
    } else {
        $latestDir = Get-ChildItem "$env:SystemRoot\System32\DriverStore\FileRepository\netrtwlanu*" -Directory -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if ($latestDir) {
            $infFile = Join-Path $latestDir.FullName "netrtwlanu.inf"
            if (Test-Path $infFile) {
                $infContent = Get-Content $infFile -ErrorAction SilentlyContinue
                $match = $infContent | Select-String -Pattern 'DriverVer\s*=\s*\d{2}/\d{2}/\d{4},(.+)' | Select-Object -First 1
                if ($match) {
                    $currentVer = $match.Matches[0].Groups[1].Value.Trim()
                    $currentStr = "Realtek USB WLAN=$currentVer (from INF)"
                }
            }
        }
        if (-not $currentVer) {
            $currentVer = "NOT_FOUND"
            $currentStr = "Realtek USB WLAN driver not found"
        }
    }
    $expectedStr = "Realtek USB WLAN=$expectedVer"
    $normCurrent = if ($currentVer -match '^\d+(\.\d+)+$') { (($currentVer -split '\.' | ForEach-Object { [int]$_ }) -join '.') } else { $currentVer }
    $normExpected = (($expectedVer -split '\.' | ForEach-Object { [int]$_ }) -join '.')
    if ($normCurrent -eq $normExpected) { $status = "PASS" } else { $status = "FAIL" }
} catch {
    $status = "FAIL"
    $currentStr = "ERROR: $($_.Exception.Message)"
    $expectedStr = "Realtek USB WLAN=$expectedVer"
}
Write-CheckResult -No $checkNo -Name $checkName -Status $status -Current $currentStr -Expected $expectedStr