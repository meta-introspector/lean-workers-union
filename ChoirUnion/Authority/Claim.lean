import Lean

namespace ChoirUnion.Authority

structure Claim where
  declaration : Lean.Name

instance : Repr Claim := ⟨fun c => "{ declaration := " ++ repr c.declaration ++ " }"⟩

instance : DecidableEq Claim := by
  intro a b
  cases a with
  | mk da =>
      cases b with
      | mk db =>
          simp [da, db]

end ChoirUnion.Authority
