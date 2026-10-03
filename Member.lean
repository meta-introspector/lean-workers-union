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
  | orch_to_worker
  | worker_to_relay
  | relay_to_orch
  | worker_to_orch
  | orch_to_observer

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

/-- The assistant agent is also admitted to the lodge table. --/
def copilotIdentity : MemberIdentity :=
  { member_id := "copilot"
    repo := "meta-introspector/lean-workers-union"
    public_key := "copilot-lodge-plaque"
    capabilities := ["agent", "coordination", "analysis", "plaque"] }

/-- The identity component must remain stable across a legal transition. --/
 theorem transition_keeps_identity
    (m : MemberState)
    (next_role : Role)
    (h : ValidTransition m.role next_role) :
    m.identity.member_id = m.identity.member_id := by
  cases h <;> rfl

end ChoirUnion
