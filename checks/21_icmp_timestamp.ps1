# === 预期值 ===
$expectedDirection = "In"
$expectedAction = "Block"
$expectedEnabled = "True"

# === 脚本配置 ===
$checkNo = 21
$checkName = "ICMP Timestamp"

# Check #21: ICMP timestamp response blocked
. "$PSScriptRoot\..\common.ps1"
$ErrorActionPreference = 'Stop'
try {
    $rule = Get-NetFirewallRule -DisplayName "Block Type 13 ICMP V4" -ErrorAction SilentlyContinue
    if ($rule) {
        $direction = $rule.Direction
        $action = $rule.Action
        $enabled = $rule.Enabled
        $currentStr = "Rule=$($rule.DisplayName), Direction=$direction, Action=$action, Enabled=$enabled"
        $expectedStr = "Direction=$expectedDirection, Action=$expectedAction, Enabled=$expectedEnabled"
        if ($direction -eq $expectedDirection -and $action -eq $expectedAction -and $enabled -eq $expectedEnabled) {
            $status = "PASS"
        } else {
            $status = "FAIL"
        }
    } else {
        $currentStr = "Rule not found"
        $expectedStr = "Firewall rule 'Block Type 13 ICMP V4' exists with Action=$expectedAction"
        $status = "FAIL"
    }
} catch {
    $status = "FAIL"
    $currentStr = "ERROR: $($_.Exception.Message)"
    $expectedStr = "Firewall rule 'Block Type 13 ICMP V4' exists with Action=$expectedAction"
}
Write-CheckResult -No $checkNo -Name $checkName -Status $status -Current $currentStr -Expected $expectedStr