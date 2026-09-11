# === 预期值 ===
$required = @('en-us', 'zh-cn', 'fr-fr', 'de-de', 'es-es', 'ja-jp', 'ru-ru', 'zh-tw', 'pt-pt', 'ar-sa')

# === 脚本配置 ===
$checkNo = 1
$checkName = "语言包"

# Check #1: 语言包 (Language Packs)
. "$PSScriptRoot\..\common.ps1"
$ErrorActionPreference = 'Stop'

$installedLangs = @()
$allDetectedLangs = @()

try {
    $langList = Get-InstalledLanguage -ErrorAction Stop

    foreach ($lang in $langList) {
        $langTag = $lang.LanguageId.ToLower()
        if (-not $langTag) { continue }
        
        $hasPack = $lang.LanguagePacks -and $lang.LanguagePacks.Count -gt 0
        $hasBasic = $lang.LanguageFeatures -and $lang.LanguageFeatures.ToString() -match "BasicTyping"

        if ($hasPack -or $hasBasic) {
            if ($allDetectedLangs -notcontains $langTag) {
                $allDetectedLangs += $langTag
            }
        }
        if ($hasPack -and $hasBasic) {
            if ($installedLangs -notcontains $langTag) {
                $installedLangs += $langTag
            }
        }
    }
} catch {}

$current = if ($installedLangs.Count -gt 0) { ($installedLangs | Sort-Object) -join ', ' } else { 'NOT_FOUND' }
$expected = ($required | Sort-Object) -join ', '

$missing = $required | Where-Object { $_ -notin $installedLangs }
$extra = $allDetectedLangs | Where-Object { $_ -notin $required }

if ($missing.Count -eq 0 -and $extra.Count -eq 0) {
    $status = "PASS"
} else {
    $status = "FAIL"
    $messages = @()
    if ($missing.Count -gt 0) { $messages += "Missing: $(($missing | Sort-Object) -join ', ')" }
    if ($extra.Count -gt 0) { $messages += "Extra: $(($extra | Sort-Object) -join ', ')" }
    $current = ($messages -join ' | ') + " | Found: $current"
}

Write-CheckResult -No $checkNo -Name $checkName -Status $status -Current $current -Expected $expected