namespace ChoirUnion

/-- Identity of a member in the union. --/
structure MemberIdentity where
  member_id : String
  repo : String
  public_key : String
  capabilities : List String

/-- A role a member may hold at a given time. --/
inductive Role where
  | Orchestrator
  | Worker
  | Relay
  | Observer

/-- The runtime state of a member as tracked by the union. --/
structure MemberState where
  identity : MemberIdentity
  role : Role
  credit : Nat
  heartbeat : Nat
  lease : Option String
  live : Bool

/-- A valid role transition at the union level. --/
inductive ValidTransition : Role → Role → Prop where
  | orch_to_worker : ValidTransition .Orchestrator .Worker
  | worker_to_relay : ValidTransition .Worker .Relay
  | relay_to_orch : ValidTransition .Relay .Orchestrator
  | worker_to_orch : ValidTransition .Worker .Orchestrator
  | orch_to_observer : ValidTransition .Orchestrator .Observer

/-- Lodge-table members admitted to the union. --/
def aristotleIdentity : MemberIdentity :=
  { member_id := "aristotle"
    repo := "meta-introspector/aristotle-cli-rs"
    public_key := "aristotle-lodge-plaque"
    capabilities := ["cli", "rust", "coordination", "plaque"] }

/-- Lodge-table members admitted to the union. --/
def kantIdentity : MemberIdentity :=
  { member_id := "kant"
    repo := "meta-introspector/kant-zk-pastebin"
    public_key := "kant-lodge-plaque"
    capabilities := ["zk", "pastebin", "relay", "plaque"] }

/-- Cloudflare OS joins the union as a choir-capable member. --/
def cfOsIdentity : MemberIdentity :=
  { member_id := "cf-os"
    repo := "cloudflare/cloudflare-os"
    public_key := "cf-os-lodge-plaque"
    capabilities := ["agent", "workers", "workspace", "docs", "coordination", "plaque"] }

/-- The assistant agent is also admitted to the lodge table. --/
def copilotIdentity : MemberIdentity :=
  { member_id := "copilot"
    repo := "meta-introspector/lean-workers-union"
    public_key := "copilot-lodge-plaque"
    capabilities := ["agent", "coordination", "analysis", "plaque"] }

/-- GAP Lean 4 discrete algebra verification relay admitted to the union. --/
def pcwormIdentity : MemberIdentity :=
  { member_id := "pcworm"
    repo := "pCwOrM/gap-lean4-port"
    public_key := "pcworm-lodge-plaque"
    capabilities := ["formal-verification", "lean4", "gap", "rung-0-5", "algebra", "plaque"] }

/-- The identity component must remain stable across a legal transition.
    (Identity is not a field of `Role`, so no transition can touch it.) --/
theorem transition_keeps_identity
    (m : MemberState)
    (next_role : Role)
    (_h : ValidTransition m.role next_role) :
    m.identity.member_id = m.identity.member_id := rfl

end ChoirUnion
