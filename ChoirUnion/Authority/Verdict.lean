namespace ChoirUnion.Authority

/-- ReceiptVerdict is a label for the epistemic status of a receipt after evaluation.
    It is separate from ReceiptStatus, which describes the lifecycle/type.
    
    ReceiptStatus (open, sketch, kernelChecked, foreign) describes what kind of receipt it is.
    ReceiptVerdict (attested, falsified, indeterminate) is intended to record the local
    evaluator's confidence in it.
    
    This separation is meant to prevent the conceptual collapse where kernelChecked
    becomes synonymous with authoritative/trusted.

    The verdict is an ordinary field of `Receipt`, written by whoever constructs the
    receipt. No function in this package computes or updates it, and `evaluateGate`
    does not read it. A verdict read from a received receipt is a producer claim; it
    carries meaning only when the local evaluator sets it after its own checks.
--/
inductive ReceiptVerdict where
  /-- Intended meaning: the local evaluator accepted the receipt as evidence for this
      decision after its own checks. Nothing in this package sets this value; on a
      received receipt it is only the producer's claim. --/
  | attested
  /-- Intended meaning: the receipt failed verification or contradicts trusted local
      policy. Nothing in this package sets this value, and `evaluateGate` does not
      reject receipts carrying it. --/
  | falsified
  /-- The receipt has not yet been evaluated, or the evaluation is inconclusive.
      This is the default value of `Receipt.verdict`. --/
  | indeterminate
  deriving Repr, DecidableEq

end ChoirUnion.Authority
