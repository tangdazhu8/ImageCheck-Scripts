# === 预期值 ===
$expectedHidden = "Yes"

# === 脚本配置 ===
$checkNo = 15
$checkName = "Hidden server"

# Check #15: Hidden server configuration
. "$PSScriptRoot\..\common.ps1"
$ErrorActionPreference = 'Stop'
try {
    Restore-OriginalEncoding
    $output = net config server 2>&1 | Out-String
    Set-Utf8Encoding

    $hiddenVal = "NOT_FOUND"
    $lines = $output -split "`n"
    foreach ($line in $lines) {
        $trimmed = $line.Trim()
        if ($trimmed -match "(?i)(服务器已隐藏|服务器隐藏|Server\s+Hidden)\s+(.+)$") {
            $hiddenVal = $Matches[2].Trim()
            break
        }
        if ($trimmed -match "(?i)(服务器已隐藏|服务器隐藏|Server\s+Hidden)\s*[:=：]\s*(\S+)") {
            $hiddenVal = $Matches[2].Trim()
            break
        }
    }

    $currentStr = "Server Hidden=$hiddenVal"
    $expectedStr = "Server Hidden=$expectedHidden"
    if ($hiddenVal -match "^(Yes|是)") {
        $status = "PASS"
    } else {
        $status = "FAIL"
    }
} catch {
    Set-Utf8Encoding
    $status = "FAIL"
    $currentStr = "ERROR: $($_.Exception.Message)"
    $expectedStr = "Server Hidden=$expectedHidden"
}
Write-CheckResult -No $checkNo -Name $checkName -Status $status -Current $currentStr -Expected $expectedStr