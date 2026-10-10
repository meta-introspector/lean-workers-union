# Use Case: Shared Data Sync Panel

## Overview
Test the shared-data-sync panel functionality.

## Precondition
User opens `/seats/share` page.

## Steps
1. Check if `shared-data-sync.js` is loaded
2. Verify `SharedDataSync.init()` executes without errors
3. Test localStorage keys are accessible

## Expected Results

### OLD SITE (lean-workers-union.oneapp.dev)
- `shared-data-sync.js` is NOT loaded (feature missing)
- No shared data sync functionality available

### NEW SITE (meta-introspector.github.io/lean-workers-union/)
- `shared-data-sync.js` IS loaded
- `SharedDataSync.init()` executes successfully
- LocalStorage keys are accessible:
  - `WORKSPACE_KEY = "lean-worker-seats-tasks-v3"`
  - `LIBRARY_KEY = "lodge-public-link-library-v1"`
  - `INBOX_KEY = "lodge-shared-data-inbox-v1"`
  - `LIMIT_KEY = "lodge-public-link-limit-v1"`

## Test Coverage
| Check | OLD Site | New Site |
|-------|----------|----------|
| JS file loaded | ❌ Not present | ✅ Present |
| `init()` executes | ❌ Not applicable | ✅ Success |
| LocalStorage access | ❌ Not applicable | ✅ All 4 keys available |