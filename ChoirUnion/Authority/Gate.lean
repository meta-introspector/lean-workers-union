import Lean
import ChoirUnion.Authority.Subject
import ChoirUnion.Authority.Claim
import ChoirUnion.Authority.Witness
import ChoirUnion.Authority.Receipt
import ChoirUnion.Authority.Verdict

namespace ChoirUnion.Authority

/-- GateCondition specifies the trusted expectations for a receipt.
    
    This is constructed by trusted local policy, never by an untrusted receipt producer.
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

/-- Pure syntactic validation: if the receipt provides a witness,
    it must be clean relative to the condition's allowed axioms.
    A missing witness fails this check.
--/
def witnessAllows (condition : GateCondition) (receipt : Receipt) : Bool :=
  match receipt.witness with
  | some w => clean w condition.allowedAxioms
  | none => false

/-- evaluateGate is a pure predicate that checks whether a receipt passes
    the syntactic acceptance criteria of a condition.
    
    It does NOT claim that the receipt was independently verified.
    It only checks:
    - receipt status indicates kernel checking was attempted
    - receipt subject matches the expected subject
    - receipt claim matches the expected claim
    - receipt witness (if present) is clean relative to the condition's allowed axioms
    
    This is a pure function: Bool. It does not perform I/O, environment inspection,
    or verify anything external. It only validates the structural consistency
    of the data.
    
    For actual evidence, the evaluating code must:
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
      (match receipt.witness with
       | some w => clean w condition.allowedAxioms = true
       | none => False) := by
  intro h
  unfold evaluateGate subjectMatches claimMatches witnessAllows at h
  simp at h
  exact h

end ChoirUnion.Authority
