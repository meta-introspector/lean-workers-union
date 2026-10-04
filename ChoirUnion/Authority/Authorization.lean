import Member
import ChoirUnion.Authority.Subject
import ChoirUnion.Authority.Claim

namespace ChoirUnion.Authority

structure ReceiptAuthorizationPolicy where
  issuerMemberId : String
  requiredCapabilities : List String
  permittedRoles : List String

instance : Repr ReceiptAuthorizationPolicy := ⟨fun p =>
  "{ issuerMemberId := " ++ repr p.issuerMemberId ++
  ", requiredCapabilities := " ++ repr p.requiredCapabilities ++
  ", permittedRoles := " ++ repr p.permittedRoles ++ " }"⟩

instance : DecidableEq ReceiptAuthorizationPolicy := by
  intro a b
  cases a with
  | mk issuerA requiredA rolesA =>
      cases b with
      | mk issuerB requiredB rolesB =>
          simp [issuerA, requiredA, rolesA, issuerB, requiredB, rolesB]

def mayRequestReceipt
    (memberId : String)
    (memberCapabilities : List String)
    (memberRole : String)
    (policy : ReceiptAuthorizationPolicy) : Bool :=
  memberId == policy.issuerMemberId &&
  policy.requiredCapabilities.all (fun cap => memberCapabilities.contains cap) &&
  policy.permittedRoles.contains memberRole

end ChoirUnion.Authority
