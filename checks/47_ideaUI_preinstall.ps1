# === 预期值 ===
$expectedDevChanVer = "1.1.26.0"
$expectedIdeaUIVer = "25.1.0.48"

# === 脚本配置 ===
$checkNo = 47
$checkName = "IdeaUI预装"

# Check #47: IdeaUI预装（DevChanSvc + IdeaUI_OPS）
. "$PSScriptRoot\..\common.ps1"
$ErrorActionPreference = 'Stop'
try {
    $issues = @()
    $currentStr = ""

    # 检查 DevChanSvc
    $devChanSvc = Get-Service -Name "DevChanSvc" -ErrorAction SilentlyContinue
    if (-not $devChanSvc) {
        $issues += "DevChanSvc service not found"
    } else {
        $devChanPath = (Get-CimInstance Win32_Service -Filter "Name='DevChanSvc'").PathName
        if ($devChanPath -match '"(.+?)"') { $devChanPath = $Matches[1] }
        if ($devChanPath -and (Test-Path $devChanPath)) {
            $devChanVer = (Get-Item $devChanPath).VersionInfo.FileVersion
            $currentStr += "DevChanSvc=$devChanVer"
            if ($devChanVer -ne $expectedDevChanVer) {
                $issues += "DevChanSvc version mismatch: expected $expectedDevChanVer, got $devChanVer"
            }
        } else {
            $currentStr += "DevChanSvc=found(no version)"
            $issues += "DevChanSvc binary not found at $devChanPath"
        }
    }

    # 检查 IdeaUI_OPS
    $ideaUI = Get-WmiObject Win32_Product -Filter "Name LIKE '%IdeaUI_OPS%'" -ErrorAction SilentlyContinue
    if (-not $ideaUI) {
        $ideaUI = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -match "IdeaUI_OPS" } | Select-Object -First 1
    }
    if (-not $ideaUI) {
        $ideaUI = Get-ItemProperty "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -match "IdeaUI_OPS" } | Select-Object -First 1
    }
    if (-not $ideaUI) {
        $issues += "IdeaUI_OPS not found"
        $currentStr += "; IdeaUI_OPS=not found"
    } else {
        $ideaUIVer = $ideaUI.DisplayVersion
        if (-not $ideaUIVer) { $ideaUIVer = $ideaUI.Version }
        $currentStr += "; IdeaUI_OPS=$ideaUIVer"
        if ($ideaUIVer -ne $expectedIdeaUIVer) {
            $issues += "IdeaUI_OPS version mismatch: expected $expectedIdeaUIVer, got $ideaUIVer"
        }
    }

    if ($issues.Count -eq 0) {
        $status = "PASS"
    } else {
        $status = "FAIL"
        $currentStr += " | Issues: $($issues -join '; ')"
    }
    $expectedStr = "DevChanSvc=$expectedDevChanVer, IdeaUI_OPS=$expectedIdeaUIVer"
} catch {
    $status = "FAIL"
    $currentStr = "ERROR: $($_.Exception.Message)"
    $expectedStr = "DevChanSvc=$expectedDevChanVer, IdeaUI_OPS=$expectedIdeaUIVer"
}
Write-CheckResult -No $checkNo -Name $checkName -Status $status -Current $currentStr -Expected $expectedStr