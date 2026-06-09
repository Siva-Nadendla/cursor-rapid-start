# <PROJECT_NAME>

<Short, client-facing description of what this application does.>

## Features

- <Feature 1>
- <Feature 2>

## Requirements

- Python 3.10+
- Azure subscription with access to the required services (see Configuration)

## Installation (PowerShell)

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

## Configuration

Copy `.env.example` to `.env` and provide non-secret configuration values.
Secrets (keys, tokens, connection strings) are resolved securely at runtime from
Azure Key Vault using managed identity and are never stored in the repository.

```powershell
Copy-Item .env.example .env
```

## Running the application

```powershell
# API
uvicorn app.main:app --reload

# UI
streamlit run app/streamlit_app.py
```

## Architecture

- Azure AI Search + Azure OpenAI for retrieval and generation
- Azure Blob Storage for document/data processing
- Azure Key Vault + managed identity for secure secret access

## Support

<How the client should request support or report issues.>
