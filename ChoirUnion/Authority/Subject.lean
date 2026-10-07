import Lean

namespace ChoirUnion.Authority

/-- Provenance: where a build happened. -/
structure Subject where
  repository : String
  commitHash : String
  toolchain : String
  deriving DecidableEq

instance : Repr Subject :=
  ⟨fun s _ => "{ repository := " ++ reprStr s.repository ++ ", commitHash := "
    ++ reprStr s.commitHash ++ ", toolchain := " ++ reprStr s.toolchain ++ " }"⟩

end ChoirUnion.Authority
