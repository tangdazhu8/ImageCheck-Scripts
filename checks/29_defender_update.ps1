# Check #29: Windows Defender 版本
. "$PSScriptRoot\..\common.ps1"
$ErrorActionPreference = 'Stop'

# === 预期值 ===
$expectedPlatform = "4.18.26060.3008"
$expectedEngine   = "1.1.26060.3008"
$expectedSig      = "1.455.211.0"
# ==============

$checkNo     = 29
$checkName   = "Defender版本"
$expectedStr = "Platform=$expectedPlatform, Engine=$expectedEngine, Signatures=$expectedSig"

try {
    $platformVer = $null
    $engineVer = $null
    $sigVer = $null
    try {
        $mpStatus = Get-MpComputerStatus -ErrorAction Stop
        $platformVer = $mpStatus.AMProductVersion
        $engineVer = $mpStatus.AMEngineVersion
        $sigVer = $mpStatus.AntispywareSignatureVersion
    } catch {}

    if (-not $platformVer) {
        $regPath = "HKLM:\SOFTWARE\Microsoft\Windows Defender"
        $platformVer = (Get-ItemProperty $regPath -ErrorAction SilentlyContinue).AMProductVersion
    }
    if (-not $platformVer) {
        $regPath2 = "HKLM:\SOFTWARE\Microsoft\Windows Defender\AM"
        $platformVer = (Get-ItemProperty $regPath2 -ErrorAction SilentlyContinue).AMProductVersion
    }
    if (-not $platformVer) {
        $mpDll = "C:\Program Files\Windows Defender\MpClient.dll"
        if (Test-Path $mpDll) {
            $platformVer = (Get-Item $mpDll).VersionInfo.ProductVersion
        }
    }

    if (-not $engineVer) {
        $engineVer = (Get-ItemProperty $regPath -ErrorAction SilentlyContinue).AMEngineVersion
    }

    $currentStr = "Platform=$platformVer, Engine=$engineVer, Signatures=$sigVer"

    if ($platformVer -eq $expectedPlatform -and $engineVer -eq $expectedEngine) {
        $status = "PASS"
    } else {
        $status = "FAIL"
    }
} catch {
    $status = "FAIL"
    $currentStr = "ERROR: $($_.Exception.Message)"
}
Write-CheckResult -No $checkNo -Name $checkName -Status $status -Current $currentStr -Expected $expectedStr
