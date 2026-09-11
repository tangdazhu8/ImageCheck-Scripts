# === 预期值 ===
$expectedTargetReleaseVersion = "25H2"
$expectedProductVersion = "Windows 11"

# === 脚本配置 ===
$checkNo = 56
$checkName = "目标功能更新版本"

# Check #56: 目标版本锁定为25H2 - 通过lgpo解析Registry.pol
. "$PSScriptRoot\..\common.ps1"
$ErrorActionPreference = 'Stop'

$lgpoPath = Join-Path $PSScriptRoot "lgpo.exe"
$polPath = "$env:SystemRoot\System32\GroupPolicy\Machine\Registry.pol"

function Get-PolicyValue {
    param([string]$KeyPath, [string]$ValueName)
    $lines = & $lgpoPath /parse /q /m $polPath 2>&1
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
        $expectedStr = "TargetReleaseVersion=1, TargetReleaseVersionInfo=$expectedTargetReleaseVersion, ProductVersion=$expectedProductVersion"
    } elseif (-not (Test-Path $polPath)) {
        $status = "FAIL"
        $currentStr = "Registry.pol not found"
        $expectedStr = "TargetReleaseVersion=1, TargetReleaseVersionInfo=$expectedTargetReleaseVersion, ProductVersion=$expectedProductVersion"
    } else {
        $keyPath = "Software\Policies\Microsoft\Windows\WindowsUpdate"
        $targetRelease = Get-PolicyValue -KeyPath $keyPath -ValueName "TargetReleaseVersion"
        $targetVersionInfo = Get-PolicyValue -KeyPath $keyPath -ValueName "TargetReleaseVersionInfo"
        $productVersion = Get-PolicyValue -KeyPath $keyPath -ValueName "ProductVersion"

        $targetOk = ([int]$targetRelease -eq 1)
        $versionOk = ($targetVersionInfo -eq $expectedTargetReleaseVersion)
        $productOk = ($productVersion -eq $expectedProductVersion)

        $currentStr = "TargetReleaseVersion=$targetRelease, TargetReleaseVersionInfo=$targetVersionInfo, ProductVersion=$productVersion"
        if ($targetOk -and $versionOk -and $productOk) { $status = "PASS" } else { $status = "FAIL" }
        $expectedStr = "TargetReleaseVersion=1, TargetReleaseVersionInfo=$expectedTargetReleaseVersion, ProductVersion=$expectedProductVersion"
    }
} catch {
    $status = "FAIL"
    $currentStr = "ERROR: $($_.Exception.Message)"
    $expectedStr = "TargetReleaseVersion=1, TargetReleaseVersionInfo=$expectedTargetReleaseVersion, ProductVersion=$expectedProductVersion"
}
Write-CheckResult -No $checkNo -Name $checkName -Status $status -Current $currentStr -Expected $expectedStr