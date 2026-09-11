# === 预期值 ===
$expectedRestrictAnon = 1
$expectedAutoShareSrv = 0
$expectedAutoShareWks = 0

# === 脚本配置 ===
$checkNo = 19
$checkName = "默认共享和IPC"

# Check #19: 默认共享和IPC$安全漏洞
. "$PSScriptRoot\..\common.ps1"
$ErrorActionPreference = 'Stop'
try {
    $lsaPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"
    $lanPath = "HKLM:\System\CurrentControlSet\Services\LanmanServer\Parameters"

    $restrictAnon = Get-RegistryValue -Path $lsaPath -Name "RestrictAnonymous"
    $autoShareSrv = Get-RegistryValue -Path $lanPath -Name "AutoShareServer"
    $autoShareWks = Get-RegistryValue -Path $lanPath -Name "AutoShareWks"

    $currentStr = "RestrictAnonymous=$restrictAnon, AutoShareServer=$autoShareSrv, AutoShareWks=$autoShareWks"
    $expectedStr = "RestrictAnonymous=$expectedRestrictAnon, AutoShareServer=$expectedAutoShareSrv, AutoShareWks=$expectedAutoShareWks"

    if ($restrictAnon -eq $expectedRestrictAnon -and $autoShareSrv -eq $expectedAutoShareSrv -and $autoShareWks -eq $expectedAutoShareWks) {
        $status = "PASS"
    } else {
        $status = "FAIL"
    }
} catch {
    $status = "FAIL"
    $currentStr = "ERROR: $($_.Exception.Message)"
    $expectedStr = "RestrictAnonymous=$expectedRestrictAnon, AutoShareServer=$expectedAutoShareSrv, AutoShareWks=$expectedAutoShareWks"
}
Write-CheckResult -No $checkNo -Name $checkName -Status $status -Current $currentStr -Expected $expectedStr