# === 预期值 ===
$expectedIgnoreSink = 1

# === 脚本配置 ===
$checkNo = 13
$checkName = "IgnoreSinkScdcRrCapability"

# Check #13: 注册表IgnoreSinkScdcRrCapability值为1
. "$PSScriptRoot\..\common.ps1"
$ErrorActionPreference = 'Stop'
try {
    $path = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000"
    $val = Get-RegistryValue -Path $path -Name "IgnoreSinkScdcRrCapability"
    $currentStr = "IgnoreSinkScdcRrCapability=$val"
    $expectedStr = "IgnoreSinkScdcRrCapability=$expectedIgnoreSink"
    if ($val -eq $expectedIgnoreSink) { $status = "PASS" } else { $status = "FAIL" }
} catch {
    $status = "FAIL"
    $currentStr = "ERROR: $($_.Exception.Message)"
    $expectedStr = "IgnoreSinkScdcRrCapability=$expectedIgnoreSink"
}
Write-CheckResult -No $checkNo -Name $checkName -Status $status -Current $currentStr -Expected $expectedStr