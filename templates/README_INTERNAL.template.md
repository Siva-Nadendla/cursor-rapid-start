# <PROJECT_NAME> (INTERNAL)

> Internal working repo. Contains `.cursor/rules`, internal notes, and prompts.
> **Do not deliver this repo to a client.** Use the export scripts to produce a clean client repo.

## Workspace safety

- This is an **internal Cursor working repo**. Before running any project prompts, verify the marker file `.internal_cursor_project_root` exists in the repo root.
- The client delivery repo is a **separate** repo. Keep it clean.
- Run Cursor prompts and use `.cursor/rules` **only** from this internal repo, never from the client delivery repo.

## Naming and File Conventions

- This internal working repo uses `work-...` naming; its paired client delivery repo uses `deliver-...` naming where applicable.
- Scripts use `.ps1`, prompts use `.md`, Cursor rules use `.mdc`, templates use `.template`.
- Marker files identify the repo type (`.internal_cursor_project_root` here, `.client_delivery_repo_root` in the client repo).
- Do not use spaces in filenames. Do not run prompts from the wrong workspace.

## Overview

<Short internal description of the project, goals, and current status.>

## Stack

- Python (Azure-first)
- Azure AI Search + Azure OpenAI for RAG
- Azure Blob Storage (blob-first processing)
- Azure Key Vault + managed identity for secrets
- Streamlit / FastAPI / Uvicorn as needed

## Local setup (PowerShell)

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
Copy-Item .env.example .env   # then fill in NON-SECRET config
```

## Run

```powershell
# FastAPI
uvicorn app.main:app --reload

# Streamlit
streamlit run app/streamlit_app.py
```

## Internal notes

- Auth: `DefaultAzureCredential` (managed identity / Azure CLI locally).
- Secrets: Azure Key Vault only. Never commit secrets.
- Do NOT add FAISS or sentence-transformers.

## Before client delivery

1. `scripts/scan_before_export.ps1`
2. `scripts/export_to_client_repo.ps1`

## Internal TODO

- [ ] ...
