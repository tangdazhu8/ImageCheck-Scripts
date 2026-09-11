# Check #30: Edge & WebView2 版本
. "$PSScriptRoot\..\common.ps1"
$ErrorActionPreference = 'Stop'

# === 预期值 ===
$expectedEdgeVer = "150.0.4078.83"
# ==============

$checkNo     = 30
$checkName   = "Edge版本"
$expectedStr = "Edge & WebView2 = $expectedEdgeVer"

try {
    $edgePath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
    if (-not (Test-Path $edgePath)) {
        $edgePath = "C:\Program Files\Microsoft\Edge\Application\msedge.exe"
    }
    if (Test-Path $edgePath) {
        $edgeVer = (Get-Item $edgePath).VersionInfo.ProductVersion
    } else {
        $edgeReg = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\msedge.exe" -ErrorAction SilentlyContinue
        if ($edgeReg) {
            $edgeVer = (Get-Item $edgeReg.'(Default)').VersionInfo.ProductVersion
        } else {
            $edgeVer = "NOT_FOUND"
        }
    }

    $wv2Path = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft EdgeWebView"
    $wv2Ver = (Get-ItemProperty $wv2Path -ErrorAction SilentlyContinue).DisplayVersion
    if (-not $wv2Ver) {
        $wv2Path2 = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}"
        $wv2Ver = (Get-ItemProperty $wv2Path2 -ErrorAction SilentlyContinue).pv
    }
    if (-not $wv2Ver) {
        $wv2Path3 = "HKLM:\SOFTWARE\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}"
        $wv2Ver = (Get-ItemProperty $wv2Path3 -ErrorAction SilentlyContinue).pv
    }

    $currentStr = "Edge=$edgeVer, WebView2=$wv2Ver"

    if ($edgeVer -eq $expectedEdgeVer) {
        $status = "PASS"
    } else {
        $status = "FAIL"
    }
} catch {
    $status = "FAIL"
    $currentStr = "ERROR: $($_.Exception.Message)"
}
Write-CheckResult -No $checkNo -Name $checkName -Status $status -Current $currentStr -Expected $expectedStr
