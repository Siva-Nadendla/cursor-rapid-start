# 07 - Naming and File Conventions

This document defines the naming and file-extension standard for the `cursor-rapid-start` starter kit and for every internal Cursor working repo and client delivery repo it creates.

## File Extensions

| Extension | Use for |
|---|---|
| `.ps1` | PowerShell scripts |
| `.md` | prompts and documentation |
| `.mdc` | Cursor rules |
| `.template` | reusable templates |
| `.yaml` | config files |
| `.json` | examples or structured input |
| `.txt` | plain text dependency files if needed |

## Repository Names

Use hyphen-case.

```text
work-client-project
deliver-client-project
```

Preferred generated repo pattern:

```text
work-<client-or-purpose>-<project>
deliver-<client-or-purpose>-<project>
```

- The `work-` repo is the internal Cursor working repo.
- The `deliver-` repo is the clean client delivery repo.

## Scripts

Use snake_case with `.ps1`.

```text
start_internal_project.ps1
apply_cursor_rules.ps1
export_to_client_repo.ps1
scan_before_export.ps1
validate_starter_repo.ps1
cleanup_test_project.ps1
```

## Prompts

Use numbered snake_case with `.md`.

```text
00_workspace_safety_check.md
01_internal_project_workspace_safety.md
02_run_starter_kit.md
03_prepare_client_delivery.md
04_review_before_export.md
05_cloud_access_guardrails.md
06_existing_internal_repo_review.md
07_naming_and_file_conventions.md
99_cleanup_test_project.md
```

## Cursor Rules

Use numbered snake_case with `.mdc`.

```text
00_workspace_safety.mdc
01_working_model.mdc
02_security_and_secrets.mdc
03_python_project_setup.mdc
04_client_delivery_boundary.mdc
05_azure_access_guardrails.mdc
06_documentation_standards.mdc
07_naming_conventions.mdc
99_project_specific.mdc
```

## Templates

Use snake_case with `.template` (or `.template.md` / `.ps1.template` where a final extension is meaningful).

```text
gitignore_internal.template
gitignore_client.template
env_example.template
config_yaml.template
requirements_txt.template
readme_internal.template.md
readme_client.template.md
internal_workspace_safety_check.ps1.template
```

## Marker Files

Use hidden dotfile marker names.

```text
.cursor_rapid_start_root
.internal_cursor_project_root
.client_delivery_repo_root
```

## Folder Names

Use lowercase folder names. Avoid spaces.

Starter internal repo folders:

```text
data/raw
pipelines
src
scripts
docs
logs
outputs
```

Starter client repo folders:

```text
pipelines
src
scripts
docs
```

## Rules of Thumb

- Do not use spaces in filenames.
- Do not mix hyphen-case and snake_case within the same file category.
- Repos use hyphens.
- Files use underscores.
- Rules and prompts use numeric prefixes.
- Client repos must never contain `.cursor`.
