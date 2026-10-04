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

instance : Repr ReplayProvenance := ⟨fun p =>
  "{ subject := " ++ repr p.subject ++
  ", checker := " ++ repr p.checker ++
  ", checkerVersion := " ++ repr p.checkerVersion ++
  ", result := " ++ repr p.result ++
  ", fresh := " ++ repr p.fresh ++
  ", buildLogDigest := " ++ repr p.buildLogDigest ++
  ", replayLogDigest := " ++ repr p.replayLogDigest ++
  ", signer := " ++ repr p.signer ++ " }"⟩

instance : DecidableEq ReplayProvenance := by
  intro a b
  cases a with
  | mk subjectA checkerA versionA resultA freshA buildA replayA signerA =>
      cases b with
      | mk subjectB checkerB versionB resultB freshB buildB replayB signerB =>
          simp [subjectA, checkerA, versionA, resultA, freshA, buildA, replayA, signerA,
            subjectB, checkerB, versionB, resultB, freshB, buildB, replayB, signerB]

end ChoirUnion.Authority
