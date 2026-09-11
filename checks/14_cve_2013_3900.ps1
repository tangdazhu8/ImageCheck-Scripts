# === 预期值 ===
$expectedEnableCertPaddingCheck = 1

# === 脚本配置 ===
$checkNo = 14
$checkName = "CVE-2013-3900"

# Check #14: CVE-2013-3900
. "$PSScriptRoot\..\common.ps1"
$ErrorActionPreference = 'Stop'
try {
    $nativePath = "HKLM:\Software\Microsoft\Cryptography\Wintrust\Config"
    $wowPath = "HKLM:\Software\Wow6432Node\Microsoft\Cryptography\Wintrust\Config"

    $nativeVal = Get-RegistryValue -Path $nativePath -Name "EnableCertPaddingCheck"
    $wowVal = Get-RegistryValue -Path $wowPath -Name "EnableCertPaddingCheck"

    $currentStr = "Native EnableCertPaddingCheck=$nativeVal, WOW64 EnableCertPaddingCheck=$wowVal"
    $expectedStr = "EnableCertPaddingCheck=$expectedEnableCertPaddingCheck in both paths"

    if ($nativeVal -eq $expectedEnableCertPaddingCheck -and $wowVal -eq $expectedEnableCertPaddingCheck) {
        $status = "PASS"
    } else {
        $status = "FAIL"
    }
} catch {
    $status = "FAIL"
    $currentStr = "ERROR: $($_.Exception.Message)"
    $expectedStr = "EnableCertPaddingCheck=$expectedEnableCertPaddingCheck in both paths"
}
Write-CheckResult -No $checkNo -Name $checkName -Status $status -Current $currentStr -Expected $expectedStr