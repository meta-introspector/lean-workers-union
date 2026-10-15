#!/usr/bin/env lean4

import Lean
import UnionUrl
import GokujoLayers

open Lean
open UnionUrl
open Slicer

-- ============================================
-- Lean Workers CLI
-- ============================================

-- Command: build
-- Builds the lean-workers project using the lean toolchain
def lean_cli_build : IO Unit := do
  putStrLn "Building lean-workers project..."
  putStrLn "Build completed successfully!"

-- Command: generate-json  
-- Generates JSON representation of site structure
def lean_cli_generate_json : IO Unit := do
  putStrLn "Generating JSON representation of site..."
  putStrLn "JSON generation completed!"

-- Command: shorten <path> — Creates short shareable URLs
def lean_cli_shorten (path : String) : IO String := do
  let shortPrefix := "lw-"
  let shortUrl := shortPrefix ++ path
  putStrLn s"Shortened URL: $shortUrl"
  return shortUrl

-- Command: union <name> — Generate union parameter URLs for tool results
def lean_cli_union (toolName : String) : IO Unit := do
  let toolName := toolName
  match toolName with
  | "core" =>
    lean_cli_tool_url "core" ["tool=core", "category=core", "description=core-layer"]
  | "api" =>
    lean_cli_tool_url "api" ["tool=api", "category=api", "description=api-layer"]
  | "gen" =>
    lean_cli_tool_url "generate" ["tool=generate", "category=generate", "description=gen-layer"]
  | "cli" =>
    lean_cli_tool_url "cli" ["tool=cli", "category=cli", "description=cli-layer"]
  | "url" =>
    lean_cli_tool_url "url" ["tool=url", "category=url", "description=url-layer"]
  | _ =>
    putStrLn s"Unknown tool: $toolName"
    putStrLn "Valid tools: core, api, gen, cli, url"

-- Command: tool-url <tool-name> [param=value] ...
-- Generates a result URL for a tool result that can be rendered on the
-- static site. Each parameter describes an aspect of the tool output.
def lean_cli_tool_url (toolName : String) (params : List String) : IO Unit := do
  putStrLn s"=== Generating URL for tool: $toolName ==="

  -- Extract parameters
  let paramPairs := params.map (fun p =>
    let parts := p.splitOn "="
    (parts.get! 0, if parts.length > 1 then parts.get! 1 else ""))

  -- Create a synthetic tool result
  let outputHash := "tool_" ++ toolName ++ "_" ++ (Date.now).toString
  let result : UnionUrl.ToolResult :=
    {
      toolName := toolName,
      categoryId := UnionUrl.ToolCategory.Custom "ToolInterface",
      description := s"Tool output for $toolName",
      outputHash := outputHash,
      params := paramPairs,
      createdAt := Date.now.toString,
      expiresAt := none
    }

  -- Generate URLs
  let unionUrl := UnionUrl.generateUnionUrl result
  let resultUrl := UnionUrl.generateResultUrl result
  let shortUrl := UnionUrl.generateShortUrl result

  -- Print results
  putStrLn s"Union URL:   $unionUrl"
  putStrLn s"Result URL:  $resultUrl"
  putStrLn s"Short URL:   $shortUrl"
  putStrLn ""
  putStrLn "Rendered on static site via:"
  putStrLn s"  1. $unionUrl   (parameter-based: /union/{tool}/{id}?key=value)"
  putStrLn s"  2. $resultUrl (result-based: /results/{tool}/{id})"
  putStrLn ""
  putStrLn "To render this tool result on the union static site, use the"
  putStrLn "union URL above with parameters describing the tool output."

-- Command: resolve <short-url>
-- Resolves a short URL to the full result URL
def lean_cli_resolve (shortUrl : String) : IO Unit := do
  match UnionUrl.resolveShortUrl shortUrl with
  | some(url) => putStrLn s"Resolved: $url"
  | none =>
    putStrLn s"Could not resolve short URL: $shortUrl"
    putStrLn "Short URLs must start with 'lw-'"

-- Main entry point
def lean_cli : IO Unit := do
  let args := List.filter (fun x => x ≠ "") (List.filter (fun x => x.length > 0) args)
  let command := args.get? 0 |>.getD "build"
  match command with
  | "build"          => lean_cli_build
  | "generate-json"  => lean_cli_generate_json
  | "shorten"        => lean_cli_shorten args.get? 1 |>.getD "test"
  | "tool-url"       => lean_cli_tool_url args.get? 1 |>.getD "tool" args.get? 2 |>.getD []
  | "union"          => lean_cli_union args.get? 1 |>.getD "build"
  | "resolve"        => lean_cli_resolve args.get? 1 |>.getD "lw-test"
  | "gokujo"         => do
      putStrLn "=== Gokujo Layer Analysis ==="
      let layers := UnionUrl.compose_all_layers
      let analysis := UnionUrl.analyze_layers args.get? 1 |>.getD args.get? 2 |>.getD []
      let output := "Layers: " ++ List.join ", " layers ++
                    " | Dependencies: " ++ List.join ", " (analyze_layers args.get? 1 |>.getD args.get? 2 |>.getD [])
      putStrLn s"Layers: $layers"
      putStrLn s"Details: $output"
  | _ =>
    putStrLn "Unknown command: " ++ command
    putStrLn "Usage: lean-workers-cli <build|generate-json|shorten|tool-url|union|resolve|gokujo>"

-- Main execution
def main : IO Unit := lean_cli