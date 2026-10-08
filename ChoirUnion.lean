import Member
import Union
import ChoirUnion.Authority.Subject
import ChoirUnion.Authority.Claim
import ChoirUnion.Authority.Profile
import ChoirUnion.Authority.Witness
import ChoirUnion.Authority.ClaimCeiling
import ChoirUnion.Authority.Verdict
import ChoirUnion.Authority.Receipt
import ChoirUnion.Authority.Gate
import ChoirUnion.Authority.Provenance
import ChoirUnion.Authority.Authorization

/-!
# ChoirUnion

ChoirUnion is a shared trust vocabulary and portable evidence envelope.

It provides:
- Member and Union: registry and role model
- Authority: common data structures for claims, evidence, and policy

ChoirUnion defines the vocabulary and pure predicates.
Consuming projects are responsible for:
- synthesizing fresh witnesses from their Lean environments
- evaluating gates using local trusted policy
- performing independent replay via lean4checker
- verifying cryptographic signatures (future)
-/
