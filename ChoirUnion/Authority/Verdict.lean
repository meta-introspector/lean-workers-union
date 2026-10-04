namespace ChoirUnion.Authority

/-- ReceiptVerdict is the epistemic status of a receipt after evaluation.
    It is separate from ReceiptStatus, which describes the lifecycle/type.
    
    ReceiptStatus (open, sketch, kernelChecked, foreign) describes what kind of receipt it is.
    ReceiptVerdict (attested, falsified, indeterminate) describes our confidence in it.
    
    This separation prevents the conceptual collapse where kernelChecked becomes
    synonymous with authoritative/trusted.
--/
inductive ReceiptVerdict where
  /-- The receipt passed the local gate and is accepted as evidence for this decision. --/
  | attested
  /-- The receipt failed verification or contradicts trusted local policy. --/
  | falsified
  /-- The receipt has not yet been evaluated, or the evaluation is inconclusive. --/
  | indeterminate
  deriving Repr, DecidableEq

end ChoirUnion.Authority
