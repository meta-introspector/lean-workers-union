# Use Case: Responsive Layout Testing

## Overview
Test responsive layout across different device sizes.

## Precondition
User views site on mobile, tablet, or desktop.

## Steps
1. Resize browser window to mobile width (<640px)
2. Verify navigation remains accessible
3. Check content wraps properly without horizontal scrolling

## Expected Results

### OLD SITE (lean-workers-union.oneapp.dev)
- Fully responsive layout with adaptive hero section
- Navigation adjusts for mobile (hamburger menu or stacked layout)
- Content wraps properly without horizontal scrolling

### NEW SITE (meta-introspector.github.io/lean-workers-union/)
- Basic responsive layout with content stacking vertically
- Navigation may wrap but lacks sophisticated mobile adaptations
- Content remains readable but lacks mobile-optimized features

## Test Coverage
| Viewport Size | OLD Site | New Site |
|---------------|----------|----------|
| Desktop (>1024px) | ✅ Full layout | ✅ Basic layout |
| Tablet (640-1024px) | ✅ Adaptive layout | ✅ Stacked layout |
| Mobile (<640px) | ✅ Mobile-optimized | ✅ Basic stacked |
