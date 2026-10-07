import Member
import ChoirUnion.Authority.Subject
import ChoirUnion.Authority.Claim

namespace ChoirUnion.Authority

structure ReceiptAuthorizationPolicy where
  issuerMemberId : String
  requiredCapabilities : List String
  permittedRoles : List String

deriving instance DecidableEq for ReceiptAuthorizationPolicy

instance : Repr ReceiptAuthorizationPolicy := ⟨fun p _ =>
  "{ issuerMemberId := " ++ reprStr p.issuerMemberId ++
  ", requiredCapabilities := " ++ toString p.requiredCapabilities ++
  ", permittedRoles := " ++ toString p.permittedRoles ++ " }"⟩

def mayRequestReceipt
    (memberId : String)
    (memberCapabilities : List String)
    (memberRole : String)
    (policy : ReceiptAuthorizationPolicy) : Bool :=
  memberId == policy.issuerMemberId &&
  policy.requiredCapabilities.all (fun cap => memberCapabilities.contains cap) &&
  policy.permittedRoles.contains memberRole

end ChoirUnion.Authority
