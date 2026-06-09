<#
.SYNOPSIS
    Copies the standard Cursor rule library into a target internal working repo.

.DESCRIPTION
    Copies every *.mdc from cursor-rules-standard/ into <TargetRepo>\.cursor\rules\.
    Internal repos only. Never run this against a client delivery repo.

.PARAMETER TargetRepo
    Path to the internal working repo that should receive the rules.

.PARAMETER Force
    Overwrite existing rule files of the same name.

.EXAMPLE
    .\apply_cursor_rules.ps1 -TargetRepo "C:\Users\SivaK\OneDrive\clientrepos\my-project"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$TargetRepo,

    [switch]$Force
)

# Starter kit workspace safety check
$ExpectedStarterRootName = "cursor-rapid-start"
$StarterCurrentPath = (Get-Location).Path
$StarterCurrentRoot = Split-Path -Leaf $StarterCurrentPath
$StarterMarkerFile = Join-Path $StarterCurrentPath ".cursor_rapid_start_root"

if ($StarterCurrentRoot -ne $ExpectedStarterRootName) {
    Write-Error "Wrong workspace. Expected starter root folder '$ExpectedStarterRootName' but current folder is '$StarterCurrentRoot'. Open cursor-rapid-start and retry."
    exit 1
}

if (!(Test-Path $StarterMarkerFile)) {
    Write-Error "Missing marker file: .cursor_rapid_start_root. This does not appear to be the cursor-rapid-start repo."
    exit 1
}

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$frameworkRoot = Split-Path -Parent $PSScriptRoot
$rulesSource = Join-Path $frameworkRoot "cursor-rules-standard"

if (-not (Test-Path -LiteralPath $rulesSource)) {
    throw "Standard rules folder not found: $rulesSource"
}

if (-not (Test-Path -LiteralPath $TargetRepo)) {
    throw "Target repo not found: $TargetRepo"
}

$targetRulesDir = Join-Path $TargetRepo ".cursor\rules"
if (-not (Test-Path -LiteralPath $targetRulesDir)) {
    New-Item -ItemType Directory -Path $targetRulesDir -Force | Out-Null
    Write-Host "Created $targetRulesDir"
}

$ruleFiles = Get-ChildItem -LiteralPath $rulesSource -Filter "*.mdc" -File
if ($ruleFiles.Count -eq 0) {
    Write-Warning "No .mdc rule files found in $rulesSource"
    return
}

$applied = @()
foreach ($file in $ruleFiles) {
    $dest = Join-Path $targetRulesDir $file.Name
    if ((Test-Path -LiteralPath $dest) -and (-not $Force)) {
        Write-Warning "Skipped (exists, use -Force to overwrite): $($file.Name)"
        continue
    }
    Copy-Item -LiteralPath $file.FullName -Destination $dest -Force
    $applied += $file.Name
    Write-Host "Applied: $($file.Name)"
}

Write-Host ""
Write-Host "Applied $($applied.Count) of $($ruleFiles.Count) rule file(s) to $targetRulesDir"
