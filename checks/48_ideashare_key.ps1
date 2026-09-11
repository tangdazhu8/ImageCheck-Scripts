# === 预期值 ===
$expectedKeyPath = "C:\Program Files\IdeaUI\IdeaShareKey"

# === 脚本配置 ===
$checkNo = 48
$checkName = "IdeaShareKey"

# Check #48: IdeaShareKey 导入
. "$PSScriptRoot\..\common.ps1"
$ErrorActionPreference = 'Stop'
try {
    if (Test-Path $expectedKeyPath) {
        $files = Get-ChildItem $expectedKeyPath -ErrorAction SilentlyContinue
        $fileCount = $files.Count
        $currentStr = "Directory exists: $expectedKeyPath, files=$fileCount"
        if ($fileCount -gt 0) {
            $currentStr += ", files: $(($files | Select-Object -First 5).Name -join ', ')"
            $status = "PASS"
        } else {
            $currentStr += " (empty)"
            $status = "FAIL"
        }
    } else {
        $currentStr = "Directory not found: $expectedKeyPath"
        $status = "FAIL"
    }
    $expectedStr = "IdeaShareKey imported to $expectedKeyPath"
} catch {
    $status = "FAIL"
    $currentStr = "ERROR: $($_.Exception.Message)"
    $expectedStr = "IdeaShareKey imported to $expectedKeyPath"
}
Write-CheckResult -No $checkNo -Name $checkName -Status $status -Current $currentStr -Expected $expectedStr