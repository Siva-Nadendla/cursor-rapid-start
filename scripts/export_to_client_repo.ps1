<#
.SYNOPSIS
    Exports a clean client delivery repo from an internal working repo.

.DESCRIPTION
    Runs the pre-export scan first. If it passes, copies only safe content to a new
    client repo, excluding all Cursor artifacts, secrets, prompts, logs, outputs, and
    raw data. Renders client-facing .gitignore and README from templates.

.PARAMETER SourceRepo
    Path to the internal working repo.

.PARAMETER ClientRepo
    Destination path for the clean client repo (created if missing).

.PARAMETER SkipScan
    Skip the pre-export scan. NOT recommended.

.PARAMETER Force
    Allow export into an existing non-empty client folder.

.EXAMPLE
    .\export_to_client_repo.ps1 -SourceRepo "C:\...\my-project" -ClientRepo "C:\...\my-project-client"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$SourceRepo,

    [Parameter(Mandatory = $true)]
    [string]$ClientRepo,

    [switch]$SkipScan,

    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$frameworkRoot = Split-Path -Parent $PSScriptRoot
$templatesDir = Join-Path $frameworkRoot "templates"

if (-not (Test-Path -LiteralPath $SourceRepo)) {
    throw "SourceRepo not found: $SourceRepo"
}
$sourceRoot = (Resolve-Path -LiteralPath $SourceRepo).Path

# 1) Safety gate
if (-not $SkipScan) {
    $scan = Join-Path $PSScriptRoot "scan_before_export.ps1"
    if (-not (Test-Path -LiteralPath $scan)) {
        throw "scan_before_export.ps1 not found; cannot verify safety. Aborting."
    }
    Write-Host "Running pre-export scan..."
    & $scan -SourceRepo $sourceRoot
    if ($LASTEXITCODE -ne 0) {
        throw "Pre-export scan failed. Resolve findings or re-run with explicit -SkipScan (not recommended). Aborting export."
    }
    Write-Host ""
}
else {
    Write-Warning "Pre-export scan SKIPPED by request."
}

# 2) Prepare destination
if (Test-Path -LiteralPath $ClientRepo) {
    $existing = Get-ChildItem -LiteralPath $ClientRepo -Force | Where-Object { $_.Name -ne ".git" }
    if ($existing -and (-not $Force)) {
        throw "Client repo exists and is not empty: $ClientRepo (use -Force to proceed)"
    }
}
else {
    New-Item -ItemType Directory -Path $ClientRepo -Force | Out-Null
}
$clientRoot = (Resolve-Path -LiteralPath $ClientRepo).Path

# 3) Exclusion rules (defense in depth even though scan passed)
$excludeDirNames = @(".git", ".cursor", "prompts", "logs", "outputs", "output", "data", "raw", "tmp", "temp", "secrets", "credentials", ".venv", "venv", "env", "__pycache__", ".pytest_cache", ".mypy_cache", ".ruff_cache", ".idea", ".vscode")
$excludeFileGlobs = @("*.env", ".env", ".env.*", "*.key", "*.pem", "*.pfx", "*.p12", "*.crt", "*.cer", "README_INTERNAL.md", ".cursorignore", ".cursorindexingignore", "*.log", "*.pyc")

function Test-Excluded {
    param([System.IO.FileSystemInfo]$Item)

    # Exclude if any path segment matches an excluded directory name
    $relative = $Item.FullName.Substring($sourceRoot.Length).TrimStart('\')
    $segments = $relative -split '\\'
    foreach ($seg in $segments) {
        if ($excludeDirNames -contains $seg) { return $true }
    }
    if (-not $Item.PSIsContainer) {
        foreach ($glob in $excludeFileGlobs) {
            if ($Item.Name -like $glob) { return $true }
        }
    }
    return $false
}

$copied = @()
$excluded = @()

$items = Get-ChildItem -LiteralPath $sourceRoot -Recurse -Force
foreach ($item in $items) {
    if (Test-Excluded -Item $item) {
        $excluded += $item.FullName
        continue
    }
    $relative = $item.FullName.Substring($sourceRoot.Length).TrimStart('\')
    $dest = Join-Path $clientRoot $relative
    if ($item.PSIsContainer) {
        if (-not (Test-Path -LiteralPath $dest)) {
            New-Item -ItemType Directory -Path $dest -Force | Out-Null
        }
    }
    else {
        $destDir = Split-Path -Parent $dest
        if (-not (Test-Path -LiteralPath $destDir)) {
            New-Item -ItemType Directory -Path $destDir -Force | Out-Null
        }
        Copy-Item -LiteralPath $item.FullName -Destination $dest -Force
        $copied += $relative
    }
}

# 4) Render client-facing .gitignore and README from templates (overwrite intentionally)
$clientGitignoreSrc = Join-Path $templatesDir "gitignore_client.template"
if (Test-Path -LiteralPath $clientGitignoreSrc) {
    Copy-Item -LiteralPath $clientGitignoreSrc -Destination (Join-Path $clientRoot ".gitignore") -Force
    Write-Host "Wrote client .gitignore"
}

$clientReadmeSrc = Join-Path $templatesDir "README_CLIENT.template.md"
if (Test-Path -LiteralPath $clientReadmeSrc) {
    $clientReadmeDest = Join-Path $clientRoot "README.md"
    $projName = Split-Path -Leaf $clientRoot
    (Get-Content -LiteralPath $clientReadmeSrc -Raw).Replace("<PROJECT_NAME>", $projName) |
        Set-Content -LiteralPath $clientReadmeDest -Encoding UTF8
    Write-Host "Wrote client README.md"
}

# 5) Manifest
Write-Host ""
Write-Host "Export complete: $clientRoot"
Write-Host "Files copied: $($copied.Count)"
Write-Host "Items excluded: $($excluded.Count)"
Write-Host ""
Write-Host "Excluded (first 30):"
$excluded | Select-Object -First 30 | ForEach-Object { Write-Host "  - $_" }

Write-Host ""
Write-Host "Reminder: verify the client repo before sharing. Run scan against it too:"
Write-Host "  .\scan_before_export.ps1 -SourceRepo `"$clientRoot`""
