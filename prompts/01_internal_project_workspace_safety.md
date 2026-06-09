# Internal Project Workspace Safety Check

Before running any project-specific Cursor prompt, verify that the active workspace is the correct internal repo.

## Required Checks

Run or verify:

```powershell
pwd
Test-Path .\.internal_cursor_project_root
```

Expected:

* `pwd` points to the intended internal repo path
* `.internal_cursor_project_root` exists
* The current repo is not the client delivery repo
* The current repo is not `cursor-rapid-start`
* The current repo is not another project

If any check fails, stop immediately.

Do not create, modify, delete, or move files until the correct internal workspace is open.
