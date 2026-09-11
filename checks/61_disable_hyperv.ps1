# === 预期值 ===
$expectedHyperVState = "Disabled"

# === 脚本配置 ===
$checkNo = 61
$checkName = "关闭Hyper-V"

# Check #61: Hyper-V所有子功能不勾选
. "$PSScriptRoot\..\common.ps1"
$ErrorActionPreference = 'Stop'

try {
    $features = Get-WindowsOptionalFeature -Online | Where-Object { $_.FeatureName -like "*Hyper-V*" }
    if ($features.Count -eq 0) {
        $status = "PASS"
        $currentStr = "No Hyper-V features found"
        $expectedStr = "All Hyper-V features = $expectedHyperVState"
    } else {
        $results = @()
        $allOk = $true
        foreach ($f in $features) {
            $results += "$($f.FeatureName)=$($f.State)"
            if ($f.State -ne $expectedHyperVState) { $allOk = $false }
        }
        $currentStr = $results -join '; '
        if ($allOk) { $status = "PASS" } else { $status = "FAIL" }
        $expectedStr = "All Hyper-V features = $expectedHyperVState"
    }
} catch {
    $status = "FAIL"
    $currentStr = "ERROR: $($_.Exception.Message)"
    $expectedStr = "All Hyper-V features = $expectedHyperVState"
}
Write-CheckResult -No $checkNo -Name $checkName -Status $status -Current $currentStr -Expected $expectedStr