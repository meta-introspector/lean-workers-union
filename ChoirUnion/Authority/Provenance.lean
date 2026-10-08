import Lean
import ChoirUnion.Authority.Subject
import ChoirUnion.Authority.Claim

namespace ChoirUnion.Authority

structure ReplayProvenance where
  subject : Subject
  checker : String
  checkerVersion : String
  result : Bool
  fresh : Bool
  buildLogDigest : String
  replayLogDigest : String
  signer : Option String := none

deriving instance DecidableEq for ReplayProvenance

instance : Repr ReplayProvenance := ⟨fun p _ =>
  "{ subject := " ++ repr p.subject ++
  ", checker := " ++ reprStr p.checker ++
  ", checkerVersion := " ++ reprStr p.checkerVersion ++
  ", result := " ++ toString p.result ++
  ", fresh := " ++ toString p.fresh ++
  ", buildLogDigest := " ++ reprStr p.buildLogDigest ++
  ", replayLogDigest := " ++ reprStr p.replayLogDigest ++
  ", signer := " ++ toString p.signer ++ " }"⟩

end ChoirUnion.Authority
