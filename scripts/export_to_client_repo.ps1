<#
.SYNOPSIS
    Copies ONLY approved deliverables from an internal repo to a client repo.

.DESCRIPTION
    Uses an explicit ALLOWLIST so nothing leaks by accident. Runs the pre-export scan
    first and aborts if it fails. A BLOCKLIST is applied as defense-in-depth while
    copying directory contents.

    Allowed (top-level):
      src, pipelines, scripts, docs, requirements.txt, config.yaml, README.md, .env.example
    Blocked (never copied):
      .cursor, .env, logs, outputs, data/raw, secrets, credentials, .venv, venv, __pycache__

    Non-destructive: creates/overwrites only inside the client repo, never deletes from source.

.PARAMETER SourceRepo
    Path to the internal working repo.

.PARAMETER ClientRepo
    Destination path for the clean client repo (created if missing).

.PARAMETER SkipScan
    Skip the post-export verification scan of the client repo. NOT recommended.

.PARAMETER Force
    Overwrite existing files in the client repo.

.EXAMPLE
    .\export_to_client_repo.ps1 -SourceRepo "C:\...\acme-internal" -ClientRepo "C:\...\acme-client"
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
$templatesDir = Join-Path $frameworkRoot "templates"

if (-not (Test-Path -LiteralPath $SourceRepo)) {
    throw "SourceRepo not found: $SourceRepo"
}
$sourceRoot = (Resolve-Path -LiteralPath $SourceRepo).Path

# --- Allow / block definitions ---------------------------------------------------
$allowedDirs = @("src", "pipelines", "scripts", "docs")
$allowedFiles = @("requirements.txt", "config.yaml", "README.md", ".env.example")

# Names that must NEVER be copied, even if nested inside an allowed directory.
$blockedNames = @(".cursor", ".env", "logs", "outputs", "raw", "secrets", "credentials", ".venv", "venv", "__pycache__")
$blockedFileGlobs = @(".env", "*.env", ".env.*", "*.key", "*.pem", "*.pfx", "*.p12", "*.crt", "*.cer", "*.log", "*.pyc")

# NOTE: The internal source repo legitimately contains .cursor, logs, outputs, and
# data/raw, so we do NOT scan it here. Instead, the CLEAN client repo is scanned
# after copying (step 8) to verify nothing forbidden leaked through.

# --- 1) Prepare destination ------------------------------------------------------
if (Test-Path -LiteralPath $ClientRepo) {
    $existing = Get-ChildItem -LiteralPath $ClientRepo -Force | Where-Object { $_.Name -ne ".git" }
    if ($existing -and (-not $Force)) {
        Write-Warning "Client repo exists and is not empty: $ClientRepo. Existing files are kept unless -Force."
    }
}
else {
    New-Item -ItemType Directory -Path $ClientRepo -Force | Out-Null
}
$clientRoot = (Resolve-Path -LiteralPath $ClientRepo).Path

# --- Helper: is any path segment blocked? ---------------------------------------
function Test-Blocked {
    param([System.IO.FileSystemInfo]$Item)
    $relative = $Item.FullName.Substring($sourceRoot.Length).TrimStart('\')
    $segments = $relative -split '\\'
    foreach ($seg in $segments) {
        if ($blockedNames -contains $seg) { return $true }
    }
    if (-not $Item.PSIsContainer) {
        foreach ($glob in $blockedFileGlobs) {
            if ($Item.Name -like $glob) { return $true }
        }
    }
    return $false
}

# --- Helper: copy a single file respecting -Force --------------------------------
function Copy-FileSafe {
    param([string]$SourcePath, [string]$DestPath)
    if ((Test-Path -LiteralPath $DestPath) -and (-not $Force)) {
        Write-Warning "  Skipped (exists, use -Force): $DestPath"
        return $false
    }
    $destDir = Split-Path -Parent $DestPath
    if (-not (Test-Path -LiteralPath $destDir)) {
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    }
    Copy-Item -LiteralPath $SourcePath -Destination $DestPath -Force
    return $true
}

$copied = @()
$skipped = @()

# --- 3) Copy allowed directories (with blocklist filtering) ----------------------
foreach ($dirName in $allowedDirs) {
    $srcDir = Join-Path $sourceRoot $dirName
    if (-not (Test-Path -LiteralPath $srcDir)) {
        Write-Host "  (allowed dir not present, skipping): $dirName"
        continue
    }
    $items = Get-ChildItem -LiteralPath $srcDir -Recurse -Force
    foreach ($item in $items) {
        if (Test-Blocked -Item $item) {
            $skipped += $item.FullName
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
            if (Copy-FileSafe -SourcePath $item.FullName -DestPath $dest) {
                $copied += $relative
            }
        }
    }
}

# --- 4) Copy allowed top-level files --------------------------------------------
foreach ($fileName in $allowedFiles) {
    $srcFile = Join-Path $sourceRoot $fileName
    if (-not (Test-Path -LiteralPath $srcFile)) {
        Write-Host "  (allowed file not present, skipping): $fileName"
        continue
    }
    $dest = Join-Path $clientRoot $fileName
    if (Copy-FileSafe -SourcePath $srcFile -DestPath $dest) {
        $copied += $fileName
    }
}

# --- 5) Ensure client-facing .gitignore + README come from client templates -----
$clientGitignoreSrc = Join-Path $templatesDir "gitignore_client.template"
if (Test-Path -LiteralPath $clientGitignoreSrc) {
    Copy-Item -LiteralPath $clientGitignoreSrc -Destination (Join-Path $clientRoot ".gitignore") -Force
    Write-Host "  Wrote client .gitignore"
}
$clientReadmeSrc = Join-Path $templatesDir "README_CLIENT.template.md"
if (Test-Path -LiteralPath $clientReadmeSrc) {
    $projName = Split-Path -Leaf $clientRoot
    (Get-Content -LiteralPath $clientReadmeSrc -Raw).Replace("<PROJECT_NAME>", $projName) |
        Set-Content -LiteralPath (Join-Path $clientRoot "README.md") -Encoding UTF8
    Write-Host "  Wrote client README.md (from client template)"
}

# --- 6) Final safety assertion ---------------------------------------------------
$leakChecks = @(".cursor", ".env", "logs", "outputs", (Join-Path "data" "raw"))
foreach ($leak in $leakChecks) {
    $leakPath = Join-Path $clientRoot $leak
    if (Test-Path -LiteralPath $leakPath) {
        throw "SAFETY: forbidden artifact present in client repo: $leakPath"
    }
}

# --- 7) Post-export verification scan of the CLIENT repo -------------------------
if (-not $SkipScan) {
    $scan = Join-Path $PSScriptRoot "scan_before_export.ps1"
    if (-not (Test-Path -LiteralPath $scan)) {
        throw "scan_before_export.ps1 not found; cannot verify client repo. Aborting."
    }
    Write-Host ""
    Write-Host "Verifying client repo is clean..."
    & $scan -SourceRepo $clientRoot
    if ($LASTEXITCODE -ne 0) {
        throw "Client repo verification scan FAILED. Inspect findings above; client repo is NOT safe to share."
    }
}
else {
    Write-Warning "Post-export verification scan SKIPPED by request."
}

# --- 8) Manifest -----------------------------------------------------------------
Write-Host ""
Write-Host "Export complete: $clientRoot"
Write-Host "Files copied : $($copied.Count)"
Write-Host "Items blocked: $($skipped.Count)"
if ($skipped.Count -gt 0) {
    Write-Host ""
    Write-Host "Blocked (first 30):"
    $skipped | Select-Object -First 30 | ForEach-Object { Write-Host "  - $_" }
}
Write-Host ""
Write-Host "Reminder: review the client repo before sharing."
