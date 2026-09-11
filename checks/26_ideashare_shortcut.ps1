# === 预期值 ===
$expectedShortcutName = "IdeaShare OPS Server Download.url"
$expectedDesktop = "C:\Users\Public\Desktop"

# === 脚本配置 ===
$checkNo = 26
$checkName = "IdeaShare快捷方式"

# Check #26: IdeaShare OPS Server Download 快捷方式
. "$PSScriptRoot\..\common.ps1"
$ErrorActionPreference = 'Stop'
try {
    $found = $false
    $foundInfo = ""

    if (Test-Path $expectedDesktop) {
        $shortcuts = Get-ChildItem -Path $expectedDesktop -Filter "*.url" -ErrorAction SilentlyContinue
        foreach ($sc in $shortcuts) {
            if ($sc.Name -eq $expectedShortcutName) {
                $shell = New-Object -ComObject WScript.Shell
                $target = $shell.CreateShortcut($sc.FullName).TargetPath
                $found = $true
                $foundInfo = "Found on Public Desktop: $($sc.Name) -> $target"
                break
            }
        }
    }

    if ($found) {
        $currentStr = $foundInfo
        $status = "PASS"
    } else {
        $currentStr = "IdeaShare OPS Server Download shortcut not found on Public Desktop ($expectedDesktop)"
        $status = "FAIL"
    }
    $expectedStr = "Shortcut '$expectedShortcutName' on Public Desktop"
} catch {
    $status = "FAIL"
    $currentStr = "ERROR: $($_.Exception.Message)"
    $expectedStr = "Shortcut '$expectedShortcutName' on Public Desktop"
}
Write-CheckResult -No $checkNo -Name $checkName -Status $status -Current $currentStr -Expected $expectedStr