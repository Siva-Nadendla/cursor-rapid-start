# Prompt: Cloud Access Guardrails (Azure)

Use this prompt when wiring a project to Azure services, to enforce safe access patterns.

---

## Principles to enforce

- **Managed identity first.** Prefer `DefaultAzureCredential` over keys/connection strings.
- **Key Vault for all secrets.** Never hardcode or commit credentials.
- **Blob-first processing.** Read/write large artifacts from Azure Blob Storage, not local disk.
- **Azure AI Search + Azure OpenAI** for retrieval and generation. No FAISS / sentence-transformers.
- **Least privilege.** Scope roles narrowly; document required RBAC.

## Prompt

> Act as my senior Python/Azure/AI engineering assistant.
>
> Wire `<PROJECT>` to Azure using safe access patterns:
>
> 1. Use `azure-identity` `DefaultAzureCredential` for auth (managed identity / Azure CLI locally).
> 2. Pull every secret from Azure Key Vault via `azure-keyvault-secrets`. No secrets in `.env` beyond
>    non-secret config (endpoint names, vault URL). Real secrets stay in Key Vault.
> 3. Use `azure-storage-blob` for blob-first read/write.
> 4. Use Azure AI Search + Azure OpenAI for RAG. Do not add FAISS or sentence-transformers.
> 5. Document the required RBAC roles and which identity needs them.
>
> Plan → review → code. Show config keys (no values) before editing.

## Expected output

- Auth via managed identity, secrets via Key Vault.
- A documented list of required Azure resources and RBAC roles.
- No secrets in source or `.env` (only references/placeholders).
