# === 预期值 ===
$expectedUsername = "newuser"
$expectedPassword = "123456"

# === 脚本配置 ===
$checkNo = 50
$checkName = "多用户软键盘"

# Check #50: 多用户软键盘（创建测试用户，人工确认）
. "$PSScriptRoot\..\common.ps1"
$ErrorActionPreference = 'Stop'
try {
    $user = Get-LocalUser -Name $expectedUsername -ErrorAction SilentlyContinue
    if (-not $user) {
        $securePassword = ConvertTo-SecureString $expectedPassword -AsPlainText -Force
        New-LocalUser -Name $expectedUsername -Password $securePassword -FullName $expectedUsername -ErrorAction Stop | Out-Null
        Add-LocalGroupMember -Group "Users" -Member $expectedUsername -ErrorAction SilentlyContinue
        $currentStr = "Created user: $expectedUsername, password: $expectedPassword"
    } else {
        $currentStr = "User already exists: $expectedUsername"
    }
    $status = "MANUAL"
    $expectedStr = "User $expectedUsername created, manually verify multi-user touch keyboard"
} catch {
    $status = "FAIL"
    $currentStr = "ERROR: $($_.Exception.Message)"
    $expectedStr = "User $expectedUsername created, manually verify multi-user touch keyboard"
}
Write-CheckResult -No $checkNo -Name $checkName -Status $status -Current $currentStr -Expected $expectedStr