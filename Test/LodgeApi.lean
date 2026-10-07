import LodgeHouse.Api
import Member
import Union

/-! Tests for the Lodge House API pure model. -/

open LodgeHouse ChoirUnion

-- slug validation (site rule: ^[a-z0-9]+(-[a-z0-9]+)*$, ≤ 40)
example : validSlug "kant" := by decide
example : validSlug "lean-worker-42" := by decide
example : ¬ validSlug "-kant" := by decide
example : ¬ validSlug "kant--" := by decide
example : ¬ validSlug "Kant" := by decide

-- safeHttpUrl mirrors the site's URL gate
example : safeHttpUrl "https://solana.solfunmeme.com" == "https://solana.solfunmeme.com" := by decide
example : safeHttpUrl "javascript:alert(1)" == "" := by decide
example : safeHttpUrl "data:text/html,hi" == "" := by decide

-- duplicate person names are rejected, case-insensitively
def w1 : Workspace := { people := [{ id := "person-1", name := "Aristotle" }] }

example : (addPerson w1 { id := "person-2", name := "aristotle" }).isNone := by decide
example : (addPerson w1 { id := "person-2", name := "Kant" }).isSome := by decide

-- share-link merge: contributions dedup by id, append the rest
def contrib (id : String) : Contribution := { id := id, person := "p" }

def tExisting : Task := { id := "task-1", title := "T", contributions := [contrib "c1"], updatedAt := "2026-10-07T00:00:00Z" }
def tIncoming : Task := { id := "task-1", title := "T", contributions := [contrib "c1", contrib "c2"], updatedAt := "2026-10-07T01:00:00Z" }

example : (mergeTask tExisting tIncoming).contributions.length = 2 := by decide
example : (mergeTask tExisting tIncoming).contributions.any (fun c => c.id == "c2") := by decide

-- registry bridge: a seat slug must be a registered member
example : ¬ memberHasSeat lodgeTableRegistry { name := "x", slug := "nobody" } := by decide
