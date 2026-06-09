<#
.SYNOPSIS
    Safety gate: scans a source repo for artifacts and secrets that must never be
    delivered to a client.

.DESCRIPTION
    Scans for forbidden paths (.cursor, prompts, .env, logs, outputs, data, raw,
    .venv, venv, __pycache__, README_INTERNAL), for likely secret patterns, and for
    hardcoded local machine paths (e.g. C:\Users\... or C:\venvs\...) inside text
    files. Returns a non-zero exit code if any blocking finding is detected, so
    export scripts and CI can fail fast.

.PARAMETER SourceRepo
    Path to the internal working repo to scan.

.PARAMETER FailOnFinding
    When set (default), exits with code 1 if any blocking finding is detected.

.EXAMPLE
    .\scan_before_export.ps1 -SourceRepo "C:\Users\SivaK\OneDrive\clientrepos\my-project"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$SourceRepo,

    [bool]$FailOnFinding = $true
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $SourceRepo)) {
    throw "SourceRepo not found: $SourceRepo"
}

$resolvedRoot = (Resolve-Path -LiteralPath $SourceRepo).Path
Write-Host "Scanning: $resolvedRoot"
Write-Host ""

$findings = @()

# 1) Forbidden path patterns (anywhere in the tree, excluding .git)
$forbiddenDirNames = @(".cursor", "prompts", "logs", "outputs", "output", "data", "raw", "tmp", "temp", "secrets", "credentials", ".venv", "venv", "__pycache__")
$forbiddenFileGlobs = @("*.env", ".env", ".env.*", "*.key", "*.pem", "*.pfx", "*.p12", "*.crt", "*.cer", "README_INTERNAL.md", ".cursorignore", ".cursorindexingignore")

$allItems = Get-ChildItem -LiteralPath $resolvedRoot -Recurse -Force |
    Where-Object { $_.FullName -notmatch "\\\.git(\\|$)" }

foreach ($item in $allItems) {
    if ($item.PSIsContainer) {
        if ($forbiddenDirNames -contains $item.Name) {
            $findings += [pscustomobject]@{ Type = "ForbiddenDir"; Path = $item.FullName; Detail = $item.Name }
        }
    }
    else {
        # .env.example is an allowed placeholder file; never flag it.
        if ($item.Name -eq ".env.example") { continue }
        foreach ($glob in $forbiddenFileGlobs) {
            if ($item.Name -like $glob) {
                $findings += [pscustomobject]@{ Type = "ForbiddenFile"; Path = $item.FullName; Detail = $glob }
                break
            }
        }
    }
}

# 2) Secret-like content patterns inside text files
$secretPatterns = @(
    @{ Name = "PrivateKeyBlock"; Pattern = "-----BEGIN (RSA |EC |OPENSSH |PGP )?PRIVATE KEY-----" },
    @{ Name = "AzureStorageConnString"; Pattern = "DefaultEndpointsProtocol=.*AccountKey=" },
    @{ Name = "SasToken"; Pattern = "[\?&]sig=[A-Za-z0-9%]+" },
    @{ Name = "BearerToken"; Pattern = "(?i)bearer\s+[A-Za-z0-9\-_\.]{20,}" },
    @{ Name = "GenericAssignedSecret"; Pattern = "(?i)(password|passwd|secret|api[_-]?key|access[_-]?key|client[_-]?secret|connection[_-]?string)\s*[:=]\s*['""]?[A-Za-z0-9/\+=_\-]{8,}" },
    @{ Name = "HardcodedLocalPath"; Pattern = "(?i)[A-Za-z]:\\(Users|venvs)\\" }
)

$textExtensions = @(".py", ".md", ".txt", ".yaml", ".yml", ".json", ".ini", ".cfg", ".toml", ".ps1", ".env", ".config", ".xml", ".js", ".ts")

$scanFiles = $allItems | Where-Object {
    -not $_.PSIsContainer -and ($textExtensions -contains $_.Extension.ToLower())
}

foreach ($file in $scanFiles) {
    # Skip .env.example style placeholder files from secret-content checks (still flagged as files if .env*)
    $content = ""
    try {
        $content = Get-Content -LiteralPath $file.FullName -Raw -ErrorAction Stop
    }
    catch {
        continue
    }
    if ([string]::IsNullOrEmpty($content)) { continue }

    foreach ($sp in $secretPatterns) {
        if ($content -match $sp.Pattern) {
            $findings += [pscustomobject]@{ Type = "SecretPattern:$($sp.Name)"; Path = $file.FullName; Detail = $sp.Name }
        }
    }
}

# Report
if ($findings.Count -eq 0) {
    Write-Host "PASS: no forbidden artifacts or secret patterns found." -ForegroundColor Green
    Write-Host ""
    Write-Host "Safe to proceed to export."
    exit 0
}

Write-Host "FINDINGS ($($findings.Count)):" -ForegroundColor Yellow
$findings | Sort-Object Type, Path | Format-Table -AutoSize Type, Detail, Path | Out-String | Write-Host

Write-Host ""
Write-Host "FAIL: blocking findings detected. Do NOT export until resolved." -ForegroundColor Red

if ($FailOnFinding) {
    exit 1
}
