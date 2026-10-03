namespace ChoirUnion

/-- Publicly exported registry record for a union member. --/
structure UnionMembership where
  member_id : String
  repo : String
  module : String
  capability_set : List String
  status : String

/-- A registry is a collection of known members. --/
structure UnionRegistry where
  members : List UnionMembership

/-- A minimalist registration operation for the union. --/
def registerMember
    (reg : UnionRegistry)
    (entry : UnionMembership) : UnionRegistry :=
  { members := entry :: reg.members }

/-- Lookup by member id is a pure query over the registry. --/
def lookupByMemberId
    (reg : UnionRegistry)
    (member_id : String) : Option UnionMembership :=
  reg.members.find? (fun m => m.member_id == member_id)

/-- Lookup by repository is a pure query over the registry. --/
def lookupByRepo
    (reg : UnionRegistry)
    (repo : String) : List UnionMembership :=
  reg.members.filter (fun m => m.repo == repo)

/-- Lookup by capability is a pure query over the registry. --/
def lookupByCapability
    (reg : UnionRegistry)
    (capability : String) : List UnionMembership :=
  reg.members.filter (fun m => m.capability_set.contains capability)

end ChoirUnion
