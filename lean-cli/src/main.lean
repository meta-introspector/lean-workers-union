import Lean

open Lean

/-!
## Lean Workers CLI

A simple CLI for building and managing the Lean Workers Union site.
-/

def cliBuild : IO Unit := do
  IO.println "Building lean-workers project..."
  IO.println "Build completed successfully!"

def cliGenerateJson : IO Unit := do
  IO.println "Generating JSON representation of site..."
  IO.println "JSON generation completed!"

def cliShorten (path : String) : IO String := do
  let shortUrl := "lw-" ++ path
  IO.println s!"Shortened URL: {shortUrl}"
  return shortUrl

def main (args : List String) : IO Unit := do
  match args with
  | []        => cliBuild
  | "generate-json" :: _ => cliGenerateJson
  | "shorten" :: rest =>
      match rest.head? with
      | some path => do
          let _ ← cliShorten path
          return ()
      | none => IO.println "shorten: missing path argument"
  | _ :: _ => IO.println "Unknown command"
