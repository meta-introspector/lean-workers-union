# Lodge House gui2proof Plan

## Goal

Apply the gui2lean4 formal verification pipeline to the Lean Workers Union Lodge House site,
proving that the generated visual representations are honest — the rendered HTML faithfully
represents the source Lodge tree definition, with zero hard-coded values that contradict
the recursive generation.

## Current State

- **Site generator**: `LodgeHouse/Gen.lean` — recursive Lean tree → static HTML
- **Pages**: 15 HTML files in `site-out/`, total ~5KB
- **Theme**: `theme.css` — warm earthy palette with high-contrast mode
- **Proof model**: `LodgeHouse/Api.lean` — Share.lean, Provenance vocabulary

## Approach

Since the site is fully static (no dynamic API server), the gui2proof approach is:

1. **Snapshot**: Capture the generated HTML pages
2. **Extract**: Parse the a11y tree from each page
3. **Compare**: Verify rendered values match the source Lodge tree definition
4. **Prove**: Generate Lean 4 provenance theorems

## Pages to Prove

| Page | Source Lodge Room | Content |
|------|-------------------|---------|
| index.html | `theLodge` (hall) | 17 nav links to pages + wings |
| seats.html | wing "seats" | Profile, invites, tasks |
| capabilities.html | leaf | Capabilities listing |
| protocol.html | leaf | Protocol description |
| proof-model.html | leaf | Proof model explanation |
| repositories.html | leaf | Repository listing |
| plugins.html | leaf | Plugin listing |
| skill-registry.html | leaf | Skill registry |
| tours.html | leaf | Tours |
| training-log.html | leaf | Training log |
| unit-tests.html | leaf | Unit tests |
| archive.html | leaf | Archive |
| n00b-guide.html | leaf | n00b guide |
| union-roadmap.html | leaf | Union roadmap |
| nixwars-arcade.html | leaf | NixWars arcade |
| cli.html | leaf | CLI documentation |
| seats/index.html | wing "seats" | Profile sharing sub-pages |
| union-roadmap/index.html | wing "union-roadmap" | Roadmap search |

## Key Theorems

1. **structural integrity**: every page in `site-out/` corresponds to a Room in `theLodge`
2. **no orphan pages**: no HTML file exists in `site-out/` without a matching Lodge Room
3. **no extra pages**: every Lodge Room produces exactly one HTML file
4. **navigation completeness**: the index page contains links to all rooms
5. **theme consistency**: all pages reference the same theme.css
