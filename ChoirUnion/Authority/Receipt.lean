import Lean
import ChoirUnion.Authority.Subject
import ChoirUnion.Authority.Claim
import ChoirUnion.Authority.Witness

namespace ChoirUnion.Authority

inductive ReceiptStatus where
  | open
  | sketch
  | kernelChecked
  | foreign

instance : Repr ReceiptStatus := ⟨fun s => match s with
  | ReceiptStatus.open => "open"
  | ReceiptStatus.sketch => "sketch"
  | ReceiptStatus.kernelChecked => "kernelChecked"
  | ReceiptStatus.foreign => "foreign"⟩

structure Receipt where
  subject : Subject
  claim : Claim
  producerMemberId : String
  witness : Option ReplayWitness
  status : ReceiptStatus
  evidenceDigest : Option String

instance : Repr Receipt := ⟨fun r =>
  "{ subject := " ++ repr r.subject ++
  ", claim := " ++ repr r.claim ++
  ", producerMemberId := " ++ repr r.producerMemberId ++
  ", witness := " ++ repr r.witness ++
  ", status := " ++ repr r.status ++
  ", evidenceDigest := " ++ repr r.evidenceDigest ++ " }"⟩

instance : DecidableEq Receipt := by
  intro a b
  cases a with
  | mk subjectA claimA producerA witnessA statusA digestA =>
      cases b with
      | mk subjectB claimB producerB witnessB statusB digestB =>
          simp [subjectA, claimA, producerA, witnessA, statusA, digestA,
            subjectB, claimB, producerB, witnessB, statusB, digestB]

end ChoirUnion.Authority
