import Lean
import ChoirUnion.Authority.Subject
import ChoirUnion.Authority.Claim
import ChoirUnion.Authority.Profile
import ChoirUnion.Authority.Witness
import ChoirUnion.Authority.Receipt
import ChoirUnion.Authority.Gate

namespace ChoirUnion.TestAuthority

open ChoirUnion.Authority

def sampleSubject : Subject :=
  { repository := "meta-introspector/lean-workers-union"
    commitHash := "deadbeef"
    toolchain := "leanprover/lean4:v4.22.0" }

def sampleClaim : Claim :=
  { declaration := ``ChoirUnion.TestAuthority.sampleClaim }

def sampleWitness : ReplayWitness :=
  { declarationFound := true
    isTheorem := true
    sorryCount := 0
    usedAxioms := [``propext] }

def sampleReceipt : Receipt :=
  { subject := sampleSubject
    claim := sampleClaim
    producerMemberId := "copilot"
    witness := some sampleWitness
    status := ReceiptStatus.kernelChecked
    evidenceDigest := some "hash" }

def sampleCondition : GateCondition :=
  { expectedSubject := sampleSubject
    expectedClaim := sampleClaim
    allowedAxioms := AxiomProfile.constructive }

example : evaluateGate sampleCondition sampleReceipt = true := by
  decide

example : clean sampleWitness AxiomProfile.constructive = true := by
  decide

end ChoirUnion.TestAuthority
