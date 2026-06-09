<#
.SYNOPSIS
    Scaffolds a new internal Cursor working repo from the rapid-start framework.

.DESCRIPTION
    Creates a new project folder, renders templates (gitignore, env example, config,
    requirements, internal README), applies the standard Cursor rules, and optionally
    initializes a git repository. Internal repos only.

.PARAMETER ProjectName
    Name of the new project (used for folder name and README title).

.PARAMETER TargetRoot
    Parent directory where the new project folder will be created.

.PARAMETER ConfigPath
    Optional path to a project startup JSON (see examples/sample_project_startup.json).

.PARAMETER InitGit
    Initialize a git repository in the new project.

.PARAMETER Force
    Allow scaffolding into an existing non-empty folder (existing files are not overwritten unless they are template targets).

.EXAMPLE
    .\start_internal_project.ps1 -ProjectName "my-project" -TargetRoot "C:\Users\SivaK\OneDrive\clientrepos" -ConfigPath ".\examples\sample_project_startup.json"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectName,

    [Parameter(Mandatory = $true)]
    [string]$TargetRoot,

    [string]$ConfigPath,

    [switch]$InitGit,

    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$frameworkRoot = Split-Path -Parent $PSScriptRoot
$templatesDir = Join-Path $frameworkRoot "templates"

if (-not (Test-Path -LiteralPath $TargetRoot)) {
    throw "TargetRoot not found: $TargetRoot"
}

# Optional config
$config = $null
if ($ConfigPath) {
    if (-not (Test-Path -LiteralPath $ConfigPath)) {
        throw "ConfigPath not found: $ConfigPath"
    }
    try {
        $config = Get-Content -LiteralPath $ConfigPath -Raw | ConvertFrom-Json
        Write-Host "Loaded config: $ConfigPath"
    }
    catch {
        throw "Failed to parse JSON config '$ConfigPath': $($_.Exception.Message)"
    }
}

$projectPath = Join-Path $TargetRoot $ProjectName
if (Test-Path -LiteralPath $projectPath) {
    $existing = Get-ChildItem -LiteralPath $projectPath -Force | Where-Object { $_.Name -ne ".git" }
    if ($existing -and (-not $Force)) {
        throw "Project folder already exists and is not empty: $projectPath (use -Force to proceed)"
    }
}
else {
    New-Item -ItemType Directory -Path $projectPath -Force | Out-Null
}
Write-Host "Project path: $projectPath"

# Standard project subfolders (kept minimal)
foreach ($sub in @("app")) {
    $p = Join-Path $projectPath $sub
    if (-not (Test-Path -LiteralPath $p)) {
        New-Item -ItemType Directory -Path $p -Force | Out-Null
    }
}

function Copy-Template {
    param(
        [string]$TemplateName,
        [string]$DestName
    )
    $src = Join-Path $templatesDir $TemplateName
    if (-not (Test-Path -LiteralPath $src)) {
        Write-Warning "Template missing, skipped: $TemplateName"
        return
    }
    $dest = Join-Path $projectPath $DestName
    if ((Test-Path -LiteralPath $dest) -and (-not $Force)) {
        Write-Warning "Skipped (exists, use -Force): $DestName"
        return
    }
    Copy-Item -LiteralPath $src -Destination $dest -Force
    Write-Host "Rendered: $DestName"
}

# Render templates into their active names
Copy-Template -TemplateName "gitignore_internal.template" -DestName ".gitignore"
Copy-Template -TemplateName "env.example.template" -DestName ".env.example"
Copy-Template -TemplateName "config.yaml.template" -DestName "config.yaml"
Copy-Template -TemplateName "requirements.txt.template" -DestName "requirements.txt"
Copy-Template -TemplateName "README_INTERNAL.template.md" -DestName "README_INTERNAL.md"

# Substitute project name in the internal README
$readmePath = Join-Path $projectPath "README_INTERNAL.md"
if (Test-Path -LiteralPath $readmePath) {
    (Get-Content -LiteralPath $readmePath -Raw).Replace("<PROJECT_NAME>", $ProjectName) |
        Set-Content -LiteralPath $readmePath -Encoding UTF8
}

# Apply standard Cursor rules
$applyRules = Join-Path $PSScriptRoot "apply_cursor_rules.ps1"
if (Test-Path -LiteralPath $applyRules) {
    & $applyRules -TargetRepo $projectPath
}
else {
    Write-Warning "apply_cursor_rules.ps1 not found; rules not applied."
}

# Optional git init
if ($InitGit) {
    if (Test-Path -LiteralPath (Join-Path $projectPath ".git")) {
        Write-Host "Git repo already initialized."
    }
    else {
        Push-Location $projectPath
        try {
            git init | Out-Null
            Write-Host "Initialized git repository."
        }
        finally {
            Pop-Location
        }
    }
}

Write-Host ""
Write-Host "Internal project scaffolded at: $projectPath"
Write-Host "Next steps:"
Write-Host "  cd `"$projectPath`""
Write-Host "  python -m venv .venv; .\.venv\Scripts\Activate.ps1; pip install -r requirements.txt"
Write-Host "  Copy-Item .env.example .env   # fill in NON-SECRET config only"
