# === 预期值 ===
$expectedProductName = "Windows 11"
$expectedEdition = "Enterprise"
$expectedDisplayVer = "25H2"

# === 脚本配置 ===
$checkNo = 53
$checkName = "系统版本"

# Check #53: 系统版本
. "$PSScriptRoot\..\common.ps1"
$ErrorActionPreference = 'Stop'
try {
    $ntPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
    $build = [int](Get-ItemProperty $ntPath -Name "CurrentBuild" -ErrorAction SilentlyContinue).CurrentBuild
    $editionId = (Get-ItemProperty $ntPath -Name "EditionID" -ErrorAction SilentlyContinue).EditionID
    $displayVersion = (Get-ItemProperty $ntPath -Name "DisplayVersion" -ErrorAction SilentlyContinue).DisplayVersion
    $productName = if ($build -ge 22000) { "Windows 11" } else { "Windows 10" }

    $currentStr = "$productName $editionId $displayVersion"
    $expectedStr = "$expectedProductName $expectedEdition $expectedDisplayVer"

    if ($productName -eq $expectedProductName -and $editionId -eq $expectedEdition -and $displayVersion -eq $expectedDisplayVer) {
        $status = "PASS"
    } else {
        $status = "FAIL"
    }
} catch {
    $status = "FAIL"
    $currentStr = "ERROR: $($_.Exception.Message)"
    $expectedStr = "$expectedProductName $expectedEdition $expectedDisplayVer"
}
Write-CheckResult -No $checkNo -Name $checkName -Status $status -Current $currentStr -Expected $expectedStr