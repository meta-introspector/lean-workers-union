import Lean
import ChoirUnion.Authority.Subject
import ChoirUnion.Authority.Claim
import ChoirUnion.Authority.Witness
import ChoirUnion.Authority.ClaimCeiling
import ChoirUnion.Authority.Verdict

namespace ChoirUnion.Authority

/-- ReceiptStatus describes the lifecycle/type of a receipt, not its truth value.
    
    open: A receipt in draft or unfinished form.
    sketch: A receipt with partial evidence or preliminary metadata.
    kernelChecked: A receipt that claims to have been validated by local inspection
                   or an external kernel checker.
    foreign: A receipt received from an external source or untrusted producer.
    
    DO NOT interpret kernelChecked as "this receipt is trustworthy."
    ReceiptStatus is just metadata about the receipt's origin and intent, written by
    whoever constructs the receipt.
    Trust is not determined by status, nor by the receipt's `verdict` field, which is
    also written by the receipt's constructor and is not computed by this package.
    Trust can only come from the consumer's own checks: `evaluateGate` is a local check
    of the receipt data, and independent kernel verification (fresh witness synthesis
    or external replay) is not provided by this package.
--/
inductive ReceiptStatus where
  | open
  | sketch
  | kernelChecked
  | foreign
  deriving Repr, DecidableEq

/-- Receipt is the common envelope for a claim and its evidence.
    
    It carries:
    - subject: what artifact this receipt is about
    - claim: what is being asserted
    - claimCeiling: optional upper bound on the scope of the claim
    - producerMemberId: which union member produced this receipt (for authorization)
    - witness: optional structured metadata claimed by the producer
      (e.g., axioms used, sorry count)
    - status: lifecycle status (open, sketch, kernelChecked, foreign)
    - verdict: intended epistemic label after evaluation (attested, falsified,
      indeterminate); a plain field, not computed by this package and not read
      by `evaluateGate`
    - evidenceDigest: optional hash/digest of supporting evidence
    
    A receipt is always just data. Every field, including status, verdict and
    witness, is supplied by whoever constructs the receipt. It is a claim, not proof,
    until validated by a trusted local policy and environment.
--/
structure Receipt where
  subject : Subject
  claim : Claim
  claimCeiling : Option ClaimCeiling := none
  producerMemberId : String
  witness : Option ReplayWitness := none
  status : ReceiptStatus := ReceiptStatus.open
  verdict : ReceiptVerdict := ReceiptVerdict.indeterminate
  evidenceDigest : Option String := none
  deriving Repr, DecidableEq

end ChoirUnion.Authority
