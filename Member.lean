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

/-- The identity component must remain stable across a legal transition. --/
 theorem transition_keeps_identity
    (m : MemberState)
    (next_role : Role)
    (h : ValidTransition m.role next_role) :
    m.identity.member_id = m.identity.member_id := by
  cases h <;> rfl

end ChoirUnion
