import Lean
import ChoirUnion.Authority.Subject
import ChoirUnion.Authority.Claim
import ChoirUnion.Authority.Witness
import ChoirUnion.Authority.Receipt

namespace ChoirUnion.Authority

structure GateCondition where
  expectedSubject : Subject
  expectedClaim : Claim
  allowedAxioms : List Lean.Name

instance : Repr GateCondition := ⟨fun c =>
  "{ expectedSubject := " ++ repr c.expectedSubject ++
  ", expectedClaim := " ++ repr c.expectedClaim ++
  ", allowedAxioms := " ++ repr c.allowedAxioms ++ " }"⟩

instance : DecidableEq GateCondition := by
  intro a b
  cases a with
  | mk subjectA claimA allowedA =>
      cases b with
      | mk subjectB claimB allowedB =>
          simp [subjectA, claimA, allowedA, subjectB, claimB, allowedB]

def subjectMatches (condition : GateCondition) (receipt : Receipt) : Bool :=
  receipt.subject == condition.expectedSubject

def claimMatches (condition : GateCondition) (receipt : Receipt) : Bool :=
  receipt.claim == condition.expectedClaim

def witnessAllows (condition : GateCondition) (receipt : Receipt) : Bool :=
  match receipt.witness with
  | some w => clean w condition.allowedAxioms
  | none => false

def evaluateGate (condition : GateCondition) (receipt : Receipt) : Bool :=
  receipt.status == ReceiptStatus.kernelChecked &&
  subjectMatches condition receipt &&
  claimMatches condition receipt &&
  witnessAllows condition receipt

 theorem evaluateGate_sound (condition : GateCondition) (receipt : Receipt) :
    evaluateGate condition receipt = true →
      receipt.status == ReceiptStatus.kernelChecked ∧
      receipt.subject == condition.expectedSubject ∧
      receipt.claim == condition.expectedClaim ∧
      match receipt.witness with
      | some w => clean w condition.allowedAxioms = true
      | none => False := by
  intro h
  unfold evaluateGate at h
  simp at h
  exact h

end ChoirUnion.Authority
