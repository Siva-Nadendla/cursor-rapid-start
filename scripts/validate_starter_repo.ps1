<#
.SYNOPSIS
    Validates the integrity of this cursor_rapid_start framework repo.

.DESCRIPTION
    Checks that all expected folders and files exist, that requirements.txt matches
    the approved minimal dependency set, that no forbidden dependencies are present,
    and that PowerShell scripts parse without syntax errors.

.EXAMPLE
    .\validate_starter_repo.ps1
#>
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$frameworkRoot = Split-Path -Parent $PSScriptRoot
Write-Host "Validating framework repo: $frameworkRoot"
Write-Host ""

$errors = @()
$ok = @()

function Test-Required {
    param([string]$RelativePath)
    $full = Join-Path $frameworkRoot $RelativePath
    if (Test-Path -LiteralPath $full) {
        $script:ok += $RelativePath
    }
    else {
        $script:errors += "MISSING: $RelativePath"
    }
}

$expected = @(
    "README.md",
    ".gitignore",
    "requirements.txt",
    "prompts\01_start_new_internal_project.md",
    "prompts\02_prepare_client_delivery.md",
    "prompts\03_review_before_export.md",
    "prompts\04_cloud_access_guardrails.md",
    "prompts\05_apply_cursor_rules.md",
    "templates\gitignore_internal.template",
    "templates\gitignore_client.template",
    "templates\env.example.template",
    "templates\config.yaml.template",
    "templates\requirements.txt.template",
    "templates\README_INTERNAL.template.md",
    "templates\README_CLIENT.template.md",
    "cursor-rules-standard\00_working_model.mdc",
    "cursor-rules-standard\01_security_and_secrets.mdc",
    "cursor-rules-standard\02_python_project_setup.mdc",
    "cursor-rules-standard\03_client_delivery_boundary.mdc",
    "cursor-rules-standard\04_azure_access_guardrails.mdc",
    "cursor-rules-standard\05_documentation_standards.mdc",
    "scripts\start_internal_project.ps1",
    "scripts\apply_cursor_rules.ps1",
    "scripts\export_to_client_repo.ps1",
    "scripts\scan_before_export.ps1",
    "scripts\validate_starter_repo.ps1",
    "examples\sample_project_startup.json",
    ".cursor\rules\00_cursor_rapid_start_repo.mdc",
    ".cursor\rules\01_script_safety.mdc"
)

foreach ($item in $expected) {
    Test-Required -RelativePath $item
}

# requirements.txt content checks
$reqPath = Join-Path $frameworkRoot "requirements.txt"
if (Test-Path -LiteralPath $reqPath) {
    $reqLines = (Get-Content -LiteralPath $reqPath) | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }
    $expectedDeps = @(
        "streamlit", "fastapi", "uvicorn", "azure-identity",
        "azure-storage-blob", "azure-keyvault-secrets", "python-dotenv", "pyyaml"
    )
    foreach ($dep in $expectedDeps) {
        if ($reqLines -notcontains $dep) {
            $errors += "requirements.txt missing dependency: $dep"
        }
    }
    $forbiddenDeps = @("faiss", "faiss-cpu", "faiss-gpu", "sentence-transformers")
    foreach ($line in $reqLines) {
        foreach ($bad in $forbiddenDeps) {
            if ($line.ToLower() -like "$bad*") {
                $errors += "requirements.txt contains forbidden dependency: $line"
            }
        }
    }
}

# PowerShell script syntax checks
$scriptFiles = Get-ChildItem -LiteralPath (Join-Path $frameworkRoot "scripts") -Filter "*.ps1" -File
foreach ($sf in $scriptFiles) {
    $tokens = $null
    $parseErrors = $null
    [System.Management.Automation.Language.Parser]::ParseFile($sf.FullName, [ref]$tokens, [ref]$parseErrors) | Out-Null
    if ($parseErrors -and $parseErrors.Count -gt 0) {
        foreach ($pe in $parseErrors) {
            $errors += "Syntax error in $($sf.Name): $($pe.Message)"
        }
    }
}

# JSON validity check
$jsonPath = Join-Path $frameworkRoot "examples\sample_project_startup.json"
if (Test-Path -LiteralPath $jsonPath) {
    try {
        Get-Content -LiteralPath $jsonPath -Raw | ConvertFrom-Json | Out-Null
    }
    catch {
        $errors += "Invalid JSON in examples\sample_project_startup.json: $($_.Exception.Message)"
    }
}

# Report
Write-Host "Checks passed: $($ok.Count) of $($expected.Count) required paths present."
if ($errors.Count -eq 0) {
    Write-Host ""
    Write-Host "VALIDATION PASSED" -ForegroundColor Green
    exit 0
}

Write-Host ""
Write-Host "VALIDATION FAILED ($($errors.Count) issue(s)):" -ForegroundColor Red
$errors | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
exit 1
