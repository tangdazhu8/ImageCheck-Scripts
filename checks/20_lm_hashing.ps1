# === 预期值 ===
$expectedLMLevel = 5
$expectedNtlmSec = 0x20000000

# === 脚本配置 ===
$checkNo = 20
$checkName = "LM Hashing"

# Check #20: Weak Lan Manager hashing
. "$PSScriptRoot\..\common.ps1"
$ErrorActionPreference = 'Stop'
try {
    $lsaPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"
    $msvPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\MSV1_0"

    $lmLevel = Get-RegistryValue -Path $lsaPath -Name "LMCompatibilityLevel"
    $ntlmSrv = Get-RegistryValue -Path $msvPath -Name "NtlmMinServerSec"
    $ntlmCli = Get-RegistryValue -Path $msvPath -Name "NtlmMinClientSec"

    $ntlmSrvInt = if ($null -ne $ntlmSrv) { [int]$ntlmSrv } else { -1 }
    $ntlmCliInt = if ($null -ne $ntlmCli) { [int]$ntlmCli } else { -1 }

    $currentStr = "LMCompatibilityLevel=$lmLevel, NtlmMinServerSec=0x$($ntlmSrvInt.ToString('X')), NtlmMinClientSec=0x$($ntlmCliInt.ToString('X'))"
    $expectedStr = "LMCompatibilityLevel=$expectedLMLevel, NtlmMinServerSec=0x$($expectedNtlmSec.ToString('X')), NtlmMinClientSec=0x$($expectedNtlmSec.ToString('X'))"

    if ($lmLevel -eq $expectedLMLevel -and $ntlmSrvInt -eq $expectedNtlmSec -and $ntlmCliInt -eq $expectedNtlmSec) {
        $status = "PASS"
    } else {
        $status = "FAIL"
    }
} catch {
    $status = "FAIL"
    $currentStr = "ERROR: $($_.Exception.Message)"
    $expectedStr = "LMCompatibilityLevel=$expectedLMLevel, NtlmMinServerSec=0x$($expectedNtlmSec.ToString('X')), NtlmMinClientSec=0x$($expectedNtlmSec.ToString('X'))"
}
Write-CheckResult -No $checkNo -Name $checkName -Status $status -Current $currentStr -Expected $expectedStr