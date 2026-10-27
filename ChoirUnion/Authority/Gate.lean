import Lean
import ChoirUnion.Authority.Subject
import ChoirUnion.Authority.Claim
import ChoirUnion.Authority.Witness
import ChoirUnion.Authority.Receipt
import ChoirUnion.Authority.Verdict

namespace ChoirUnion.Authority

/-- GateCondition specifies the trusted expectations for a receipt.
    
    This must be constructed by trusted local policy, never by an untrusted receipt
    producer. This package does not enforce that; it is the caller's responsibility.
    The condition's allowedAxioms override any axiom list in the receipt.
--/
structure GateCondition where
  /-- The expected subject this receipt must match. --/
  expectedSubject : Subject
  /-- The expected claim this receipt must assert. --/
  expectedClaim : Claim
  /-- The axioms this condition permits. Receipt witness must use only these. --/
  allowedAxioms : List Lean.Name
  deriving Repr, DecidableEq

/-- Pure syntactic matching: receipt subject matches the condition's expected subject. --/
def subjectMatches (condition : GateCondition) (receipt : Receipt) : Bool :=
  receipt.subject == condition.expectedSubject

/-- Pure syntactic matching: receipt claim matches the condition's expected claim. --/
def claimMatches (condition : GateCondition) (receipt : Receipt) : Bool :=
  receipt.claim == condition.expectedClaim

/-- Pure syntactic validation: the receipt must provide a witness, and that
    witness must be clean relative to the condition's allowed axioms.
    A missing witness fails this check.
--/
def witnessAllows (condition : GateCondition) (receipt : Receipt) : Bool :=
  receipt.witness.isSome &&
  receipt.witness.all (fun w => clean w condition.allowedAxioms)

/-- evaluateGate is a pure predicate that checks whether a receipt passes
    the syntactic acceptance criteria of a condition.
    
    It does NOT claim that the receipt was independently verified.
    It only checks:
    - receipt status is `kernelChecked`, i.e. the producer claims kernel checking
      was performed (the status itself is not verified)
    - receipt subject matches the expected subject
    - receipt claim matches the expected claim
    - receipt witness is present and clean relative to the condition's allowed axioms
      (a missing witness fails the gate)

    It does not read `verdict`, `producerMemberId`, `claimCeiling` or `evidenceDigest`,
    and it does not tie the witness to the claimed declaration.
    
    This is a pure function: Bool. It does not perform I/O, environment inspection,
    or verify anything external. It only validates the structural consistency
   of the data. The receipt fields are producer-supplied and are compared
against trusted local gate conditions. Passing this gate checks local
consistency; it does not establish independent kernel verification.
    
    For actual evidence, the evaluating code must (none of this is provided by this
    package):
    - synthesize a fresh witness from the current Lean environment
    - run an independent replay via lean4checker
    - verify cryptographic signatures (when implemented)
--/
def evaluateGate (condition : GateCondition) (receipt : Receipt) : Bool :=
  receipt.status == ReceiptStatus.kernelChecked &&
  subjectMatches condition receipt &&
  claimMatches condition receipt &&
  witnessAllows condition receipt

/-- Soundness of the gate: if evaluateGate returns true, then the receipt
    satisfies all the structural conditions.
    
    This theorem proves only what the Boolean gate checks: data consistency.
    It does not prove that the receipt was independently generated or is trustworthy.
--/
theorem evaluateGate_sound (condition : GateCondition) (receipt : Receipt) :
    evaluateGate condition receipt = true →
      receipt.status == ReceiptStatus.kernelChecked ∧
      receipt.subject == condition.expectedSubject ∧
      receipt.claim == condition.expectedClaim ∧
      receipt.witness.isSome ∧
      ∀ w ∈ receipt.witness, clean w condition.allowedAxioms = true := by
  intro h
  unfold evaluateGate subjectMatches claimMatches witnessAllows at h
  simp only [Bool.and_eq_true, Option.all_eq_true, and_assoc] at h
  simpa using h

end ChoirUnion.Authority
