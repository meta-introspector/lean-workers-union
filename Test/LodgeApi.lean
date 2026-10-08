import LodgeHouse.Api
import LodgeHouse.Base64
import LodgeHouse.Share
import LodgeHouse.Site
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

-- Base64url: RFC 4648 test vectors (URL-safe, unpadded)
example : LodgeHouse.base64url "foobar" = "Zm9vYmFy" := by decide
example : LodgeHouse.base64url "foob" = "Zm9vYg" := by decide
example : LodgeHouse.base64url "fo" = "Zm8" := by decide
example : LodgeHouse.base64url "f" = "Zg" := by decide
example : LodgeHouse.base64url "hello" = "aGVsbG8" := by decide
-- round trips, including multibyte UTF-8
example : LodgeHouse.base64urlDecode (LodgeHouse.base64url "hello lodge")
  = some "hello lodge" := by decide
example : LodgeHouse.base64urlDecode (LodgeHouse.base64url "héllo")
  = some "héllo" := by decide

-- Share links: encode → URL → decode round trip
def testProfile : LodgeHouse.Profile :=
  { name := "mike", slug := "mike", note := "from lean" }
def testInvite : LodgeHouse.InvitePayload :=
  { invitationId := "i1", profile := testProfile, prompt := "join" }
-- inviteUrl/decode use String.splitOn (opaque to the kernel), so this is
-- checked at elaboration time instead of by `decide`.
#guard LodgeHouse.decodeInviteUrl
    (LodgeHouse.inviteUrl "https://x.dev/s.html" testInvite)
  == some (LodgeHouse.Json.render (LodgeHouse.invitePayloadJson testInvite))
#guard LodgeHouse.hashParam "invite" "https://x.dev/s.html#invite=Zm8" == some "Zm8"
#guard LodgeHouse.hashParam "response" "https://x.dev/s.html#invite=Zm8" == none

-- The recursive lodge renders every room
def miniLodge : LodgeHouse.Lodge :=
  .hall "Test" [
    .page "a.html" "A" "body a",
    .wing "sub" "Sub" [.page "b.html" "B" "body b"]
  ]
-- String.append is opaque to the kernel, so this one is checked at
-- elaboration time (#guard fails the build if the tree renders wrong).
#guard (LodgeHouse.renderLodge miniLodge).map (·.1) ==
  ["index.html", "a.html", "sub/b.html", "sub/index.html"]
