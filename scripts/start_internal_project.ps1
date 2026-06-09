<#
.SYNOPSIS
    Creates a new internal Cursor working repo AND a separate clean client delivery repo.

.DESCRIPTION
    Scaffolds two sibling repos under BaseRepoPath:
      - An internal working repo (may contain .cursor rules, logs, outputs, raw data).
      - A clean client delivery repo (NEVER receives .cursor, secrets, logs, outputs, or raw data).
    Also creates a dedicated Python virtual environment for the internal repo and installs
    the starter dependencies into it.

    Safe by design:
      - Never copies .cursor into the client repo.
      - Never writes a .env file with real values; only a .env.example with placeholders.
      - Does not overwrite existing files unless -Force is supplied.
      - Performs no destructive operations (no deletes).

.PARAMETER InternalRepoName
    Folder name of the internal working repo (also used to name the virtual environment).

.PARAMETER ClientRepoName
    Folder name of the clean client delivery repo.

.PARAMETER BaseRepoPath
    Parent directory for both repos. Defaults to C:\Users\SivaK\OneDrive\clientrepos.

.PARAMETER VenvBasePath
    Parent directory for virtual environments. Defaults to C:\venvs.

.PARAMETER AzureSupport
    When $true (default), includes Azure-first guidance in the generated project rule.

.PARAMETER Force
    Overwrite existing files when they already exist. Without it, existing files are kept.

.EXAMPLE
    .\start_internal_project.ps1 -InternalRepoName "acme-internal" -ClientRepoName "acme-client"

.EXAMPLE
    .\start_internal_project.ps1 -InternalRepoName "acme-internal" -ClientRepoName "acme-client" -AzureSupport:$false -Force
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$InternalRepoName,

    [Parameter(Mandatory = $true)]
    [string]$ClientRepoName,

    [string]$BaseRepoPath = "C:\Users\SivaK\OneDrive\clientrepos",

    [string]$VenvBasePath = "C:\venvs",

    [bool]$AzureSupport = $true,

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

# --- Resolve framework locations -------------------------------------------------
$frameworkRoot = Split-Path -Parent $PSScriptRoot
$templatesDir = Join-Path $frameworkRoot "templates"
$rulesSourceDir = Join-Path $frameworkRoot "cursor-rules-standard"

if (-not (Test-Path -LiteralPath $templatesDir)) {
    throw "Templates folder not found: $templatesDir"
}
if (-not (Test-Path -LiteralPath $rulesSourceDir)) {
    throw "Standard rules folder not found: $rulesSourceDir"
}

# --- Helper: ensure a directory exists (non-destructive) -------------------------
function New-DirectoryIfMissing {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
        Write-Host "  Created folder: $Path"
    }
}

# --- Helper: render a template into an active file (respects -Force) --------------
function Copy-TemplateFile {
    param(
        [string]$TemplateName,   # file name inside templates/
        [string]$DestPath,       # full destination path
        [hashtable]$Replacements # optional token -> value substitutions
    )
    $src = Join-Path $templatesDir $TemplateName
    if (-not (Test-Path -LiteralPath $src)) {
        Write-Warning "  Template missing, skipped: $TemplateName"
        return
    }
    if ((Test-Path -LiteralPath $DestPath) -and (-not $Force)) {
        Write-Warning "  Skipped (exists, use -Force): $DestPath"
        return
    }
    if ($Replacements -and $Replacements.Count -gt 0) {
        $content = Get-Content -LiteralPath $src -Raw
        foreach ($key in $Replacements.Keys) {
            $content = $content.Replace($key, [string]$Replacements[$key])
        }
        Set-Content -LiteralPath $DestPath -Value $content -Encoding UTF8
    }
    else {
        Copy-Item -LiteralPath $src -Destination $DestPath -Force
    }
    Write-Host "  Rendered: $DestPath"
}

# --- Validate / prepare base paths -----------------------------------------------
New-DirectoryIfMissing -Path $BaseRepoPath
New-DirectoryIfMissing -Path $VenvBasePath

$internalRepoPath = Join-Path $BaseRepoPath $InternalRepoName
$clientRepoPath = Join-Path $BaseRepoPath $ClientRepoName
$venvPath = Join-Path $VenvBasePath $InternalRepoName

if ($internalRepoPath -eq $clientRepoPath) {
    throw "InternalRepoName and ClientRepoName must be different."
}

# Guard against scaffolding into an existing, non-empty repo without -Force.
foreach ($repo in @($internalRepoPath, $clientRepoPath)) {
    if (Test-Path -LiteralPath $repo) {
        $existing = Get-ChildItem -LiteralPath $repo -Force | Where-Object { $_.Name -ne ".git" }
        if ($existing -and (-not $Force)) {
            throw "Repo folder already exists and is not empty: $repo (use -Force to proceed)"
        }
    }
}

# =================================================================================
# 1) INTERNAL REPO
# =================================================================================
Write-Host ""
Write-Host "Creating internal repo: $internalRepoPath"
New-DirectoryIfMissing -Path $internalRepoPath

# Internal starter folders
$internalFolders = @("data\raw", "pipelines", "src", "scripts", "docs", "logs", "outputs")
foreach ($folder in $internalFolders) {
    New-DirectoryIfMissing -Path (Join-Path $internalRepoPath $folder)
}

# Internal templates (internal .gitignore, placeholders only for env)
Copy-TemplateFile -TemplateName "gitignore_internal.template" -DestPath (Join-Path $internalRepoPath ".gitignore")
Copy-TemplateFile -TemplateName "env.example.template" -DestPath (Join-Path $internalRepoPath ".env.example")
Copy-TemplateFile -TemplateName "config.yaml.template" -DestPath (Join-Path $internalRepoPath "config.yaml")
Copy-TemplateFile -TemplateName "requirements.txt.template" -DestPath (Join-Path $internalRepoPath "requirements.txt")
Copy-TemplateFile -TemplateName "README_INTERNAL.template.md" -DestPath (Join-Path $internalRepoPath "README.md") -Replacements @{ "<PROJECT_NAME>" = $InternalRepoName }

# Standard Cursor rules -> internal repo ONLY
$internalRulesDir = Join-Path $internalRepoPath ".cursor\rules"
New-DirectoryIfMissing -Path $internalRulesDir
$ruleFiles = Get-ChildItem -LiteralPath $rulesSourceDir -Filter "*.mdc" -File
foreach ($rule in $ruleFiles) {
    $dest = Join-Path $internalRulesDir $rule.Name
    if ((Test-Path -LiteralPath $dest) -and (-not $Force)) {
        Write-Warning "  Skipped rule (exists, use -Force): $($rule.Name)"
        continue
    }
    Copy-Item -LiteralPath $rule.FullName -Destination $dest -Force
    Write-Host "  Applied rule: $($rule.Name)"
}

# Generate a project-specific rule (no secrets, placeholders only)
$projectRulePath = Join-Path $internalRulesDir "99_project_specific.mdc"
if ((Test-Path -LiteralPath $projectRulePath) -and (-not $Force)) {
    Write-Warning "  Skipped 99_project_specific.mdc (exists, use -Force)"
}
else {
    $azureLine = if ($AzureSupport) {
        "- Azure-first: use Azure AI Search, Azure OpenAI, Blob-first processing, Key Vault, and managed identity."
    }
    else {
        "- Azure support is disabled for this project; confirm the target cloud/services before adding access code."
    }
    # Built as a line array to avoid heredocs / here-strings.
    $ruleLines = @(
        "---",
        "description: Project-specific rules for $InternalRepoName (internal working repo).",
        "globs:",
        "alwaysApply: true",
        "---",
        "",
        "# Project: $InternalRepoName",
        "",
        "- This is an INTERNAL working repo. Its paired client repo is '$ClientRepoName'.",
        "- Never deliver .cursor, .env, logs, outputs, or data/raw to the client repo.",
        "- Use scripts/export_to_client_repo.ps1 (allowlist) to produce client deliverables.",
        $azureLine,
        "- Keep secrets in Key Vault; never commit credentials. Use placeholders in .env.example only.",
        "- Follow plan -> review -> code with minimal, safe diffs.",
        "",
        "## Workspace Protection",
        "",
        "This project must only be modified from this internal Cursor workspace:",
        "",
        ('`' + $internalRepoPath + '`'),
        "",
        "Before running project prompts, verify:",
        "",
        '```powershell',
        "pwd",
        "Test-Path .\.internal_cursor_project_root",
        '```',
        "",
        "Expected result:",
        "",
        ('* `pwd` points to `' + $internalRepoPath + '`'),
        '* marker file returns `True`',
        "",
        "If not, stop immediately."
    )
    Set-Content -LiteralPath $projectRulePath -Value $ruleLines -Encoding UTF8
    Write-Host "  Generated: $projectRulePath"
}

# Internal repo workspace protection: root marker file
$internalMarkerLines = @(
    "This folder is an internal Cursor working repo created by cursor-rapid-start.",
    "",
    "Do not run this project's Cursor prompts from any other workspace.",
    "",
    "Internal repo name: $InternalRepoName",
    "Client delivery repo name: $ClientRepoName",
    "Internal repo path: $internalRepoPath",
    "Client delivery repo path: $clientRepoPath",
    "Venv path: $venvPath",
    "",
    "This repo may contain .cursor/rules.",
    "The client delivery repo must not contain .cursor, .env, logs, outputs, data/raw, secrets, or credentials."
)
$internalMarkerPath = Join-Path $internalRepoPath ".internal_cursor_project_root"
if ((Test-Path -LiteralPath $internalMarkerPath) -and (-not $Force)) {
    Write-Warning "  Skipped .internal_cursor_project_root (exists, use -Force)"
}
else {
    Set-Content -LiteralPath $internalMarkerPath -Value $internalMarkerLines -Encoding UTF8
    Write-Host "  Created marker: $internalMarkerPath"
}

# Internal repo workspace protection: dynamic Cursor safety rule
$internalSafetyRulePath = Join-Path $internalRulesDir "00_workspace_safety.mdc"
if ((Test-Path -LiteralPath $internalSafetyRulePath) -and (-not $Force)) {
    Write-Warning "  Skipped 00_workspace_safety.mdc (exists, use -Force)"
}
else {
    $internalSafetyLines = @(
        '---',
        "description: Workspace safety rule for internal repo $InternalRepoName.",
        'globs:',
        'alwaysApply: true',
        '---',
        '',
        '# Workspace Safety Rule',
        '',
        'This is an internal Cursor working repo.',
        '',
        '## Expected Workspace',
        '',
        'Internal repo name:',
        '',
        ('`' + $InternalRepoName + '`'),
        '',
        'Internal repo path:',
        '',
        ('`' + $internalRepoPath + '`'),
        '',
        'Required marker file:',
        '',
        '`.internal_cursor_project_root`',
        '',
        'Linked client delivery repo:',
        '',
        ('`' + $clientRepoPath + '`'),
        '',
        'Venv path:',
        '',
        ('`' + $venvPath + '`'),
        '',
        '## Mandatory Rule',
        '',
        'Before creating, editing, deleting, moving, or generating files, verify that the active workspace is this internal repo.',
        '',
        'The current workspace must match:',
        '',
        ('`' + $internalRepoPath + '`'),
        '',
        'The root marker file must exist:',
        '',
        '`.internal_cursor_project_root`',
        '',
        'If the workspace is not correct, stop immediately and say:',
        '',
        ('`Wrong workspace. Open ' + $internalRepoPath + ' before running this prompt.`'),
        '',
        '## Do Not Run Internal Prompts From',
        '',
        'Do not run this project''s prompts from:',
        '',
        '- The client delivery repo',
        '- Another internal repo',
        '- The `cursor-rapid-start` repo',
        '- Any unrelated project folder',
        '- Any recent Cursor sidebar item that is not this exact workspace',
        '',
        '## Client Boundary',
        '',
        'Never copy these to the client delivery repo:',
        '',
        '- `.cursor`',
        '- `.env`',
        '- `logs`',
        '- `outputs`',
        '- `data/raw`',
        '- `secrets`',
        '- `credentials`',
        '- local scratch files',
        '- private notes',
        '- agent prompts',
        '',
        '## Before Any Action',
        '',
        'Before writing files, always state:',
        '',
        '- Current workspace path',
        '- Target file path',
        '- Whether `.internal_cursor_project_root` exists',
        '- Whether the action is inside the approved internal repo'
    )
    Set-Content -LiteralPath $internalSafetyRulePath -Value $internalSafetyLines -Encoding UTF8
    Write-Host "  Generated: $internalSafetyRulePath"
}

# =================================================================================
# 2) CLIENT REPO (clean - never receives .cursor)
# =================================================================================
Write-Host ""
Write-Host "Creating client repo: $clientRepoPath"
New-DirectoryIfMissing -Path $clientRepoPath

# Client starter folders (no data/raw, logs, or outputs)
$clientFolders = @("pipelines", "src", "scripts", "docs")
foreach ($folder in $clientFolders) {
    New-DirectoryIfMissing -Path (Join-Path $clientRepoPath $folder)
}

# Client templates (client .gitignore + client README, placeholders only for env)
Copy-TemplateFile -TemplateName "gitignore_client.template" -DestPath (Join-Path $clientRepoPath ".gitignore")
Copy-TemplateFile -TemplateName "env.example.template" -DestPath (Join-Path $clientRepoPath ".env.example")
Copy-TemplateFile -TemplateName "config.yaml.template" -DestPath (Join-Path $clientRepoPath "config.yaml")
Copy-TemplateFile -TemplateName "requirements.txt.template" -DestPath (Join-Path $clientRepoPath "requirements.txt")
Copy-TemplateFile -TemplateName "README_CLIENT.template.md" -DestPath (Join-Path $clientRepoPath "README.md") -Replacements @{ "<PROJECT_NAME>" = $ClientRepoName }

# Safety assertion: the client repo must never contain .cursor
$clientCursorPath = Join-Path $clientRepoPath ".cursor"
if (Test-Path -LiteralPath $clientCursorPath) {
    throw "SAFETY: .cursor exists in the client repo ($clientCursorPath). This must never happen."
}

# Client repo workspace protection: root marker file
$clientMarkerLines = @(
    "This folder is a clean client delivery repo created by cursor-rapid-start.",
    "",
    "Cursor prompts and .cursor/rules must not be used here.",
    "",
    "This repo should contain only approved client deliverables.",
    "Do not copy .cursor, .env, logs, outputs, data/raw, secrets, credentials, or internal notes into this repo.",
    "",
    "Client delivery repo name: $ClientRepoName",
    "Linked internal repo name: $InternalRepoName"
)
$clientMarkerPath = Join-Path $clientRepoPath ".client_delivery_repo_root"
if ((Test-Path -LiteralPath $clientMarkerPath) -and (-not $Force)) {
    Write-Warning "  Skipped .client_delivery_repo_root (exists, use -Force)"
}
else {
    Set-Content -LiteralPath $clientMarkerPath -Value $clientMarkerLines -Encoding UTF8
    Write-Host "  Created marker: $clientMarkerPath"
}

# =================================================================================
# 3) VIRTUAL ENVIRONMENT + DEPENDENCIES (internal repo)
# =================================================================================
Write-Host ""
Write-Host "Creating virtual environment: $venvPath"

$pythonExe = $null
foreach ($candidate in @("python", "py")) {
    $cmd = Get-Command $candidate -ErrorAction SilentlyContinue
    if ($cmd) { $pythonExe = $candidate; break }
}

if (-not $pythonExe) {
    Write-Warning "Python not found on PATH. Skipped venv creation and dependency install."
    Write-Warning "Create it later with: python -m venv `"$venvPath`""
}
elseif ((Test-Path -LiteralPath $venvPath) -and (-not $Force)) {
    Write-Warning "Venv already exists (use -Force to recreate inputs): $venvPath. Skipped creation."
}
else {
    & $pythonExe -m venv $venvPath
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "venv creation returned exit code $LASTEXITCODE. Check your Python installation."
    }
    else {
        Write-Host "  Virtual environment ready."
        $venvPython = Join-Path $venvPath "Scripts\python.exe"
        $reqFile = Join-Path $internalRepoPath "requirements.txt"
        if ((Test-Path -LiteralPath $venvPython) -and (Test-Path -LiteralPath $reqFile)) {
            Write-Host "  Installing dependencies from requirements.txt ..."
            & $venvPython -m pip install --upgrade pip
            & $venvPython -m pip install -r $reqFile
            if ($LASTEXITCODE -ne 0) {
                Write-Warning "pip install returned exit code $LASTEXITCODE. Review the output above."
            }
            else {
                Write-Host "  Dependencies installed."
            }
        }
        else {
            Write-Warning "  Could not locate venv python or requirements.txt; skipped dependency install."
        }
    }
}

# =================================================================================
# SUMMARY
# =================================================================================
Write-Host ""
Write-Host "==================== SUMMARY ===================="
Write-Host "Internal repo : $internalRepoPath"
Write-Host "Client repo   : $clientRepoPath"
Write-Host "Virtual env   : $venvPath"
Write-Host "Azure support : $AzureSupport"
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Activate venv: `"$venvPath\Scripts\Activate.ps1`""
Write-Host "  2. In the internal repo, copy .env.example to .env and set NON-SECRET config only."
Write-Host "  3. When ready, export deliverables:"
Write-Host "     .\export_to_client_repo.ps1 -SourceRepo `"$internalRepoPath`" -ClientRepo `"$clientRepoPath`""
