# Check #28: OS Build版本
. "$PSScriptRoot\..\common.ps1"
$ErrorActionPreference = 'Stop'

# === 预期值 ===
$expectedBuild = "26200.8737"
# ==============

$checkNo    = 28
$checkName  = "OS Build"
$regPath    = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
$expectedStr = $expectedBuild

try {
    $osVer = [System.Environment]::OSVersion.Version
    $build = $osVer.Build
    $ubr = (Get-ItemProperty $regPath -Name "UBR" -ErrorAction SilentlyContinue).UBR
    $currentBuild = "$build.$ubr"
    $currentStr = "OS Build=$currentBuild"
    if ($currentBuild -eq $expectedBuild) {
        $status = "PASS"
    } else {
        $status = "FAIL"
    }
} catch {
    $status = "FAIL"
    $currentStr = "ERROR: $($_.Exception.Message)"
}
Write-CheckResult -No $checkNo -Name $checkName -Status $status -Current $currentStr -Expected $expectedStr
