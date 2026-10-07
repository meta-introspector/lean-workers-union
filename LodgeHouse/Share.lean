import LodgeHouse.Base64

/-!
# Share links

The site's share pipeline, ported to Lean:

* an invitation payload is rendered as JSON, UTF-8-encoded, base64url'd, and
  appended to the page URL as `#invite=<payload>`;
* a reply payload uses the same encoding with `#response=<payload>`;
* a workspace exports as the `lean-worker-seats-tasks-v3` JSON backup.

Anyone with a link can read its contents — the payload *is* the message.
-/

namespace LodgeHouse

/-! ## Payloads -/

/-- The site's payload kind tags. -/
def profileShareKind : String := "lodge-profile-invite-v1"
def replyKind : String := "lodge-invitation-reply-v1"

/-- An invitation payload: a profile, an optional prompt, sent to one guest. -/
structure InvitePayload where
  invitationId : String
  profile : Profile
  prompt : String := ""
  createdAt : String := ""
  deriving Inhabited

/-- A reply payload: a message brought back from an invitation. -/
structure ReplyPayload where
  invitationId : String
  inviterName : String
  sender : String := "A guest"
  message : String
  createdAt : String := ""
  deriving Inhabited

/-- Render a profile as the site's stored-profile JSON. -/
def profileJson (p : Profile) : Json :=
  .obj [
    ("name", .str p.name),
    ("slug", .str p.slug),
    ("note", .str p.note),
    ("icon", .str p.icon),
    ("photos", .arr (p.photos.map .str))
  ]

/-- Render an invite payload as the site's JSON object. -/
def invitePayloadJson (p : InvitePayload) : Json :=
  .obj [
    ("kind", .str profileShareKind),
    ("invitationId", .str p.invitationId),
    ("profile", profileJson p.profile),
    ("prompt", .str p.prompt),
    ("createdAt", .str p.createdAt)
  ]

/-- Render a reply payload as the site's JSON object. -/
def replyPayloadJson (r : ReplyPayload) : Json :=
  .obj [
    ("kind", .str replyKind),
    ("invitationId", .str r.invitationId),
    ("inviterName", .str r.inviterName),
    ("from", .str r.sender),
    ("message", .str r.message),
    ("createdAt", .str r.createdAt)
  ]

/-! ## URLs -/

/-- Encode a payload as the site does: JSON → UTF-8 → unpadded base64url. -/
def encodePayload (j : Json) : String := base64url (Json.render j)

/-- Build an invite link for a page URL. -/
def inviteUrl (pageUrl : String) (p : InvitePayload) : String :=
  pageUrl ++ "#invite=" ++ encodePayload (invitePayloadJson p)

/-- Build a reply link for a page URL. -/
def replyUrl (pageUrl : String) (r : ReplyPayload) : String :=
  pageUrl ++ "#response=" ++ encodePayload (replyPayloadJson r)

/-- Extract the base64url payload after `#key=` in a share URL, if present. -/
def hashParam (key : String) (url : String) : Option String :=
  match url.splitOn "#" with
  | [_] => none
  | _ :: fragments =>
    let wanted := key ++ "="
    let hits := fragments.filter (fun f => startsWithList f.toList wanted.toList)
    match hits with
    | [] => none
    | f :: _ => some (String.ofList (f.toList.drop wanted.toList.length))
  | _ => none

/-- Decode an invite payload from a share URL. -/
def decodeInviteUrl (url : String) : Option String :=
  match hashParam "invite" url with
  | none => none
  | some encoded => base64urlDecode encoded

/-- Decode a reply payload from a share URL. -/
def decodeReplyUrl (url : String) : Option String :=
  match hashParam "response" url with
  | none => none
  | some encoded => base64urlDecode encoded

/-! ## Workspace JSON export -/

/-- Render a person as JSON. -/
def personJson (p : Person) : Json :=
  .obj [
    ("id", .str p.id),
    ("name", .str p.name),
    ("note", .str p.note)
  ]

/-- Render a task as JSON. -/
def taskJson (t : Task) : Json :=
  .obj [
    ("id", .str t.id),
    ("title", .str t.title),
    ("description", .str t.description),
    ("assigneeId", .str t.assigneeId),
    ("status", .str (match t.status with
      | .notStarted => "not-started" | .inProgress => "in-progress" | .blocked => "blocked"
      | .done => "done")),
    ("notes", .str t.notes),
    ("contributions", .arr (t.contributions.map (fun c =>
      .obj [("id", .str c.id), ("person", .str c.person), ("note", .str c.note)]))),
    ("collaborators", .arr (t.collaborators.map personJson)),
    ("updatedAt", .str t.updatedAt)
  ]

/-- Render a schedule entry as JSON. -/
def scheduleJson (s : Schedule) : Json :=
  .obj [
    ("id", .str s.id),
    ("title", .str s.title),
    ("taskId", .str s.taskId),
    ("date", .str s.date),
    ("time", .str s.time),
    ("duration", .str (toString s.duration)),
    ("notes", .str s.notes),
    ("participants", .arr (s.participants.map .str)),
    ("createdAt", .str s.createdAt)
  ]

/-- Render the whole workspace as the `lean-worker-seats-tasks-v3` backup JSON. -/
def workspaceJson (w : Workspace) : Json :=
  .obj [
    ("formatVersion", .str (toString w.formatVersion)),
    ("profile", match w.profile with
      | some p => profileJson p
      | none => .null),
    ("people", .arr (w.people.map personJson)),
    ("tasks", .arr (w.tasks.map taskJson)),
    ("schedules", .arr (w.schedules.map scheduleJson))
  ]

end LodgeHouse
