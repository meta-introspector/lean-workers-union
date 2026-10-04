namespace ChoirUnion.Authority

/-- ClaimCeiling represents an upper bound or specification digest for a claim.
    It allows a consumer to assert not just what is claimed, but what guarantees
    it is allowed to claim (e.g., type, behavior, specification boundaries).
    
    This is part of the bounded-claim concept: a receipt can assert a claim,
    but only within the ceiling of what the trusted local policy permits.
--/
structure ClaimCeiling where
  /-- Human-readable description of the claim ceiling. --/
  description : String
  /-- Structural digest or hash of the specification this claim must satisfy. --/
  digest : String
  deriving Repr, DecidableEq

end ChoirUnion.Authority
