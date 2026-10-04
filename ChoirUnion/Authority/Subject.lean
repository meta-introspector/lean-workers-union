import Lean

namespace ChoirUnion.Authority

structure Subject where
  repository : String
  commitHash : String
  toolchain : String

instance : Repr Subject := ⟨fun s => "{ repository := " ++ repr s.repository ++ ", commitHash := " ++ repr s.commitHash ++ ", toolchain := " ++ repr s.toolchain ++ " }"⟩

instance : DecidableEq Subject := by
  intro a b
  cases a with
  | mk repoA hashA toolA =>
      cases b with
      | mk repoB hashB toolB =>
          simp [repoA, hashA, toolA, repoB, hashB, toolB]

end ChoirUnion.Authority
