# === 预期值 ===
$expectedDeferFeatureUpdates = 1
$expectedDeferPeriodInDays = 0
$expectedPauseFeatureUpdatesStartTime = $null

# === 脚本配置 ===
$checkNo = 57
$checkName = "禁用预览版本推送"

# Check #57: 禁用预览版本推送 - 通过lgpo解析Registry.pol
. "$PSScriptRoot\..\common.ps1"
$ErrorActionPreference = 'Stop'

$lgpoPath = Join-Path $PSScriptRoot "lgpo.exe"
$polPath = "$env:SystemRoot\System32\GroupPolicy\Machine\Registry.pol"

function Get-PolicyValue {
    param([string]$KeyPath, [string]$ValueName)
    $lines = & $lgpoPath /parse /q /m $polPath 2>&1
    $foundKey = $false
    for ($i = 0; $i -lt $lines.Count - 2; $i++) {
        if ($lines[$i] -eq "Computer" -and $lines[$i+1] -eq $KeyPath -and $lines[$i+2] -eq $ValueName) {
            $valLine = $lines[$i+3]
            if ($valLine -match '^[A-Z]+:(.+)$') {
                return $Matches[1]
            }
        }
    }
    return $null
}

try {
    if (-not (Test-Path $lgpoPath)) {
        $status = "FAIL"
        $currentStr = "lgpo.exe not found"
        $expectedStr = "DeferFeatureUpdates=${expectedDeferFeatureUpdates}, DeferFeatureUpdatesPeriodInDays=${expectedDeferPeriodInDays}, PauseFeatureUpdatesStartTime=空"
    } elseif (-not (Test-Path $polPath)) {
        $status = "FAIL"
        $currentStr = "Registry.pol not found"
        $expectedStr = "DeferFeatureUpdates=${expectedDeferFeatureUpdates}, DeferFeatureUpdatesPeriodInDays=${expectedDeferPeriodInDays}, PauseFeatureUpdatesStartTime=空"
    } else {
        $keyPath = "Software\Policies\Microsoft\Windows\WindowsUpdate"
        $deferFeature = Get-PolicyValue -KeyPath $keyPath -ValueName "DeferFeatureUpdates"
        $deferPeriod = Get-PolicyValue -KeyPath $keyPath -ValueName "DeferFeatureUpdatesPeriodInDays"
        $pauseStart = Get-PolicyValue -KeyPath $keyPath -ValueName "PauseFeatureUpdatesStartTime"

        $deferOk = ([int]$deferFeature -eq $expectedDeferFeatureUpdates)
        $periodOk = ([int]$deferPeriod -eq $expectedDeferPeriodInDays)
        $pauseOk = ($null -eq $pauseStart -or $pauseStart -eq "")

        $currentStr = "DeferFeatureUpdates=$deferFeature, DeferFeatureUpdatesPeriodInDays=$deferPeriod, PauseFeatureUpdatesStartTime=$pauseStart"
        if ($deferOk -and $periodOk -and $pauseOk) { $status = "PASS" } else { $status = "FAIL" }
        $expectedStr = "DeferFeatureUpdates=${expectedDeferFeatureUpdates}, DeferFeatureUpdatesPeriodInDays=${expectedDeferPeriodInDays}, PauseFeatureUpdatesStartTime=空"
    }
} catch {
    $status = "FAIL"
    $currentStr = "ERROR: $($_.Exception.Message)"
    $expectedStr = "DeferFeatureUpdates=${expectedDeferFeatureUpdates}, DeferFeatureUpdatesPeriodInDays=${expectedDeferPeriodInDays}, PauseFeatureUpdatesStartTime=空"
}
Write-CheckResult -No $checkNo -Name $checkName -Status $status -Current $currentStr -Expected $expectedStr