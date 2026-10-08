import LodgeHouse.Site

/-!
# Site generator executable

`lake exe lodge-gen -- out-dir base-url` writes the static Lodge House site,
the workspace JSON backup, and demo invite/reply share links — all computed
in Lean, all from the recursive `Lodge` tree.
-/

namespace LodgeHouse

open Lean Elab Command

/-- The lodge: the real site's page map, as one recursive tree. -/
def theLodge : Lodge :=
  .hall "Lean-Workers Union Lodge House" [
    .page "seats.html" "My profile, invites & tasks"
      "<h1>Seats</h1><p>Profile, invitations, tasks — the browser-local workspace.</p>",
    .page "capabilities.html" "Capabilities" "<h1>Capabilities</h1>",
    .page "protocol.html" "Protocol" "<h1>Protocol</h1>",
    .page "proof-model.html" "Proof model" "<h1>Proof model</h1>",
    .page "repositories.html" "Repositories" "<h1>Repositories</h1>",
    .page "plugins.html" "Plugins" "<h1>Plugins</h1>",
    .page "skill-registry.html" "Skill registry" "<h1>Skill registry</h1>",
    .page "tours.html" "Tours" "<h1>Tours</h1>",
    .page "training-log.html" "Training log" "<h1>Training log</h1>",
    .page "unit-tests.html" "Unit tests" "<h1>Unit tests</h1>",
    .page "archive.html" "Archive" "<h1>Archive</h1>",
    .page "n00b-guide.html" "n00b guide" "<h1>n00b guide</h1>",
    .page "union-roadmap.html" "Union roadmap" "<h1>Union roadmap</h1>",
    .page "nixwars-arcade.html" "NixWars arcade" "<h1>NixWars arcade</h1>",
    .wing "seats" "Profile sharing" [
      .page "share.html" "Share a profile"
        "<h1>Share</h1><p>Create an invite link; bring the reply back.</p>"
    ],
    .wing "union-roadmap" "Roadmap search" [
      .page "search.html" "Search" "<h1>Search</h1>",
      .page "enrichment.html" "Enrichment" "<h1>Enrichment</h1>"
    ]
  ]

/-- A demo workspace: the union's founding members. -/
def demoWorkspace : Workspace :=
  { profile := some (Profile.mk "Lean-Workers Union" "lean-workers-union"
      "Generated in recursive Lean. The lodge is a tree." "" []),
    people := [
      Person.mk "person-aristotle" "aristotle" "",
      Person.mk "person-kant" "kant" "",
      Person.mk "person-copilot" "copilot" ""
    ],
    tasks := [
      { id := "task-port", title := "Port the Lodge House to Lean",
        assigneeId := "person-aristotle", status := .inProgress,
        contributions := [Contribution.mk "c1" "aristotle" "API implemented, gokujo-clean."],
        updatedAt := "2026-10-07" : Task }
    ] }

/-- The site's stylesheet, embedded so the generator is self-contained. -/
def themeCss : String := include_str "theme.css"

/-- Write one (path, contents) pair to disk under `outDir`. -/
def writeFilePair (outDir : String) (path : String) (contents : String) : IO Unit := do
  IO.FS.createDirAll outDir
  let full := outDir ++ "/" ++ path
  -- create parent directories
  let parts := (path.splitOn "/").dropLast
  let mut acc := ""
  for dir in parts do
    acc := acc ++ "/" ++ dir
    IO.FS.createDirAll (outDir ++ acc)
  IO.FS.writeFile full contents

end LodgeHouse

open LodgeHouse in
def main (args : List String) : IO UInt32 := do
  let outDir := args.getD 0 "site"
  let baseUrl := args.getD 1 "https://lean-workers-union.oneapp.dev"
  IO.println s!"lodge-gen: writing site to {outDir}"
  -- 1. the static site, from the recursive tree
  for (path, contents) in renderLodge theLodge do
    writeFilePair outDir path contents
    IO.println s!"  {path}"
  -- 1b. the theme
  IO.FS.writeFile (outDir ++ "/theme.css") themeCss
  IO.println "  theme.css"
  -- 2. the workspace JSON backup
  let wsJson := Json.render (workspaceJson demoWorkspace)
  IO.FS.writeFile (outDir ++ "/workspace.json") wsJson
  IO.println "  workspace.json"
  -- 3. share links
  let invite : InvitePayload := InvitePayload.mk "invite-demo-1"
    ((demoWorkspace.profile).getD default) "Welcome to the lodge." ""
  let inviteLink := inviteUrl (baseUrl ++ "/seats/share.html") invite
  let reply : ReplyPayload := ReplyPayload.mk "invite-demo-1" "Lean-Workers Union"
    "aristotle" "The lodge is constructed. It is a tree." ""
  let replyLink := replyUrl (baseUrl ++ "/seats/share.html") reply
  IO.FS.writeFile (outDir ++ "/share-links.txt")
    (s!"# Invite link (anyone with the link can read it)\n{inviteLink}\n\n" ++
     s!"# Reply link\n{replyLink}\n")
  IO.println "  share-links.txt"
  -- 4. verify the round-trip before declaring victory
  match decodeInviteUrl inviteLink with
  | some s => IO.println s!"invite round-trip OK ({s.length} chars)"
  | none => do
      IO.println "ERROR: invite round-trip FAILED"
      return 1
  match decodeReplyUrl replyLink with
  | some s => IO.println s!"reply round-trip OK ({s.length} chars)"
  | none => do
      IO.println "ERROR: reply round-trip FAILED"
      return 1
  IO.println "lodge-gen: done."
  return 0

