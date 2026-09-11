# === 预期值 ===
$expectedRequireSign = 1
$expectedEnableSign = 1

# === 脚本配置 ===
$checkNo = 18
$checkName = "SMB数字签名"

# Check #18: SMB数字签名（组策略判定）
. "$PSScriptRoot\..\common.ps1"
$ErrorActionPreference = 'Stop'
try {
    $tempFile = Join-Path $env:TEMP "secedit_export_$PID.inf"
    secedit /export /areas SECURITYPOLICY /cfg $tempFile | Out-Null

    if (-not (Test-Path $tempFile)) {
        throw "secedit export failed"
    }

    $content = Get-Content $tempFile -Raw
    Remove-Item $tempFile -Force -ErrorAction SilentlyContinue

    $pat = 'MACHINE\\System\\CurrentControlSet\\Services\\LanManServer\\Parameters\\RequireSecuritySignature\s*=\s*4,(\d+)'
    $srvSign = if ($content -match $pat) { [int]$Matches[1] } else { $null }

    $pat2 = 'MACHINE\\System\\CurrentControlSet\\Services\\LanManServer\\Parameters\\EnableSecuritySignature\s*=\s*4,(\d+)'
    $wksSign = if ($content -match $pat2) { [int]$Matches[1] } else { $null }

    $currentStr = "RequireSecuritySignature=$srvSign, EnableSecuritySignature=$wksSign"
    $expectedStr = "RequireSecuritySignature=$expectedRequireSign, EnableSecuritySignature=$expectedEnableSign"

    if ($srvSign -eq $expectedRequireSign -and $wksSign -eq $expectedEnableSign) {
        $status = "PASS"
    } else {
        $status = "FAIL"
    }
} catch {
    $status = "FAIL"
    $currentStr = "ERROR: $($_.Exception.Message)"
    $expectedStr = "RequireSecuritySignature=$expectedRequireSign, EnableSecuritySignature=$expectedEnableSign"
}
Write-CheckResult -No $checkNo -Name $checkName -Status $status -Current $currentStr -Expected $expectedStr