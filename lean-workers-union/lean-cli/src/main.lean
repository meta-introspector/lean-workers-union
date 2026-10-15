#!/usr/bin/env lean4

import Lean

open Lean

--
-- CLI Entry Point
--
-- This is the main entry point for the lean-workers-cli.
-- It provides commands to:
-- 1. Build the static site using gokujo
-- 2. Generate JSON URLs for the site
-- 3. Create shareable short URLs
--
-- Usage:
--   lean-workers-cli build           # Build the site
--   lean-workers-cli generate-json   # Generate JSON URL manifest
--   lean-workers-cli shorten <path> # Create a short shareable URL
--
--
-- The CLI leverages the gokujo/lean-worker ecosystem for building
-- the static site and managing the lean-worker infrastructure.

-- Command: build
-- Builds the lean-worker project using gokujo
--
def lean_cli.build : IO Unit := do
  putStrLn "Building lean-worker site with gokujo..."
  -- In practice, this would call gokujo to build the site
  -- For example: gokujo bootstrap -o lean-worker-gokujo
  -- Then copy the built site to the static hosting location
  putStrLn "Build complete!"

-- Command: generate-json
-- Generates a JSON file with all site URLs
--
def lean_cli.generate_json : IO Unit := do
  putStrLn "Generating JSON URL manifest..."
  -- Collect all pages from the site
  -- For the current site: lean-workers-union/
  -- Pages: index.html, seats.html, capacity.html, etc.
  let pages = [
    "https://lean-workers-union.oneapp.dev/index.html",
    "https://lean-workers-union.oneapp.dev/seats.html",
    "https://lean-workers-union.oneapp.dev/seats/share.html",
    "https://lean-workers-union.oneapp.dev/union-roadmap.html",
    "https://lean-workers-union.oneapp.dev/protocols.html",
    "https://lean-workers-union.oneapp.dev/proof-model.html",
    "https://lean-workers-union.oneapp.dev/plugins.html",
    "https://lean-workers-union.oneapp.dev/skill-registry.html",
    "https://lean-workers-union.oneapp.dev/tours.html",
    "https://lean-workers-union.oneapp.dev/training-log.html",
    "https://lean-workers-union.oneapp.dev/unit-tests.html",
    "https://lean-workers-union.oneapp.dev/archive.html",
    "https://lean-workers-union.oneapp.dev/n00b-guide.html",
    "https://lean-workers-union.oneapp.dev/union-roadmap.html",
    "https://lean-workers-union.oneapp.dev/nixwars-arcade.html",
    "https://lean-workers-union.oneapp.dev/seats/index.html",
  ]
  -- Write to JSON file
  let json = json.dumps(pages, indent = 2)
  writeToFile "site_urls.json" json
  putStrLn "JSON manifest written to site_urls.json"

-- Command: shorten
-- Creates a short shareable URL for a given path
--
def lean_cli.shorten : String -> IO String := do
  let shortPrefix = "lw-"  -- Lean Workers Union short prefix
  let path = argument
  let shortUrl = shortPrefix ++ path
  putStrLn $ s"Shortened URL: $shortUrl"
  return shortUrl

-- Main entry point
--
-- Parse command line arguments and dispatch accordingly
--
def lean_cli : IO Unit := do
  let args = argument
  case args of
    [] -> lean_cli.build
    "generate-json" -> lean_cli.generate_json
    "shorten" -> lean_cli.shorten args
    _ -> putStrLn "Unknown command: $args" <|> lean_cli.build
