# lean-workers-union

A shared trust vocabulary and portable evidence envelope for Lean declaration authority.

## Overview

This repository defines the `ChoirUnion` namespace, which provides:

1. **Member and Union**: registry and role coordination (existing, unchanged)
2. **Authority**: portable types and pure policy semantics for declaration authority

The authority layer is intentionally minimal. It provides the vocabulary—Subject, Claim, Witness, Receipt, Gate—but does not perform the actual verification. That responsibility belongs to consuming projects.

## Design Boundary

### The Union Layer (This Package)

ChoirUnion owns:
- **Subject**: repository identity, commit hash, toolchain identifier
- **Claim**: declaration identity as `Lean.Name`
- **AxiomProfile**: standard profiles (empty, constructive, classical)
- **ReplayWitness**: portable metadata (declarationFound, isTheorem, sorryCount, usedAxioms)
- **Receipt**: envelope for claim + witness + status + metadata
- **ReceiptStatus**: lifecycle (open, sketch, kernelChecked, foreign)
- **ReceiptVerdict**: epistemic confidence (attested, falsified, indeterminate)
- **ClaimCeiling**: optional bounded-claim specification
- **GateCondition**: expected subject, claim, and allowed axioms
- **evaluateGate**: pure syntactic validation predicate
- **ReplayProvenance**: audit metadata for builds and replay results
- **ReceiptAuthorizationPolicy**: pure policy over member capabilities and roles

### The Consuming Project (Your Lean Repository)

Your project owns:
- `synthesizeWitness : Lean.Name → CoreM ReplayWitness` — environment introspection
- `Lean.collectAxioms`, `getEnv` — metaprogramming operations
- Fresh local witness construction before gating
- `lean4checker` invocation and replay scripts
- Poisoned/hostile test fixtures
- Application-specific expected claims and subjects
- Cryptographic signing keys and verification (future)

## Critical Distinctions

### 1. ReplayWitness is Metadata, Not Proof

```
clean(w, allowedAxioms) = true
  ⟹ w is internally consistent with allowedAxioms
  ⟹ w.usedAxioms ⊆ allowedAxioms
  ⟹ w.sorryCount == 0
  ⟹ w.isTheorem = true
  
clean(w, allowedAxioms) ≠ "Lean independently verified w"
```

A deserialized witness passing `clean()` is still a claim, not evidence, until:
- synthesized fresh from the current Lean environment via `CoreM`, or
- independently verified by an external replay checker, or
- authenticated by a trusted cryptographic signature

### 2. Subject.commitHash is an Asserted Identity

The `Subject` structure holds:
```lean
repository : String
commitHash : String
Toolchain : String
```

`commitHash` is an identity claim, not a cryptographic binding. This package does not:
- verify that the hash corresponds to actual bytes
- establish provenance by connecting the hash to an artifact digest
- provide Git or version control semantics

Those bindings are external:
- **OOB Publication**: trusted source publishes expected `commitHash`
- **CI Provenance**: the consuming project's CI binds the actual checkout SHA
- **Replay Evidence**: independent checker records artifact digests

Together, these form the authority chain.

### 3. ReceiptStatus ≠ Truth Value

```lean
inductive ReceiptStatus where
  | open           -- draft
  | sketch         -- partial
  | kernelChecked  -- claims to have been kernel-validated
  | foreign        -- from untrusted source
```

`ReceiptStatus.kernelChecked` means "this receipt asserts it was checked." It does not mean the receipt is trustworthy.

Trust is determined by `ReceiptVerdict`:
```lean
inductive ReceiptVerdict where
  | attested      -- passed local gate; accepted as evidence
  | falsified     -- failed verification
  | indeterminate -- not yet evaluated
```

The separation prevents the conceptual collapse:
```
kernelChecked ≠ attested
```

### 4. evaluateGate is Pure Syntactic Validation

```lean
def evaluateGate (condition : GateCondition) (receipt : Receipt) : Bool
```

This checks only whether the receipt data structurally matches the condition:
- subject matches
- claim matches
- witness (if present) is clean

It does **not**:
- inspect the current Lean environment
- run independent replay
- verify signatures
- perform I/O

### 5. Capabilities ≠ Authority

```lean
def mayRequestReceipt (member : MemberState) (policy : ReceiptAuthorizationPolicy) : Bool
```

This evaluates whether a member satisfies the authorization policy. It determines who can request or publish receipts, not what is true.

Authority requires both:
1. `mayRequestReceipt = true` — the member is authorized to speak
2. `evaluateGate condition receipt = true` — the evidence meets local trust criteria

### 6. ClaimCeiling Bounds the Claim

```lean
structure ClaimCeiling where
  description : String
  digest : String
```

Optionally attached to a receipt, `ClaimCeiling` specifies an upper bound on what the claim is allowed to assert. This enables the bounded-claim model: a receipt can assert a declaration, but only within the specification boundary the trusted policy permits.

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│ ChoirUnion.Authority (shared vocabulary)                 │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  Subject ──┐                                            │
│            ├─→ Claim ──┐                                │
│  Profile ──┤          ├─→ Receipt ──→ evaluateGate ──→  │
│  Witness ──┤          │                    ↓            │
│            └─→ Provenance ← Verdict        │            │
│                                            │            │
│  Authorization ────────────────→ mayRequest...          │
│                                                          │
└─────────────────────────────────────────────────────────┘
                           ↑
                           │ imports
                           │
              ┌────────────────────────────┐
              │ Member, Union              │
              │ (existing registry model)  │
              └────────────────────────────┘
```

## Consuming Project Flow

1. **Trusted Policy** (local):  
   Construct `GateCondition` with expected `Subject`, `Claim`, `allowedAxioms`

2. **Fresh Synthesis** (CoreM):  
   Call `synthesizeWitness : Lean.Name → CoreM ReplayWitness`

3. **Local Verification**:  
   Create fresh `Receipt` with the new witness, evaluate `evaluateGate`

4. **Independent Replay** (CI):  
   Run `lean4checker` over `.olean` artifacts

5. **Transport** (if needed):  
   Serialize receipt (future with signatures)

6. **Remote Verification** (if needed):  
   Either:
   - Re-run `synthesizeWitness` + `evaluateGate` locally, or
   - Verify a cryptographic signature (not yet implemented)

## Example: Pure Gate Test

```lean
open ChoirUnion.Authority

def sampleCondition : GateCondition :=
  { expectedSubject := { repository := "...", commitHash := "...", toolchain := "..." }
    expectedClaim := { declaration := ``SomeDeclaration }
    allowedAxioms := AxiomProfile.constructive }

def sampleReceipt : Receipt :=
  { subject := sampleCondition.expectedSubject
    claim := sampleCondition.expectedClaim
    producer := "copilot"
    witness := some { declarationFound := true, isTheorem := true, sorryCount := 0, usedAxioms := [``propext] }
    status := ReceiptStatus.kernelChecked
    verdict := ReceiptVerdict.indeterminate
    ... }

example : evaluateGate sampleCondition sampleReceipt = true := by decide
```

## Not Yet Implemented

1. **Serialization**: A structural encoding for `Lean.Name` that never uses `Name.toString`
2. **Signatures**: Cryptographic binding of receipts to trusted builder keys
3. **Fresh Witness Synthesis**: The `synthesizeWitness` implementation (project-local)
4. **Replay Scripts**: `lean4checker` integration (project-local)
5. **Hostile Tests**: Regression fixtures for `native_decide`, `sorryAx`, custom axioms (project-local)

## Repository Structure

```
lean-workers-union/
├── lean-toolchain              # Pinned to leanprover/lean4:v4.22.0
├── lakefile.toml               # Lake build config
├── Member.lean                 # Existing: member identity and role model
├── Union.lean                  # Existing: registry and lookup
├── ChoirUnion.lean             # Root aggregator
├── ChoirUnion/Authority/       # Common authority vocabulary
│   ├── Subject.lean
│   ├── Claim.lean
│   ├── Profile.lean
│   ├── Witness.lean
│   ├── ClaimCeiling.lean
│   ├── Verdict.lean
│   ├── Receipt.lean
│   ├── Gate.lean
│   ├── Provenance.lean
│   └── Authorization.lean
├── Test/
│   └── AuthorityPure.lean      # Pure gate examples
├── scripts/
│   └── check_kernel_replay.sh  # Replay validation (project-local)
├── .github/workflows/
│   └── ci.yml                  # CI definition
└── README.md
```

## Threat Model

This package establishes shared vocabulary. It does not claim to prevent:
- Attacks via `debug.skipKernelTC` (requires independent replay)
- `@[implemented_by]` + `native_decide` attacks (requires independent replay)
- Compromised build artifacts (requires cryptographic signatures)
- Untrusted remote receipts (requires local re-admission or signatures)

Defenses against these threats belong in:
- The consuming project's `lean4checker`-based CI
- Cryptographic signature schemes (future)
- Local re-admission workflows

## Compatibility

- Lean 4.22.0 (pinned in `lean-toolchain`)
- Portable to projects using the `ChoirUnion.Authority` namespace
