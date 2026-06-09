# cursor_rapid_start

Internal Cursor Pro+ **rapid-start framework**. This is a private control repo used to:

1. Spin up clean **internal Cursor working repos** with standard rules, structure, and Azure-first defaults.
2. Produce separate, clean **client delivery repos** that never contain Cursor artifacts, secrets, logs, outputs, or raw data.

> **This repo is NOT a client repo.** It intentionally contains `.cursor/rules`, `prompts/`, and automation that must never be exported to clients.

---

## What this repo gives you

| Area | What it does |
|------|--------------|
| `prompts/` | Reusable Cursor prompts for each phase (start project, prepare delivery, review before export, cloud guardrails, apply rules). Internal-only. |
| `templates/` | Inert `*.template` files copied + renamed into new repos (gitignores, env example, config, requirements, READMEs). |
| `cursor-rules-standard/` | The canonical `.mdc` rule library applied to new internal working repos. |
| `scripts/` | PowerShell automation for scaffolding, applying rules, scanning, and exporting. |
| `examples/` | Sample inputs (e.g. `sample_project_startup.json`). |
| `.cursor/rules/` | Rules governing *this* control repo only. |

---

## Quick start (PowerShell)

### 1. Create a new internal working project

```powershell
.\scripts\start_internal_project.ps1 -ProjectName "my-project" -TargetRoot "C:\Users\SivaK\OneDrive\clientrepos" -ConfigPath ".\examples\sample_project_startup.json"
```

### 2. Apply standard Cursor rules to a working repo

```powershell
.\scripts\apply_cursor_rules.ps1 -TargetRepo "C:\Users\SivaK\OneDrive\clientrepos\my-project"
```

### 3. Scan a working repo before export (safety gate)

```powershell
.\scripts\scan_before_export.ps1 -SourceRepo "C:\Users\SivaK\OneDrive\clientrepos\my-project"
```

### 4. Export a clean client delivery repo

```powershell
.\scripts\export_to_client_repo.ps1 -SourceRepo "C:\Users\SivaK\OneDrive\clientrepos\my-project" -ClientRepo "C:\Users\SivaK\OneDrive\clientrepos\my-project-client"
```

### 5. Validate this starter repo itself

```powershell
.\scripts\validate_starter_repo.ps1
```

---

## Client delivery boundary (non-negotiable)

Client delivery repos must **NEVER** contain:

- `.cursor/` (any Cursor rules, prompts, or metadata)
- `.env`, `.env.*`, or any secrets / keys / tokens / connection strings
- `prompts/` (internal Cursor prompts)
- `logs/`, `outputs/`, `data/`, `raw/`
- Any internal-only `README_INTERNAL.md`

`scan_before_export.ps1` is the gate; `export_to_client_repo.ps1` refuses to copy forbidden artifacts.

---

## Principles

- **Plan → review → code** for every change.
- **Azure-first**: Azure AI Search, Azure OpenAI, Blob-first processing, Key Vault, managed identity.
- **No secrets in git, ever.** Use Key Vault + managed identity.
- **PowerShell-friendly**, Windows-first, no heredocs.
- **Minimal, safe diffs.** No broad rewrites without explicit request.

---

## Repo layout

```text
cursor-rapid-start/
├── README.md
├── .gitignore
├── requirements.txt
├── prompts/
├── templates/
├── cursor-rules-standard/
├── scripts/
├── examples/
└── .cursor/rules/
```
