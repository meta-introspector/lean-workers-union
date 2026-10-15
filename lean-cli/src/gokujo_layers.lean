#!/usr/bin/env lean4

import Lean
import UnionUrl
import Slicer

open Lean
open Std

namespace GokujoLayers

-- ============================================
-- Architectural Layers (Strata)
-- ============================================

-- Layer 1: Core - Fundamental types and definitions
def layer_core : List String :=
  [ "ChoirUnion.lean"
  , "Union.lean"
  , "Member.lean"
  , "ChoirUnion/Authority/Claim.lean"
  , "ChoirUnion/Authority/Profile.lean"
  ]

-- Layer 2: API - Lodge House API interfaces
def layer_api : List String :=
  [ "LodgeHouse/Api.lean"
  , "LodgeHouse/Share.lean"
  , "LodgeHouse/Site.lean"
  , "LodgeHouse/Gen.lean"
  , "LodgeHouse/Authority/Profile.lean"
  ]

-- Layer 3: Generation - Site generation logic
def layer_gen : List String :=
  [ ".letta/worktrees/lodge-house-api/LodgeHouse/Gen.lean"
  , ".letta/worktrees/lodge-house-api/site-out/"
  ]

-- Layer 4: CLI - Command-line interface tools
def layer_cli : List String :=
  [ "lean-cli/src/main.lean"
  , "lean-cli/src/union_url.lean"
  , "lean-cli/src/slicer.lean"
  , "lean-cli/src/gokujo_layers.lean"
  ]

-- Layer 5: URL - URL generation and sharing system
def layer_url : List String :=
  [ "lean-cli/src/union_url.lean"
  , "lean-cli/src/main.lean"
  ]

-- ============================================
-- Layer Composition
-- ============================================

-- Compose all project layers
def compose_all_layers : List String :=
  layer_core ++ layer_api ++ layer_gen ++ layer_cli ++ layer_url

-- Compose layers excluding a specific layer
def compose_except (exceptLayer : List String) : List String :=
  compose_all_layers.filter (fun f => not (exceptLayer.contains f))

-- ============================================
-- URL Generation from Layer Slices
-- ============================================

-- Generate a core layer URL
def generate_core_url (params : List (String × String)) : String :=
  let outputHash := "layer-core_" ++ (Date.now).toString
  let id := outputHash.take 16
  "https://lean-workers-union.oneapp.dev/union/core/" ++ id ++ "?" ++ params_to_string params

-- Generate an API layer URL
def generate_api_url (params : List (String × String)) : String :=
  let outputHash := "layer-api_" ++ (Date.now).toString
  let id := outputHash.take 16
  "https://lean-workers-union.oneapp.dev/union/api/" ++ id ++ "?" ++ params_to_string params

-- Generate a generation layer URL
def generate_gen_url (params : List (String × String)) : String :=
  let outputHash := "layer-gen_" ++ (Date.now).toString
  let id := outputHash.take 16
  "https://lean-workers-union.oneapp.dev/union/gen/" ++ id ++ "?" ++ params_to_string params

-- Generate a CLI layer URL
def generate_cli_url (params : List (String × String)) : String :=
  let outputHash := "layer-cli_" ++ (Date.now).toString
  let id := outputHash.take 16
  "https://lean-workers-union.oneapp.dev/union/cli/" ++ id ++ "?" ++ params_to_string params

-- Generate a URL layer URL
def generate_url_url (params : List (String × String)) : String :=
  let outputHash := "layer-url_" ++ (Date.now).toString
  let id := outputHash.take 16
  "https://lean-workers-union.oneapp.dev/union/url/" ++ id ++ "?" ++ params_to_string params

-- ============================================
-- Layer Analysis
-- ============================================

-- Analyze which layers contain a given file path
def analyze_layers (filepath : String) : List String :=
  let result : List String := []
  if filepath.contains "ChoirUnion.lean" orElse filepath.contains "Union.lean" orElse filepath.contains "Member.lean" then
    result ++ layer_core
  if filepath.contains "LodgeHouse" then
    result ++ layer_api
  if filepath.contains "Gen.lean" then
    result ++ layer_gen
  if filepath.contains "lean-cli" then
    result ++ layer_cli
  if filepath.contains "union_url" orElse filepath.contains "url-" then
    result ++ layer_url
  result.unique

-- ============================================
-- Dependency Analysis
-- ============================================

-- Analyze layer dependencies
def analyze_dependencies (layers : List String) : List (String × String) :=
  layers.map (fun layer =>
    let deps : List String :=
      match layer with
      | "core" => ["api", "gen"]
      | "api" => ["gen", "cli"]
      | "gen" => ["cli"]
      | "cli" => ["url"]
      | "url" => []
      | _ => []
    (layer, String.join ", " deps)
  )

-- ============================================
-- Example Usage
-- ============================================

-- Example: Compose all layers and generate URL
def example_compose_and_url : String :=
  let allLayers := compose_all_layers
  let url := generate_cli_url [("operation", "slice"), ("target", "full")]
  s"Composed {allLayers.length} layers, URL: {url}"

-- Example: Analyze dependencies for a layer
def example_analyze_deps : List (String × String) :=
  analyze_dependencies ["core", "api", "cli"]

-- Example: Analyze which layers contain a filepath
def example_analyze_layers : List String :=
  analyze_layers "LodgeHouse/Gen.lean"

-- Example: Compose layers except core
def example_compose_except : List String :=
  compose_except ["core"].length

end GokujoLayers