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
- **ReceiptVerdict**: epistemic confidence label (attested, falsified, indeterminate); a plain receipt field, not computed by this package
- **ClaimCeiling**: optional bounded-claim specification
- **GateCondition**: expected subject, claim, and allowed axioms
- **evaluateGate**: pure syntactic validation predicate
- **ReplayProvenance**: audit metadata for builds and replay results (defined only; not a field of `Receipt` and not read by `evaluateGate`)
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
toolchain : String
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

`ReceiptVerdict` is a separate label:
```lean
inductive ReceiptVerdict where
  | attested      -- intended: passed local gate; accepted as evidence
  | falsified     -- intended: failed verification
  | indeterminate -- intended: not yet evaluated (the default)
```

The separation is meant to prevent the conceptual collapse:
```
kernelChecked ≠ attested
```

However, trust is **not** determined by `ReceiptVerdict`. `verdict` is an ordinary field of `Receipt`, written by whoever constructs the receipt. No function in this package computes or updates it, and `evaluateGate` does not read it. A `verdict` read from a received receipt is a producer-supplied claim, exactly like `status`. It carries meaning only if the local evaluator sets it itself after its own checks; consumers should ignore or reset the `verdict` of any receipt they did not construct.

### 4. evaluateGate is Pure Syntactic Validation

```lean
def evaluateGate (condition : GateCondition) (receipt : Receipt) : Bool
```

This checks only whether the receipt data structurally matches the condition. It returns `true` exactly when all four hold:
- `status` is `kernelChecked`
- `subject` equals `expectedSubject`
- `claim` equals `expectedClaim`
- a witness is **present** and is clean relative to the condition's `allowedAxioms` (a missing witness fails the gate)

The allowed axiom list comes from the `GateCondition`, not from the receipt.

It does **not**:
- inspect the current Lean environment
- run independent replay
- verify signatures
- perform I/O
- read `verdict`, `producerMemberId`, `claimCeiling` or `evidenceDigest`
- tie the witness to the claimed declaration (`ReplayWitness` has no declaration name field)

Every value it compares — the status label, subject, claim and witness — is supplied by the receipt's producer. Passing `evaluateGate` is therefore **not** equivalent to independent kernel verification: a receipt whose producer simply writes `status := kernelChecked` and a clean-looking witness passes without any Lean environment being consulted. The theorem `evaluateGate_sound` only restates these Boolean checks.

### 5. Capabilities ≠ Authority

```lean
def mayRequestReceipt
    (memberId : String)
    (memberCapabilities : List String)
    (memberRole : String)
    (policy : ReceiptAuthorizationPolicy) : Bool
```

This evaluates whether a member satisfies the authorization policy. It determines who can request or publish receipts, not what is true.

Authority requires both:
1. `mayRequestReceipt = true` — the member is authorized to speak
2. `evaluateGate condition receipt = true` — the receipt data matches the local gate condition

No function in this package combines these two checks; consumers must call both. Neither check establishes that the claimed proof was actually checked.

### 6. ClaimCeiling Bounds the Claim

```lean
structure ClaimCeiling where
  description : String
  digest : String
```

Optionally attached to a receipt, `ClaimCeiling` specifies an upper bound on what the claim is allowed to assert. This enables the bounded-claim model: a receipt can assert a declaration, but only within the specification boundary the trusted policy permits.

### 7. Producer-Supplied Claims vs. Independently Established Evidence

Producer-supplied claims (everything inside a `Receipt`):
- `subject`, `claim`, `claimCeiling`, `producerMemberId`
- `witness` (`declarationFound`, `isTheorem`, `sorryCount`, `usedAxioms`)
- `status` and `verdict`
- `evidenceDigest`

Established locally by this package:
- whether those fields match a trusted `GateCondition` (`evaluateGate`), and whether a member ID, capability list and role satisfy a policy (`mayRequestReceipt`)

Independently established evidence (not provided by this package):
- a witness synthesized fresh from the consumer's own Lean environment
- an independent replay by an external checker such as `lean4checker`
- a binding of `subject` to actual artifact bytes, or a verified signature

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

3. **Local Gate Check**:  
   Create fresh `Receipt` with the new witness, evaluate `evaluateGate` (this checks data consistency only; the evidence value comes from step 2)

4. **Independent Replay** (CI):  
   Run `lean4checker` over `.olean` artifacts

5. **Transport** (if needed):  
   Serialize receipt (future with signatures)

6. **Remote Verification** (if needed):  
   Either:
   - Re-run your own `synthesizeWitness` + `evaluateGate` locally (`synthesizeWitness` is not provided by this package; see "Not Yet Implemented"), or
   - Verify a cryptographic signature (not yet implemented)

   Running `evaluateGate` on a received receipt alone is not remote verification.

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
    producerMemberId := "copilot"
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
├── lean-toolchain              # Pinned to leanprover/lean4:v4.28.0
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
│   └── build-site.sh           # Site build (no replay script is included; replay is project-local)
├── .github/workflows/
│   └── main.yml                # CI definition (builds and runs the pure tests; no replay checker)
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

- Lean 4.28.0 (pinned in `lean-toolchain`)
- Portable to projects using the `ChoirUnion.Authority` namespace
