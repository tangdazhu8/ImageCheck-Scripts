# === 预期值 ===
$expectedKB = "KB5100998"

# === 脚本配置 ===
$checkNo = 31
$checkName = ".NET Framework"

# Check #31: .NET Framework 更新
. "$PSScriptRoot\..\common.ps1"
$ErrorActionPreference = 'Stop'
try {
    $hotfix = Get-HotFix -Id $expectedKB -ErrorAction SilentlyContinue
    if ($hotfix) {
        $currentStr = "$expectedKB installed on $($hotfix.InstalledOn)"
        $status = "PASS"
    } else {
        $dotnetKBs = Get-HotFix -ErrorAction SilentlyContinue | Where-Object { $_.HotFixID -match "KB5" -and $_.Description -match "Update" }
        if ($dotnetKBs) {
            $currentStr = "$expectedKB NOT found. Related .NET updates: $(($dotnetKBs | Select-Object -First 5).HotFixID -join ', ')"
        } else {
            $currentStr = "$expectedKB not found"
        }
        $status = "FAIL"
    }
    $expectedStr = "$expectedKB installed"
} catch {
    $status = "FAIL"
    $currentStr = "ERROR: $($_.Exception.Message)"
    $expectedStr = "$expectedKB installed"
}
Write-CheckResult -No $checkNo -Name $checkName -Status $status -Current $currentStr -Expected $expectedStr