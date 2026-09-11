# === 预期值 ===
$expectedExcludedPorts = @(1444, 4999)

# === 脚本配置 ===
$checkNo = 62
$checkName = "TCP端口排除"

# Check #62: 排除TCP端口1444、4999
. "$PSScriptRoot\..\common.ps1"
$ErrorActionPreference = 'Stop'

try {
    $output = netsh int ipv4 show excludedportrange protocol=tcp 2>&1 | Out-String
    $excludedPorts = @()
    $lines = $output -split "`r`n|`n"
    foreach ($line in $lines) {
        if ($line -match '^\s*(\d+)\s+(\d+)') {
            $startPort = [int]$Matches[1]
            $endPort = [int]$Matches[2]
            $excludedPorts += $startPort..$endPort
        }
    }

    $results = @()
    $allOk = $true
    foreach ($port in $expectedExcludedPorts) {
        $found = $excludedPorts -contains $port
        $results += "Port $port=$found"
        if (-not $found) { $allOk = $false }
    }

    $currentStr = $results -join '; '
    if ($allOk) { $status = "PASS" } else { $status = "FAIL" }
    $expectedStr = "Ports $($expectedExcludedPorts -join ', ') excluded"
} catch {
    $status = "FAIL"
    $currentStr = "ERROR: $($_.Exception.Message)"
    $expectedStr = "Ports $($expectedExcludedPorts -join ', ') excluded"
}
Write-CheckResult -No $checkNo -Name $checkName -Status $status -Current $currentStr -Expected $expectedStr