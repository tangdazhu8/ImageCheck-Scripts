# === 预期值 ===
$expectedDiskTimeout = 0
$expectedSleepTimeout = 0
$expectedHibernateTimeout = 0
$expectedDisplayTimeout = 600

# === 脚本配置 ===
$checkNo = 2
$checkName = "电源设置"

# Check #2: 电源设置 - AC: 永不关闭硬盘/睡眠/休眠, 息屏10min
. "$PSScriptRoot\..\common.ps1"
$ErrorActionPreference = 'Stop'
try {
    $diskSubGroup    = "SUB_DISK"
    $diskSetting     = "DISKIDLE"
    $sleepSubGroup   = "SUB_SLEEP"
    $sleepSetting    = "STANDBYIDLE"
    $hibernateSetting = "HIBERNATEIDLE"
    $videoSubGroup   = "SUB_VIDEO"
    $videoSetting    = "VIDEOIDLE"

    $results = @()

    $diskAC = Get-PowerSettingValue -SubGroupGuid $diskSubGroup -SettingGuid $diskSetting -AcDc "AC"
    $results += "Disk AC=${diskAC}s"

    $sleepAC = Get-PowerSettingValue -SubGroupGuid $sleepSubGroup -SettingGuid $sleepSetting -AcDc "AC"
    $results += "Sleep AC=${sleepAC}s"

    $hibAC = Get-PowerSettingValue -SubGroupGuid $sleepSubGroup -SettingGuid $hibernateSetting -AcDc "AC"
    $results += "Hibernate AC=${hibAC}s"

    $videoAC = Get-PowerSettingValue -SubGroupGuid $videoSubGroup -SettingGuid $videoSetting -AcDc "AC"
    $results += "Display AC=${videoAC}s"

    $currentStr = $results -join '; '
    $diskOk = ($diskAC -eq $expectedDiskTimeout)
    $sleepOk = ($sleepAC -eq $expectedSleepTimeout)
    $hibOk = ($hibAC -eq $expectedHibernateTimeout)
    $displayOk = ($videoAC -eq $expectedDisplayTimeout)

    if ($diskOk -and $sleepOk -and $hibOk -and $displayOk) { $status = "PASS" } else { $status = "FAIL" }
    $expectedStr = "Disk=${expectedDiskTimeout}s, Sleep=${expectedSleepTimeout}s, Hibernate=${expectedHibernateTimeout}s, Display=${expectedDisplayTimeout}s"
} catch {
    $status = "FAIL"
    $currentStr = "ERROR: $($_.Exception.Message)"
    $expectedStr = "Disk=${expectedDiskTimeout}s, Sleep=${expectedSleepTimeout}s, Hibernate=${expectedHibernateTimeout}s, Display=${expectedDisplayTimeout}s"
}
Write-CheckResult -No $checkNo -Name $checkName -Status $status -Current $currentStr -Expected $expectedStr