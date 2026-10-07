import LodgeHouse.Api

/-!
# Base64url codec

The Lodge House share links encode their JSON payload as UTF-8 bytes, then
base64 with the URL-safe alphabet (`+` → `-`, `/` → `_`, no padding), exactly
like the site's `btoa` + `replaceAll` pipeline.
-/

namespace LodgeHouse

/-- The base64 alphabet, URL-safe variant. -/
def b64Alphabet : List Char :=
  "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_".toList

def b64Char (n : Nat) : Char :=
  match b64Alphabet[n]? with
  | some c => c
  | none => '?'

/-- Render one 6-bit group as a character. -/
def renderGroup (n : Nat) : String := String.singleton (b64Char n)

/-- Encode a list of 6-bit groups as a string. -/
def encodeGroups : List Nat → String
  | [] => ""
  | n :: rest => renderGroup n ++ encodeGroups rest

/-- Split a byte list into 3-byte chunks, each yielding four (or fewer) 6-bit groups. -/
def chunk3 : List UInt8 → List Nat
  | [] => []
  | [a] => [a.toNat >>> 2, (a.toNat &&& 3) <<< 4]
  | [a, b] => [a.toNat >>> 2, ((a.toNat &&& 3) <<< 4) ||| (b.toNat >>> 4), (b.toNat &&& 15) <<< 2]
  | a :: b :: c :: rest =>
    [a.toNat >>> 2, ((a.toNat &&& 3) <<< 4) ||| (b.toNat >>> 4),
     ((b.toNat &&& 15) <<< 2) ||| (c.toNat >>> 6), c.toNat &&& 63] ++ chunk3 rest

/-- Encode a string as unpadded base64url. -/
def base64url (s : String) : String :=
  encodeGroups (chunk3 (String.toUTF8 s).data.toList)

/-- Decode a base64url character to its 6-bit value. -/
def b64Value (c : Char) : Option Nat :=
  if c ≥ 'A' ∧ c ≤ 'Z' then some (c.toNat - 'A'.toNat)
  else if c ≥ 'a' ∧ c ≤ 'z' then some (26 + c.toNat - 'a'.toNat)
  else if c ≥ '0' ∧ c ≤ '9' then some (52 + c.toNat - '0'.toNat)
  else if c = '-' then some 62
  else if c = '_' then some 63
  else none

/-- Assemble a group of four (or fewer) 6-bit values into up to three bytes. -/
def groupsToBytes : List Nat → List UInt8
  | [a, b] => [UInt8.ofNat ((a <<< 2) ||| (b >>> 4))]
  | [a, b, c] => [UInt8.ofNat ((a <<< 2) ||| (b >>> 4)),
                  UInt8.ofNat (((b &&& 15) <<< 4) ||| (c >>> 2))]
  | [a, b, c, d] => [UInt8.ofNat ((a <<< 2) ||| (b >>> 4)),
                     UInt8.ofNat (((b &&& 15) <<< 4) ||| (c >>> 2)),
                     UInt8.ofNat (((c &&& 3) <<< 6) ||| d)]
  | _ => []

/-- Decode a list of 6-bit values back to bytes, four groups at a time. -/
def groupsBytes : List Nat → List UInt8
  | [] => []
  | [a] => groupsToBytes [a]
  | [a, b] => groupsToBytes [a, b]
  | [a, b, c] => groupsToBytes [a, b, c]
  | [a, b, c, d] => groupsToBytes [a, b, c, d]
  | a :: b :: c :: d :: rest => groupsToBytes [a, b, c, d] ++ groupsBytes rest

/-- Decode unpadded base64url back to bytes. -/
def base64urlBytes (s : String) : Option (List UInt8) :=
  let values := s.toList.map b64Value
  if values.any Option.isNone then none
  else some (groupsBytes (values.flatMap (fun v => match v with
    | some n => [n]
    | none => [])))

/-- Decode base64url back to a string (fails on invalid UTF-8). -/
def base64urlDecode (s : String) : Option String :=
  match base64urlBytes s with
  | none => none
  | some bytes => String.fromUTF8? (ByteArray.mk bytes.toArray)

end LodgeHouse
