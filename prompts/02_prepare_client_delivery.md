# Prompt: Prepare a Client Delivery Repo

Use this prompt when you are ready to produce a clean, client-facing delivery repo from an internal working repo.

---

## Hard rules (state these to the agent)

The client delivery repo must **NEVER** contain:

- `.cursor/` (rules, prompts, metadata)
- `.env`, `.env.*`, secrets, keys, tokens, connection strings
- `prompts/` (internal Cursor prompts)
- `logs/`, `outputs/`, `data/`, `raw/`
- `README_INTERNAL.md` (internal-only docs)

## Prompt

> Act as my senior Python/Azure/AI engineering assistant.
>
> I want to prepare a client delivery repo from `<SOURCE_REPO>`.
>
> 1. First run `scripts/scan_before_export.ps1 -SourceRepo "<SOURCE_REPO>"` and show me the report.
> 2. If the scan fails, stop and list every forbidden artifact found. Do not export.
> 3. If the scan passes, run `scripts/export_to_client_repo.ps1` to create `<CLIENT_REPO>`.
> 4. Confirm the client repo uses `templates/gitignore_client.template` as its `.gitignore`
>    and `templates/README_CLIENT.template.md` as its `README.md`.
> 5. List exactly what was copied and what was excluded.
>
> Plan → review → code. Do not copy anything outside the safe allowlist.

## Expected output

- A clean client repo with source code, client `README.md`, client `.gitignore`, and `requirements.txt` only.
- A clear copied/excluded manifest.
- Confirmation that no Cursor artifacts or secrets were transferred.
