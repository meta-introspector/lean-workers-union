# Lodge House API v1 — Specification

Reverse-engineered from the deployed site (lean-workers-union.oneapp.dev, wget mirror
2026-10-07) and aligned with the `ChoirUnion` registry in this repo. The site is entirely
browser-local today: localStorage + IndexedDB, tar.gz export, base64url share links.
This API is the server-side formalization of those exact models.

## Design rule

The site's own disclaimers are load-bearing: "browser-local notes, not live build or
permission checks", "sharing links are readable, not encrypted, not access-controlled".
The API keeps the same honesty: every response carries provenance, and nothing in the
API asserts what was not checked. The ChoirUnion `Receipt`/`Witness` vocabulary is the
status grammar.

## Resources

### 1. Registry (server-side mirror of ChoirUnion.UnionRegistry)

```
GET  /api/v1/registry                 → UnionRegistry (members as UnionMembership)
GET  /api/v1/registry/:member_id      → UnionMembership | 404
GET  /api/v1/registry?capability=lean4 → lookupByCapability
POST /api/v1/registry                 → registerMember (idempotent on member_id)
```

`UnionMembership`: member_id, repo, module, capability_set, status ("lodge-table").

### 2. Workspace (mirror of localStorage `lean-worker-seats-tasks-v3`)

```
GET    /api/v1/workspaces/:slug            → Workspace
PUT    /api/v1/workspaces/:slug            → replace (formatVersion must match)
GET    /api/v1/workspaces/:slug/people     → List Person
GET    /api/v1/workspaces/:slug/tasks      → List Task
GET    /api/v1/workspaces/:slug/invitations→ List Invitation
GET    /api/v1/workspaces/:slug/schedules  → List Schedule
```

`Workspace`: formatVersion=1, profile: Option Profile, people, invitations, tasks,
schedules, document: Option String.

`Profile`: name (≤80), slug (≤40, `^[a-z0-9]+(-[a-z0-9]+)*$`), note (≤240),
icon (data:image/, ≤100000), photos (List of data:image/, ≤100000 each).

`Person`: id ("person-…"), name (≤80, unique case-insensitive), note (≤180).

`Invitation`: id, person (name), note, status ∈ {Draft, …}, createdAt.

`Task`: id ("task-…"), title (≤160), description (≤500), assigneeId,
status ∈ {Not started, …, Done}, notes, contributions: List Contribution,
collaborators: List Person, updatedAt.

`Schedule`: id ("schedule-…"), title (≤120), taskId, date (YYYY-MM-DD), time,
duration (minutes, default 60), notes (≤500), participants: List String, createdAt.

### 3. Builds (mirror of localStorage `lodge-profile-builds-v1`)

```
GET    /api/v1/workspaces/:slug/builds  → List Build
POST   /api/v1/workspaces/:slug/builds  → Build
PATCH  /api/v1/builds/:id               → {status?, access?} (bumps updatedAt)
DELETE /api/v1/builds/:id
```

`Build`: id (UUID), title (≤100), description (≤800), artwork (data:image/, ≤2MB),
status ∈ {Planning, In progress, Blocked, Ready, Archived},
access ∈ {Private, Invite link, Public link},
link (http(s) only, else ""), updatedAt (ISO-8601).

### 4. Sharing views (mirror of `lodge-profile-sharing-views-v1`)

```
GET    /api/v1/workspaces/:slug/views   → List View
POST   /api/v1/workspaces/:slug/views   → View
GET    /api/v1/views/:id               → View
DELETE /api/v1/views/:id
```

`View`: id, name (≤80), query (≤160), sections ⊆ {people, invitations, tasks, schedules}.

### 5. Archive (mirror of IndexedDB `lodge-private-archive-desk-v1`, v2)

```
GET  /api/v1/archives                  → List ArchiveMeta
GET  /api/v1/archives/:id             → Archive (files inline)
POST /api/v1/archives                 → Archive (tar.gz upload, ≤ site limits)
GET  /api/v1/archives/:id/files/:name → raw bytes
```

Stores: `archives`, `profiles`, `profileDocuments`. `ProfileDocument`:
id, sourceArchiveId, name, promotedAt, files: List {path, size, bytes}.

### 6. Backup (mirror of the tar.gz export)

```
GET /api/v1/workspaces/:slug/backup   → application/tar+gzip
     (lodge-house-backup-YYYY-MM-DD.tar.gz, same tar layout the site writes)
```

## Share links (compat)

The site encodes `{formatVersion: 1, kind: "workspace" | "task" | "lodge-profile-invite-v1", …}`
as base64url in the URL fragment (`#data=…` / `#invite=…`). The API accepts the same
payloads as request bodies:

```
POST /api/v1/import/link   {url: "https://…#data=…"}  → Workspace (merged)
```

Merge semantics (from the site's import code): people merge by name (case-insensitive),
tasks merge by id — contributions append dedup by id, collaborators dedup by name.

## Status grammar (ChoirUnion alignment)

Every mutating response carries a `Receipt`:
- claim (Lean.Name of the declaration / resource id)
- witness (ReplayWitness: declarationFound, isTheorem, sorryCount, usedAxioms)
- status: ReceiptStatus (open | sketch | kernelChecked | foreign)
- verdict: ReceiptVerdict (attested | falsified | indeterminate)

The API never upgrades a browser-local claim past `sketch` unless a witness was
synthesized fresh (gokujo `axioms`/`check` gate) — per the README's critical
distinction: a deserialized witness passing `clean()` is still a claim, not evidence.
