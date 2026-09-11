# check_all.ps1 - Image Checklist Audit Main Orchestrator
# Usage:
#   .\check_all.ps1              # Run all checks
#   .\check_all.ps1 -CheckNo 16  # Run specific check only
#   .\check_all.ps1 -Verbose     # Run with verbose output

param(
    [int]$CheckNo = -1
)

# Save original encodings (to restore at the end, avoiding garbled output in parent session)
$origOutputEnc = [Console]::OutputEncoding
$origInputEnc = [Console]::InputEncoding
$origOutputVar = $OutputEncoding

# Set UTF-8 for JSON output with Chinese characters
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$ErrorActionPreference = 'Continue'
$scriptDir = $PSScriptRoot
$checksDir = Join-Path $scriptDir "checks"

# Collect all check scripts
$allScripts = Get-ChildItem -Path $checksDir -Filter "*.ps1" | Sort-Object Name

if ($CheckNo -ge 0) {
    # Run specific check
    $prefix = "{0:D2}" -f $CheckNo
    $targetScript = $allScripts | Where-Object { $_.Name -match "^$prefix" }
    if ($targetScript) {
        $allScripts = @($targetScript)
    } else {
        Write-Host "ERROR: Check #$CheckNo not found" -ForegroundColor Red
        # Restore encoding before exit
        [Console]::OutputEncoding = $origOutputEnc
        [Console]::InputEncoding = $origInputEnc
        $OutputEncoding = $origOutputVar
        exit 1
    }
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Decenta-Huawei Image Checklist Audit" -ForegroundColor Cyan
Write-Host "  $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

$results = @()
$passCount = 0
$failCount = 0
$manualCount = 0
$skipCount = 0

foreach ($script in $allScripts) {
    try {
        $output = & $script.FullName 2>&1 | Out-String
        # Parse JSON output (may contain multiple lines, find the JSON line)
        $jsonLine = $output -split "`n" | Where-Object { $_ -match '^\s*\{' } | Select-Object -First 1
        if ($jsonLine) {
            $result = $jsonLine | ConvertFrom-Json
            $results += $result

            # Color output based on status
            $statusIcon = switch ($result.status) {
                "PASS"   { "[PASS]" }
                "FAIL"   { "[FAIL]" }
                "MANUAL" { "[MANUAL]" }
                "SKIP"   { "[SKIP]" }
                default  { "[????]" }
            }

            $color = switch ($result.status) {
                "PASS"   { "Green" }
                "FAIL"   { "Red" }
                "MANUAL" { "Yellow" }
                "SKIP"   { "Gray" }
                default  { "White" }
            }

            Write-Host "$statusIcon #$($result.no) $($result.name)" -ForegroundColor $color -NoNewline
            Write-Host " | Current: $($result.current)" -ForegroundColor White

            if ($result.status -eq "FAIL") {
                Write-Host "       Expected: $($result.expected)" -ForegroundColor DarkYellow
            }

            switch ($result.status) {
                "PASS"   { $passCount++ }
                "FAIL"   { $failCount++ }
                "MANUAL" { $manualCount++ }
                "SKIP"   { $skipCount++ }
            }
        } else {
            Write-Host "[ERROR] $($script.Name) - No JSON output" -ForegroundColor Red
            $failCount++
        }
    } catch {
        Write-Host "[ERROR] $($script.Name) - $($_.Exception.Message)" -ForegroundColor Red
        $failCount++
    }
}

# Summary
$totalCount = $passCount + $failCount + $manualCount + $skipCount
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Summary / 审计汇总" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Total / 总计: $totalCount" -ForegroundColor White
Write-Host "  PASS / 通过:    $passCount" -ForegroundColor Green
Write-Host "  FAIL / 失败:    $failCount" -ForegroundColor Red
Write-Host "  MANUAL / 手动:  $manualCount" -ForegroundColor Yellow
Write-Host "  SKIP / 跳过:    $skipCount" -ForegroundColor Gray
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

if ($failCount -gt 0) {
    Write-Host "Failed checks / 失败项:" -ForegroundColor Red
    $results | Where-Object { $_.status -eq "FAIL" } | ForEach-Object {
        Write-Host "  #$($_.no) $($_.name): $($_.current)" -ForegroundColor DarkYellow
        Write-Host "    Expected: $($_.expected)" -ForegroundColor DarkGray
    }
    Write-Host ""
}

# Restore original encodings (critical: prevents garbled output in parent PowerShell session)
[Console]::OutputEncoding = $origOutputEnc
[Console]::InputEncoding = $origInputEnc
$OutputEncoding = $origOutputVar

exit $(if ($failCount -gt 0) { 1 } else { 0 })
