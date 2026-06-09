# 02 - Run Starter Kit

You are my Cursor Rapid Start execution agent.

## Mandatory Workspace Safety Check

Before doing anything, verify that the current workspace is the starter-kit repo.

Expected workspace:

`C:\Users\SivaK\OneDrive\clientrepos\cursor-rapid-start`

Expected root folder:

`cursor-rapid-start`

Required marker file:

`.cursor_rapid_start_root`

If the workspace is not correct, stop immediately and say:

`Wrong workspace. Open C:\Users\SivaK\OneDrive\clientrepos\cursor-rapid-start before running this prompt.`

Do not create or modify files in any other repo.

## Goal

Use this starter repo to create:

1. One new internal Cursor working repo
2. One separate clean client delivery repo
3. One Python virtual environment under `C:\venvs\<internal-repo-name>`

## Ask for Startup Inputs

Before doing anything else, ask me for these inputs:

1. Internal Cursor working repo name
2. Client delivery repo name
3. Base repo path
   Default: `C:\Users\SivaK\OneDrive\clientrepos`
4. Venv base path
   Default: `C:\venvs`
5. Azure support required?
   Default: `yes`

## What Will Be Created

The internal Cursor working repo will receive:

- `.cursor/rules` (including `00_workspace_safety.mdc` and `99_project_specific.mdc`)
- `.internal_cursor_project_root` marker file
- Internal starter folders: `data/raw`, `pipelines`, `src`, `scripts`, `docs`, `logs`, `outputs`
- Starter files: `.gitignore`, `.env.example`, `config.yaml`, `requirements.txt`, `README.md`

The clean client delivery repo will receive:

- `.client_delivery_repo_root` marker file
- Client starter folders: `pipelines`, `src`, `scripts`, `docs`
- Starter files: `.gitignore`, `.env.example`, `config.yaml`, `requirements.txt`, `README.md`

The client delivery repo must never receive:

- `.cursor`
- `.env`
- `logs`
- `outputs`
- `data/raw`
- secrets or credentials

## Security Rules

Never store, generate, or copy real passwords, API keys, tokens, private keys, connection strings, client secrets, or cloud credentials.

Use only `.env.example` placeholders for local configuration, Azure CLI/session authentication where needed, and Azure Key Vault where appropriate. Never print secret values.

## Execution Steps

1. Run the workspace safety check above. Stop if it fails.
2. Verify these required starter-kit folders exist: `templates`, `cursor-rules-standard`, `scripts`.
3. Verify this script exists: `scripts/start_internal_project.ps1`.
4. If anything required is missing, stop and tell me what is missing.
5. Ask me for the startup inputs.
6. Show the planned internal repo path, client repo path, venv path, and the folders/files to be created in each.
7. Wait for my approval.
8. After approval, run:

```powershell
.\scripts\start_internal_project.ps1 -InternalRepoName "<internal-repo-name>" -ClientRepoName "<client-repo-name>" -BaseRepoPath "<base-repo-path>" -VenvBasePath "<venv-base-path>" -AzureSupport $true
```

Use `$false` for `-AzureSupport` if Azure support is not required.

9. Validate that the internal repo contains `.cursor/rules`, `.internal_cursor_project_root`, and the approved internal folders/files.
10. Validate that the client repo contains `.client_delivery_repo_root` and does NOT contain `.cursor`, `.env`, `logs`, `outputs`, or `data/raw`.

## Approval Rule

Do not create or modify project repos until I approve the plan.
