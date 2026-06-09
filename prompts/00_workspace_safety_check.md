# 00 - Workspace Safety Check

Before running any Cursor Rapid Start prompt, verify the active workspace.

## Expected Workspace

`C:\Users\SivaK\OneDrive\clientrepos\cursor-rapid-start`

## Expected Root Folder

`cursor-rapid-start`

## Required Marker File

`.cursor_rapid_start_root`

## Required Checks

Run or verify:

```powershell
pwd
git remote -v
Test-Path .\.cursor_rapid_start_root
```

Expected result:

* `pwd` points to `C:\Users\SivaK\OneDrive\clientrepos\cursor-rapid-start`
* Git remote points to the `cursor-rapid-start` GitHub repo
* Marker check returns `True`

If any check fails, stop immediately.

Do not create, modify, delete, or move files until the correct workspace is open.
