# === 预期值 ===
$expectedAUOptions = 3
$expectedAutomaticMaintenanceEnabled = 0
$expectedScheduledInstallDay = 0
$expectedScheduledInstallTime = 3
$expectedScheduledInstallEveryWeek = 1
$expectedScheduledInstallFirstWeek = 0
$expectedScheduledInstallSecondWeek = 0
$expectedScheduledInstallThirdWeek = 0
$expectedScheduledInstallFourthWeek = 0
$expectedAllowMUUpdateService = 0

# === 脚本配置 ===
$checkNo = 58
$checkName = "自动更新配置"

# Check #58: 自动更新安全补丁 - 每天03:00 - 通过lgpo解析Registry.pol
. "$PSScriptRoot\..\common.ps1"
$ErrorActionPreference = 'Stop'

$lgpoPath = Join-Path $PSScriptRoot "lgpo.exe"
$polPath = "$env:SystemRoot\System32\GroupPolicy\Machine\Registry.pol"

function Get-PolicyValue {
    param([string]$KeyPath, [string]$ValueName)
    $lines = & $lgpoPath /parse /q /m $polPath 2>&1
    for ($i = 0; $i -lt $lines.Count - 2; $i++) {
        if ($lines[$i] -eq "Computer" -and $lines[$i+1] -eq $KeyPath -and $lines[$i+2] -eq $ValueName) {
            $valLine = $lines[$i+3]
            if ($valLine -match '^[A-Z]+:(.+)$') {
                return $Matches[1]
            }
        }
    }
    return $null
}

try {
    if (-not (Test-Path $lgpoPath)) {
        $status = "FAIL"
        $currentStr = "lgpo.exe not found"
        $expectedStr = "AUOptions=${expectedAUOptions}, ScheduledInstallDay=${expectedScheduledInstallDay}, ScheduledInstallTime=${expectedScheduledInstallTime}, AutomaticMaintenanceEnabled=${expectedAutomaticMaintenanceEnabled}, EveryWeek=${expectedScheduledInstallEveryWeek}, FirstWeek=${expectedScheduledInstallFirstWeek}, SecondWeek=${expectedScheduledInstallSecondWeek}, ThirdWeek=${expectedScheduledInstallThirdWeek}, FourthWeek=${expectedScheduledInstallFourthWeek}, AllowMUUpdateService=${expectedAllowMUUpdateService}"
    } elseif (-not (Test-Path $polPath)) {
        $status = "FAIL"
        $currentStr = "Registry.pol not found"
        $expectedStr = "AUOptions=${expectedAUOptions}, ScheduledInstallDay=${expectedScheduledInstallDay}, ScheduledInstallTime=${expectedScheduledInstallTime}, AutomaticMaintenanceEnabled=${expectedAutomaticMaintenanceEnabled}, EveryWeek=${expectedScheduledInstallEveryWeek}, FirstWeek=${expectedScheduledInstallFirstWeek}, SecondWeek=${expectedScheduledInstallSecondWeek}, ThirdWeek=${expectedScheduledInstallThirdWeek}, FourthWeek=${expectedScheduledInstallFourthWeek}, AllowMUUpdateService=${expectedAllowMUUpdateService}"
    } else {
        $auKeyPath = "Software\Policies\Microsoft\Windows\WindowsUpdate\AU"

        $auOptions = Get-PolicyValue -KeyPath $auKeyPath -ValueName "AUOptions"
        $scheduledDay = Get-PolicyValue -KeyPath $auKeyPath -ValueName "ScheduledInstallDay"
        $scheduledTime = Get-PolicyValue -KeyPath $auKeyPath -ValueName "ScheduledInstallTime"
        $autoMaintenance = Get-PolicyValue -KeyPath $auKeyPath -ValueName "AutomaticMaintenanceEnabled"
        $firstWeek = Get-PolicyValue -KeyPath $auKeyPath -ValueName "ScheduledInstallFirstWeek"
        $secondWeek = Get-PolicyValue -KeyPath $auKeyPath -ValueName "ScheduledInstallSecondWeek"
        $thirdWeek = Get-PolicyValue -KeyPath $auKeyPath -ValueName "ScheduledInstallThirdWeek"
        $fourthWeek = Get-PolicyValue -KeyPath $auKeyPath -ValueName "ScheduledInstallFourthWeek"
        $installEveryWeek = Get-PolicyValue -KeyPath $auKeyPath -ValueName "ScheduledInstallEveryWeek"
        $allowMU = Get-PolicyValue -KeyPath $auKeyPath -ValueName "AllowMUUpdateService"

        $auOk = ([int]$auOptions -eq $expectedAUOptions)
        $dayOk = ([int]$scheduledDay -eq $expectedScheduledInstallDay)
        $timeOk = ([int]$scheduledTime -eq $expectedScheduledInstallTime)
        $maintenanceOk = ($null -eq $autoMaintenance -or [int]$autoMaintenance -eq $expectedAutomaticMaintenanceEnabled)
        $firstWeekOk = ($null -eq $firstWeek -or [int]$firstWeek -eq $expectedScheduledInstallFirstWeek)
        $secondWeekOk = ($null -eq $secondWeek -or [int]$secondWeek -eq $expectedScheduledInstallSecondWeek)
        $thirdWeekOk = ($null -eq $thirdWeek -or [int]$thirdWeek -eq $expectedScheduledInstallThirdWeek)
        $fourthWeekOk = ($null -eq $fourthWeek -or [int]$fourthWeek -eq $expectedScheduledInstallFourthWeek)
        $everyWeekOk = ($null -eq $installEveryWeek -or [int]$installEveryWeek -eq $expectedScheduledInstallEveryWeek)
        $muOk = ($null -eq $allowMU -or [int]$allowMU -eq $expectedAllowMUUpdateService)

        $currentStr = "AUOptions=$auOptions, ScheduledInstallDay=$scheduledDay, ScheduledInstallTime=$scheduledTime, AutomaticMaintenanceEnabled=$autoMaintenance, EveryWeek=$installEveryWeek, FirstWeek=$firstWeek, SecondWeek=$secondWeek, ThirdWeek=$thirdWeek, FourthWeek=$fourthWeek, AllowMUUpdateService=$allowMU"
        if ($auOk -and $dayOk -and $timeOk -and $maintenanceOk -and $everyWeekOk -and $firstWeekOk -and $secondWeekOk -and $thirdWeekOk -and $fourthWeekOk -and $muOk) { $status = "PASS" } else { $status = "FAIL" }
        $expectedStr = "AUOptions=${expectedAUOptions}, ScheduledInstallDay=${expectedScheduledInstallDay}, ScheduledInstallTime=${expectedScheduledInstallTime}, AutomaticMaintenanceEnabled=${expectedAutomaticMaintenanceEnabled}, EveryWeek=${expectedScheduledInstallEveryWeek}, FirstWeek=${expectedScheduledInstallFirstWeek}, SecondWeek=${expectedScheduledInstallSecondWeek}, ThirdWeek=${expectedScheduledInstallThirdWeek}, FourthWeek=${expectedScheduledInstallFourthWeek}, AllowMUUpdateService=${expectedAllowMUUpdateService}"
    }
} catch {
    $status = "FAIL"
    $currentStr = "ERROR: $($_.Exception.Message)"
    $expectedStr = "AUOptions=${expectedAUOptions}, ScheduledInstallDay=${expectedScheduledInstallDay}, ScheduledInstallTime=${expectedScheduledInstallTime}, AutomaticMaintenanceEnabled=${expectedAutomaticMaintenanceEnabled}, EveryWeek=${expectedScheduledInstallEveryWeek}, FirstWeek=${expectedScheduledInstallFirstWeek}, SecondWeek=${expectedScheduledInstallSecondWeek}, ThirdWeek=${expectedScheduledInstallThirdWeek}, FourthWeek=${expectedScheduledInstallFourthWeek}, AllowMUUpdateService=${expectedAllowMUUpdateService}"
}
Write-CheckResult -No $checkNo -Name $checkName -Status $status -Current $currentStr -Expected $expectedStr