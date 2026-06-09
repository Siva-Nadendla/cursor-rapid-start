# Prompt: Review Before Export

Use this prompt as a final human-in-the-loop review gate before any client export.

---

## Prompt

> Act as my senior Python/Azure/AI engineering assistant and reviewer.
>
> Before I export `<SOURCE_REPO>` to a client, perform a review:
>
> 1. Run `scripts/scan_before_export.ps1 -SourceRepo "<SOURCE_REPO>"` and summarize findings.
> 2. Search the repo for hardcoded secrets, tokens, keys, connection strings, and internal URLs.
> 3. Search for any `.cursor` references, internal prompt text, or `README_INTERNAL` content
>    that could leak into client-facing files.
> 4. Confirm `requirements.txt` does not contain FAISS or sentence-transformers.
> 5. Produce a go / no-go recommendation with a checklist.
>
> Do not modify files in this step. Review only.

## Review checklist

- [ ] `scan_before_export.ps1` passed
- [ ] No secrets / keys / tokens / connection strings
- [ ] No `.cursor/` artifacts referenced in deliverable files
- [ ] No internal-only docs in client-facing paths
- [ ] `requirements.txt` clean (Azure-first, no FAISS / sentence-transformers)
- [ ] README is the client version, not internal
- [ ] Go / No-Go decision recorded
