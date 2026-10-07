import Lean

namespace ChoirUnion.Authority

/-- A claim names a Lean declaration. -/
structure Claim where
  declaration : Lean.Name
  deriving DecidableEq

instance : Repr Claim :=
  ⟨fun c _ => "{ declaration := " ++ toString (repr c.declaration) ++ " }"⟩

end ChoirUnion.Authority
