# Prompt: Start a New Internal Project

Use this prompt in Cursor when bootstrapping a brand-new internal working repo from the rapid-start framework.

---

## Context to give the agent

- This is an **internal** Cursor working repo (not a client repo).
- It MAY contain `.cursor/rules`, `prompts/`, and internal docs.
- It must follow the Azure-first stack: Azure AI Search, Azure OpenAI, Blob-first processing, Key Vault, managed identity.
- No secrets in git. No FAISS / sentence-transformers.

## Prompt

> Act as my senior Python/Azure/AI engineering assistant.
>
> I want to start a new internal project named `<PROJECT_NAME>`.
>
> 1. Read `examples/sample_project_startup.json` and confirm the config you will use.
> 2. Plan the folder structure before creating anything (plan → review → code).
> 3. Use `scripts/start_internal_project.ps1` to scaffold it under `<TARGET_ROOT>`.
> 4. Apply the standard rules with `scripts/apply_cursor_rules.ps1`.
> 5. Render `templates/README_INTERNAL.template.md`, `templates/config.yaml.template`,
>    `templates/env.example.template`, `templates/requirements.txt.template`, and
>    `templates/gitignore_internal.template` into the new repo.
> 6. Confirm `.env` is git-ignored and contains only placeholders (never real secrets).
>
> Show me the proposed structure and wait for approval before writing files.

## Expected output

- A new internal repo with `.cursor/rules/`, `.gitignore`, `.env.example`, `config.yaml`, `requirements.txt`, and `README_INTERNAL.md`.
- No secrets committed.
- A short summary plus exact PowerShell test commands.
