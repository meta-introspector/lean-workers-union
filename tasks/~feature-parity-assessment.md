# Use Case: Feature Parity Assessment

## Overview
Compare feature sets between old site and new site.

## Precondition
Compare old site feature set vs new site.

## Steps
1. List all interactive elements on old site
2. Verify equivalent elements exist on new site
3. Document missing features and their impact

## Expected Results

### OLD SITE (lean-workers-union.oneapp.dev) - Full Featured Application
- ✅ Hero section with SVG illustration
- ✅ Tailwind CSS styled components
- ✅ Styled buttons with hover effects
- ✅ Navigation menus with dropdowns
- ✅ Forms and interactive elements
- ✅ Hero section with Kant/Aristotle SVG
- ✅ SVG illustrations and decorative elements
- ✅ Responsive grid layout
- ✅ Custom CSS variables for theming

### NEW SITE (meta-introspector.github.io/lean-workers-union/) - Minimalist Content Site
- ❌ Hero section
- ❌ SVG illustrations
- ❌ Styled buttons (only plain links)
- ❌ Dropdown menus
- ❌ Forms
- ❌ SVG illustrations
- ❌ Responsive grid (basic stacking only)
- ❌ Custom CSS theming

## Preserved Features (Both Sites)
- ✅ Page navigation links
- ✅ Basic content structure
- ✅ `seats/share` page with shared-data-sync panel (NEW site only)

## Feature Gap Impact
| Feature Category | Impact |
|-----------------|--------|
| Visual Identity | HIGH - Brand identity lost |
| User Engagement | HIGH - No hero/CTA sections |
| Interactivity | HIGH - No forms, buttons, dropdowns |
| Navigation | MEDIUM - Flat structure vs hierarchical |
| Accessibility | MEDIUM - Reduced semantic structure |