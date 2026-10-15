#!/usr/bin/env lean4

import Lean

--
-- URL Generator for the Lean Workers Union Static Site
--
-- This module provides functions to generate shareable URLs
-- for the static site hosted at lean-workers-union.oneapp.dev
--
-- The site is built from the lean-worker project and served at:
--   https://lean-workers-union.oneapp.dev/

--
-- Public API
--
-- | Generates a JSON manifest of all site URLs
-- | Returns a list of strings, each being a full URL
-- | @param description Description of the generated data
-- | @return List of URLs
--
def generate_site_urls : List String := do
  let baseUrl = "https://lean-workers-union.oneapp.dev/"
  let pages = [
    "index.html",
    "seats.html",
    "seats/share.html",
    "union-roadmap.html",
    "protocols.html",
    "proof-model.html",
    "plugins.html",
    "skill-registry.html",
    "tours.html",
    "training-log.html",
    "archive.html",
    "n00b-guide.html",
    "nixwars-arcade.html",
  ]
  -- Map each page to its full URL
  let urls = map (
    page -> baseUrl ++ page
  ) pages
  return urls

-- | Generates a short shareable URL for a given path
-- | @param path The URL path segment (e.g., "seats/share")
-- | @return The shortened URL
--
def generate_short_url : String -> String := do
  let shortPrefix = "lw-"  -- Lean Workers Union short prefix
  let path = argument
  let shortUrl = shortPrefix ++ path
  return shortUrl

-- | Validates that a URL points to the correct domain
-- | @param url The URL to validate
-- | @return True if valid, False otherwise
--
def isValidSiteUrl : String -> Bool := do
  let base = "https://lean-workers-union.oneapp.dev"
  let url = argument
  return (url.startsWith base)

-- | Gets the list of all pages on the site
-- | Useful for discovering new routes
--
def get_all_pages : List String := do
  let pages = [
    "index.html",
    "seats.html",
    "seats/share.html",
    "union-roadmap.html",
    "protocols.html",
    "proof-model.html",
    "plugins.html",
    "skill-registry.html",
    "tours.html",
    "training-log.html",
    "archive.html",
    "n00b-guide.html",
    "nixwars-arcade.html",
  ]
  return pages
