# lean-workers-union

A minimal scaffold for the `ChoirUnion` registry and authority vocabulary.

## Status

This repository is intentionally a small, shared trust vocabulary package. It keeps the existing
`Member.lean` and `Union.lean` files in place, while providing a common authority layer that is
portable and reusable by integrating Lean projects.

## Authority package

The `ChoirUnion.Authority` namespace provides common, pure data definitions for:

- `Subject`: repository identity, immutable commit hash, and toolchain
- `Claim`: exact Lean declaration identity as a `Lean.Name`
- `AxiomProfile`: standard profiles such as empty, constructive, and classical
- `ReplayWitness`: declaration status, theorem-vs-def status, sorry flag, and used axioms
- `Receipt`: shared envelope metadata for a claim and evidence summary
- `GateCondition`: expected subject, expected claim, and allowed axioms
- `ReplayProvenance`: build/replay provenance for CI or local verification
- `ReceiptAuthorizationPolicy`: pure policy metadata for issuer/member authorization

These structures are deliberately portable and do not perform Lean metaprogramming or environment
inspection. Fresh local witness synthesis, local policy construction, and independent `lean4checker`
replay remain the responsibility of the consuming project or build pipeline.

## Design boundary

The shared union library does not claim that a receipt, witness, or provenance record is authoritative
by itself. A deserialized or transmitted receipt is still a claim until it is re-evaluated in a trusted
local environment or verified with a valid trust-rooted signature scheme.

## Notes

- `lean-toolchain` is pinned to `leanprover/lean4:v4.22.0`.
- The existing `Member.lean` and `Union.lean` files remain the source of registry and role truth.
- The authority layer is intentionally separate from the registry and does not replace it.
