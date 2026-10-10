# Use Case: Navigation Link Testing

## Overview
Test navigation link functionality across both site versions.

## Precondition
User is on the homepage.

## Steps
1. Navigate to each top-level menu item
2. Verify page loads without 404 errors
3. Test deep links (e.g., `/seats/share`)

## Expected Results

### OLD SITE (lean-workers-union.oneapp.dev)
- All 15+ links work with full navigation including deep links
- Deep links like `/seats#builds`, `/seats/share`, `/union-roadmap/search` resolve correctly

### NEW SITE (meta-introspector.github.io/lean-workers-union/)
- 12 links work, but deep links may fail to resolve
- Navigation is flat (no section anchors in URLs)

## Test Coverage
| URL Pattern | Old Site | New Site |
|-------------|----------|----------|
| `/` | ✅ Works | ✅ Works |
| `/capabilities` | ✅ Works | ✅ Works (`capabilities.html`) |
| `/seats/share` | ✅ Works (deep link) | ✅ Works (`seats/index.html`) |
| `/union-roadmap/search` | ✅ Works | ❌ May fail |
