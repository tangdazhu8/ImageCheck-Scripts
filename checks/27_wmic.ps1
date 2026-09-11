# === 预期值 ===
$expectedFeatureName = "WMIC"

# === 脚本配置 ===
$checkNo = 27
$checkName = "WMIC功能"

# Check #27: WMIC功能可用
. "$PSScriptRoot\..\common.ps1"
$ErrorActionPreference = 'Stop'
try {
    $wmicPath = Get-Command wmic -ErrorAction SilentlyContinue
    if ($wmicPath) {
        $testOutput = wmic os get caption /format:list 2>&1 | Out-String
        if ($testOutput -match "Caption") {
            $currentStr = "WMIC available at $($wmicPath.Source), functional"
            $status = "PASS"
        } else {
            $currentStr = "WMIC found at $($wmicPath.Source) but not functional: $testOutput"
            $status = "FAIL"
        }
    } else {
        $feature = Get-WindowsOptionalFeature -Online -FeatureName $expectedFeatureName -ErrorAction SilentlyContinue
        if ($feature -and $feature.State -eq "Enabled") {
            $currentStr = "WMIC feature enabled but command not in PATH"
            $status = "PASS"
        } else {
            $currentStr = "WMIC not found"
            $status = "FAIL"
        }
    }
    $expectedStr = "WMIC command available and functional"
} catch {
    $status = "FAIL"
    $currentStr = "ERROR: $($_.Exception.Message)"
    $expectedStr = "WMIC command available and functional"
}
Write-CheckResult -No $checkNo -Name $checkName -Status $status -Current $currentStr -Expected $expectedStr