/-
# Lodge House API v1 — pure model

Server-side formalization of the Lodge House site's browser-local data model
(lean-workers-union.oneapp.dev). Types mirror the localStorage/IndexedDB schemas;
invariants mirror the site's client-side validations. Spec: `docs/API.md`.

Honesty rule preserved: nothing here claims a live check that was not performed —
statuses follow the ChoirUnion Receipt vocabulary (a receipt is data, not proof).
-/

import Union
import ChoirUnion.Authority.Receipt

namespace LodgeHouse

open ChoirUnion (UnionRegistry UnionMembership lookupByMemberId)
open ChoirUnion.Authority (Receipt ReceiptStatus ReceiptVerdict Subject Claim)

/-! ## Inhabited instances for the receipt chain -/

instance : Inhabited Subject := ⟨{ repository := "", commitHash := "", toolchain := "" }⟩
instance : Inhabited Claim := ⟨{ declaration := `LodgeHouse.default }⟩
instance : Inhabited Receipt := ⟨{ subject := default, claim := default, producerMemberId := "" }⟩

/-! ## Profile and workspace -/

/-- Seat slugs: `^[a-z0-9]+(-[a-z0-9]+)*$`, at most 40 chars (site rule). -/
def slugChar (c : Char) : Bool :=
  (c ≥ 'a' ∧ c ≤ 'z') ∨ (c ≥ '0' ∧ c ≤ '9') ∨ c = '-'

/-- Last element of a list, if any. -/
def lastOpt : List Char → Option Char
  | [] => none
  | [c] => some c
  | _ :: rest => lastOpt rest

/-- No leading/trailing dash and no doubled dash, over a character list. -/
def slugDashes (cs : List Char) : Bool :=
  match cs with
  | [] => false
  | c :: _ =>
    c ≠ '-' ∧
    (lastOpt cs).all (fun c => c ≠ '-') ∧
    ¬ (cs.zip (cs.drop 1)).any (fun (a, b) => a = '-' ∧ b = '-')

/-- Seat slugs: `^[a-z0-9]+(-[a-z0-9]+)*$`, at most 40 chars (site rule). -/
def validSlug (s : String) : Bool :=
  s.length ≤ 40 ∧
  s.toList.all slugChar ∧
  slugDashes s.toList

/-- The lodge profile: name, seat, note, icon, photos (all data: URLs). -/
structure Profile where
  name : String
  slug : String
  note : String := ""
  icon : String := ""
  photos : List String := []
  deriving Inhabited

/-- A person on the seats list. -/
structure Person where
  id : String
  name : String
  note : String := ""
  deriving Inhabited

/-- Prepared invitations are drafts until delivered out of band. -/
inductive InvitationStatus where
  | draft | sent | accepted
  deriving DecidableEq, Inhabited

structure Invitation where
  id : String
  person : String
  note : String
  status : InvitationStatus := .draft
  createdAt : String
  deriving Inhabited

/-! ## Tasks -/

inductive TaskStatus where
  | notStarted | inProgress | blocked | done
  deriving DecidableEq, Inhabited

structure Contribution where
  id : String
  person : String
  note : String := ""
  deriving Inhabited

structure Task where
  id : String
  title : String
  description : String := ""
  assigneeId : String := ""
  status : TaskStatus := .notStarted
  notes : String := ""
  contributions : List Contribution := []
  collaborators : List Person := []
  updatedAt : String
  deriving Inhabited

/-! ## Schedules -/

structure Schedule where
  id : String
  title : String
  taskId : String := ""
  date : String
  time : String
  duration : Nat := 60
  notes : String := ""
  participants : List String := []
  createdAt : String
  deriving Inhabited

/-! ## Builds -/

inductive BuildStatus where
  | planning | inProgress | blocked | ready | archived
  deriving DecidableEq, Inhabited

inductive BuildAccess where
  | private_ | inviteLink | publicLink
  deriving DecidableEq, Inhabited

/-- Does `cs` start with the characters `pre`? -/
def startsWithList (cs : List Char) (pre : List Char) : Bool :=
  match cs, pre with
  | _, [] => true
  | [], _ :: _ => false
  | c :: rest, p :: preRest => c = p ∧ startsWithList rest preRest

def safeHttpUrl (s : String) : String :=
  let cs := s.toList
  if startsWithList cs "https://".toList ∨ startsWithList cs "http://".toList then s else ""

structure Build where
  id : String
  title : String
  description : String := ""
  artwork : String := ""
  status : BuildStatus := .planning
  access : BuildAccess := .private_
  link : String := ""
  updatedAt : String
  deriving Inhabited

/-! ## Sharing views -/

inductive ViewSection where
  | people | invitations | tasks | schedules
  deriving DecidableEq, Inhabited

structure View where
  id : String
  name : String
  query : String := ""
  sections : List ViewSection := []
  deriving Inhabited

/-! ## Workspace -/

structure Workspace where
  formatVersion : Nat := 1
  profile : Option Profile := none
  people : List Person := []
  invitations : List Invitation := []
  tasks : List Task := []
  schedules : List Schedule := []
  document : Option String := none
  deriving Inhabited

/-! ## Operations -/

/-- Lowercase a character list (ASCII only — seat names are typed, not parsed).
    The site rejects duplicate seat names case-insensitively. -/
def lowerList : List Char → List Char
  | [] => []
  | c :: rest =>
    (if c ≥ 'A' ∧ c ≤ 'Z' then Char.ofNat (c.toNat + 32) else c) :: lowerList rest

def canAddPerson (w : Workspace) (name : String) : Bool :=
  name ≠ "" ∧ ¬ w.people.any (fun p => lowerList p.name.toList == lowerList name.toList)

/-- Adding a person, if the name is fresh. -/
def addPerson (w : Workspace) (p : Person) : Option Workspace :=
  if canAddPerson w p.name then some { w with people := p :: w.people } else none

/-- Tasks merge by id: contributions append (dedup by id), collaborators dedup by name. -/
def mergeTask (existing : Task) (incoming : Task) : Task :=
  let contribIds := existing.contributions.map (·.id)
  let mergedContribs :=
    existing.contributions ++
    incoming.contributions.filter (fun c => ¬ contribIds.contains c.id)
  let names := existing.collaborators.map (·.name.toLower)
  let mergedCollabs :=
    existing.collaborators ++
    incoming.collaborators.filter (fun p => ¬ names.contains p.name.toLower)
  { existing with
    contributions := mergedContribs
    collaborators := mergedCollabs }

/-- People merge by name (case-insensitive): incoming note wins if present. -/
def mergePerson (existing : Person) (incoming : Person) : Person :=
  { existing with note := if incoming.note ≠ "" then incoming.note else existing.note }

/-- Replace the first element satisfying `p` with `f` applied to it. -/
def replaceWhere (α : Type) (xs : List α) (p : α → Bool) (f : α → α) : List α :=
  xs.map (fun x => if p x then f x else x)

/-- Workspace merge — the semantics of the site's share-link import. -/
def mergeWorkspace (w : Workspace) (incoming : Workspace) : Workspace :=
  let people :=
    incoming.people.foldl (fun acc p =>
      match acc.find? (fun e => e.name.toLower == p.name.toLower) with
      | some _ => replaceWhere Person acc
          (fun e => e.name.toLower == p.name.toLower)
          (fun e => mergePerson e p)
      | none => p :: acc
    ) w.people
  let tasks :=
    incoming.tasks.foldl (fun acc t =>
      match acc.find? (fun e => e.id == t.id) with
      | some _ => replaceWhere Task acc
          (fun e => e.id == t.id)
          (fun e => mergeTask e t)
      | none => t :: acc
    ) w.tasks
  { w with people := people, tasks := tasks }

/-! ## Registry bridge -/

/-- A lodge-table member with a seat gets a workspace keyed by slug. -/
def memberHasSeat (reg : UnionRegistry) (p : Profile) : Bool :=
  (lookupByMemberId reg p.slug).isSome

/-! ## Receipts: the honesty layer -/

/-- A mutating API response: data plus a ChoirUnion receipt.
    Browser-local state is never more than `sketch` unless a fresh
    witness was synthesized (gokujo gate). -/
structure ApiResponse (α : Type) where
  data : α
  receipt : Receipt
  deriving Inhabited

/-- The receipt the API attaches to browser-local (unverified) state. -/
def sketchReceipt (producer : String) : Receipt :=
  { subject := { repository := "lean-workers-union", commitHash := "", toolchain := "" }
    claim := { declaration := `LodgeHouse.browserLocal }
    producerMemberId := producer
    status := .sketch
    verdict := .indeterminate }

/-! ## Well-formedness theorems -/

theorem addPerson_keepsExisting (w : Workspace) (p : Person)
    (h : (addPerson w p).isSome) :
    ∀ q ∈ w.people, ∃ q' ∈ (addPerson w p).get!.people, q'.id = q.id := by
  unfold addPerson at h
  split at h
  · next hcond =>
    intro q hq
    have hw : addPerson w p = some { w with people := p :: w.people } := by
      simp only [addPerson, if_pos hcond]
    refine ⟨q, ?_, rfl⟩
    rw [hw]
    show q ∈ (p :: w.people)
    exact List.mem_cons.mpr (Or.inr hq)
  · contradiction

theorem mergeTask_neverLosesContributions (e i : Task) :
    e.contributions.length ≤ (mergeTask e i).contributions.length := by
  simp only [mergeTask]
  apply Nat.le_trans (Nat.le_refl _)
  simp

/-! ## JSON wire format -/

inductive Json where
  | null
  | bool (b : Bool)
  | str (s : String)
  | arr (items : List Json)
  | obj (fields : List (String × Json))
  deriving Inhabited

/-- Escape the JSON-special characters in a string. -/
def Json.escape (s : String) : String :=
  s.foldl (fun acc c =>
    match c with
    | '"' => acc ++ "\\\""
    | '\\' => acc ++ "\\\\"
    | '\n' => acc ++ "\\n"
    | '\r' => acc ++ "\\r"
    | '\t' => acc ++ "\\t"
    | c => acc.push c) ""

mutual
/-- Render a JSON value to its wire string. -/
def Json.render : Json → String
  | .null => "null"
  | .bool true => "true"
  | .bool false => "false"
  | .str s => "\"" ++ Json.escape s ++ "\""
  | .arr items => "[" ++ Json.renderList items ++ "]"
  | .obj fields => "{" ++ Json.renderFields fields ++ "}"

/-- Render a JSON array's items, comma-separated. -/
def Json.renderList : List Json → String
  | [] => ""
  | [x] => Json.render x
  | x :: xs => Json.render x ++ ", " ++ Json.renderList xs

/-- Render an object's fields, comma-separated. -/
def Json.renderFields : List (String × Json) → String
  | [] => ""
  | [(k, v)] => "\"" ++ Json.escape k ++ "\": " ++ Json.render v
  | (k, v) :: rest =>
    "\"" ++ Json.escape k ++ "\": " ++ Json.render v ++ ", " ++ Json.renderFields rest
end

/-- A build renders to the same JSON the site stores. -/
def buildToJson (b : Build) : Json :=
  .obj [
    ("id", .str b.id),
    ("title", .str b.title),
    ("description", .str b.description),
    ("artwork", .str b.artwork),
    ("status", .str (match b.status with
      | .planning => "Planning" | .inProgress => "In progress" | .blocked => "Blocked"
      | .ready => "Ready" | .archived => "Archived")),
    ("access", .str (match b.access with
      | .private_ => "Private" | .inviteLink => "Invite link" | .publicLink => "Public link")),
    ("link", .str b.link),
    ("updatedAt", .str b.updatedAt)
  ]

end LodgeHouse
