# Prompt: Apply Standard Cursor Rules

Use this prompt to apply the canonical rule library to an internal working repo.

---

## Prompt

> Act as my senior Python/Azure/AI engineering assistant.
>
> Apply the standard Cursor rules to `<TARGET_REPO>`:
>
> 1. Run `scripts/apply_cursor_rules.ps1 -TargetRepo "<TARGET_REPO>"`.
> 2. This copies every `.mdc` from `cursor-rules-standard/` into `<TARGET_REPO>\.cursor\rules\`.
> 3. Confirm the target is an **internal** repo (client repos must never receive `.cursor/`).
> 4. List the rules applied and confirm none were overwritten unexpectedly (use `-Force` only if I ask).
>
> Plan → review → code.

## Standard rules applied

| File | Purpose |
|------|---------|
| `00_working_model.mdc` | Plan → review → code; minimal safe diffs. |
| `01_security_and_secrets.mdc` | No secrets in git; Key Vault + managed identity. |
| `02_python_project_setup.mdc` | Python project conventions and structure. |
| `03_client_delivery_boundary.mdc` | What may never reach a client repo. |
| `04_azure_access_guardrails.mdc` | Azure-first access patterns. |
| `05_documentation_standards.mdc` | Documentation expectations. |

## Reminder

Never apply `.cursor/` rules to a client delivery repo.
