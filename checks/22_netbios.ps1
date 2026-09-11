# === 预期值 ===
$expectedNetbiosOption = 2

# === 脚本配置 ===
$checkNo = 22
$checkName = "NetBIOS"

# Check #22: NetBIOS disabled on all active adapters
# Registry: NetBT\Parameters\Interfaces\{GUID}\NetbiosOptions = 2 (disabled)
. "$PSScriptRoot\..\common.ps1"
$ErrorActionPreference = 'Stop'
try {
    $adapters = Get-NetAdapter -ErrorAction SilentlyContinue
    $failAdapters = @()
    $checkedCount = 0

    foreach ($adapter in $adapters) {
        $guid = $adapter.InterfaceGuid
        $nbOption = $null
        # 尝试两种键名格式：{GUID} 和 Tcpip_{GUID}
        $regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters\Interfaces\$guid"
        $nbOption = Get-RegistryValue -Path $regPath -Name "NetbiosOptions"
        if ($null -eq $nbOption) {
            $regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters\Interfaces\Tcpip_$guid"
            $nbOption = Get-RegistryValue -Path $regPath -Name "NetbiosOptions"
        }
        if ($null -ne $nbOption) {
            $checkedCount++
            if ($nbOption -ne $expectedNetbiosOption) {
                $failAdapters += "$($adapter.Name): NetbiosOptions=$nbOption"
            }
        }
    }

    $currentStr = "Checked $checkedCount adapters"
    if ($failAdapters.Count -gt 0) {
        $currentStr += "; FAIL: $($failAdapters -join '; ')"
        $status = "FAIL"
    } elseif ($checkedCount -gt 0) {
        $currentStr += "; All NetBIOS disabled"
        $status = "PASS"
    } else {
        $currentStr += "; No NetBIOS adapters found"
        $status = "PASS"
    }
    $expectedStr = "All adapters: NetbiosOptions=$expectedNetbiosOption (disabled)"
} catch {
    $status = "FAIL"
    $currentStr = "ERROR: $($_.Exception.Message)"
    $expectedStr = "All adapters: NetbiosOptions=$expectedNetbiosOption (disabled)"
}
Write-CheckResult -No $checkNo -Name $checkName -Status $status -Current $currentStr -Expected $expectedStr